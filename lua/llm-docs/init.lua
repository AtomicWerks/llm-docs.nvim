local M = {}

M.state = {
  projects = {},
}

local data_path = vim.fn.stdpath("data") .. "/llm_docs_projects.json"

local function load_persisted_projects()
  local f = io.open(data_path, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()
  if content == "" then
    return {}
  end
  local ok, parsed = pcall(vim.json.decode, content)
  return ok and parsed or {}
end

local function save_persisted_projects(projects)
  local f = io.open(data_path, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(projects))
  f:close()
end

function M.setup(opts)
  opts = opts or {}
  local config_projects = opts.projects or {}
  local persisted_projects = load_persisted_projects()

  local seen_urls = {}
  M.state.projects = {}

  local function add_project(p, is_from_config)
    -- Normalize: prioritize base_url if provided
    if p.base_url and not p.url then
      p.url = p.base_url:gsub("/$", "") .. "/llms.txt"
    end
    -- If only url provided, extract base_url
    if p.url and not p.base_url then
      p.base_url = p.url:match("(https?://[^/]+)")
    end

    if not seen_urls[p.url] then
      seen_urls[p.url] = true
      p.is_config = is_from_config
      table.insert(M.state.projects, p)
    end
  end

  for _, p in ipairs(config_projects) do
    add_project(p, true)
  end
  for _, p in ipairs(persisted_projects) do
    add_project(p, false)
  end

  vim.api.nvim_create_user_command("LLMDocs", function(cmd_opts)
    local picker = require("llm-docs.picker")

    if cmd_opts.args ~= "" then
      local input_url = cmd_opts.args
      local name = input_url:match("://([^/]+)") or "New Project"

      local new_project = {
        name = name,
        url = input_url,
      }

      add_project(new_project, false)

      -- Save only non-config projects to JSON
      local to_save = vim.tbl_filter(function(proj)
        return not proj.is_config
      end, M.state.projects)

      save_persisted_projects(to_save)
      picker.fetch_llms_txt(new_project)
    else
      picker.open_project_picker(M.state.projects)
    end
  end, { nargs = "?" })
end

return M
