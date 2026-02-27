local M = {}
M.state = { projects = {} }
local data_path = vim.fn.stdpath("data") .. "/llm_docs_projects.json"

local function load_persisted()
  local f = io.open(data_path, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, parsed = pcall(vim.json.decode, content)
  return ok and parsed or {}
end

local function save_persisted(projects)
  local f = io.open(data_path, "w")
  if not f then return end
  f:write(vim.json.encode(projects))
  f:close()
end

function M.setup(opts)
  opts = opts or {}
  local config_projects = opts.projects or {}
  local persisted_projects = load_persisted()
  local seen_urls = {}
  M.state.projects = {}

  local function add_project(p, is_config)
    -- Ensure base_url is just the base (e.g. https://docs.vendure.io)
    if p.base_url then p.base_url = p.base_url:gsub("/$", "") end

    -- If no explicit url for llms.txt, derive it from base_url
    if not p.url and p.base_url then
      p.url = p.base_url .. "/llms.txt"
    end

    -- Derive base_url from url if missing
    if p.url and not p.base_url then
      p.base_url = p.url:match("(https?://[^/]+)")
    end

    if p.url and not seen_urls[p.url] then
      seen_urls[p.url] = true
      p.is_config = is_config
      table.insert(M.state.projects, p)
    end
  end

  for _, p in ipairs(config_projects) do add_project(p, true) end
  for _, p in ipairs(persisted_projects) do add_project(p, false) end

   vim.api.nvim_create_user_command("LLMDocs", function(cmd_opts)
    local picker = require("llm-docs.picker")
    if cmd_opts.args ~= "" then
      local url = cmd_opts.args
      local new_project = {
        name = url:match("://([^/]+)") or "New Project",
        url = url,
      }
      add_project(new_project, false)
      save_persisted(vim.tbl_filter(function(v) return not v.is_config end, M.state.projects))

      -- Check if curl is available before attempting to fetch
      local curl = picker.get_curl()
      if not curl then
        vim.notify("llm-docs: curl.nvim is required but not installed. Please install curl.nvim.", vim.log.levels.ERROR)
        return
      end

      picker.fetch_llms_txt(new_project)
    else
      picker.open_project_picker(M.state.projects)
    end
  end, { nargs = "?" })
end

return M

