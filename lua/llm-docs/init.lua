local M = {}

-- The combined state of config projects + persisted projects
M.state = {
  projects = {}
}

-- Define the path where our dynamically added projects will live
local data_path = vim.fn.stdpath("data") .. "/llm_docs_projects.json"

-- Helper to load from disk
local function load_persisted_projects()
  local f = io.open(data_path, "r")
  if not f then return {} end
  
  local content = f:read("*a")
  f:close()
  
  if content == "" then return {} end
  
  local ok, parsed = pcall(vim.json.decode, content)
  if not ok then return {} end
  return parsed
end

-- Helper to save to disk
local function save_persisted_projects(projects)
  local f = io.open(data_path, "w")
  if not f then return end
  
  f:write(vim.json.encode(projects))
  f:close()
end

function M.setup(opts)
  opts = opts or {}
  local config_projects = opts.projects or {}
  local persisted_projects = load_persisted_projects()
  
  local seen_urls = {}
  M.state.projects = {}

  -- Helper to merge projects and prevent duplicates
  local function add_project(p)
    if not seen_urls[p.url] then
      seen_urls[p.url] = true
      table.insert(M.state.projects, p)
    end
  end

  -- Load projects from user's init.lua/lazy config first
  for _, p in ipairs(config_projects) do add_project(p) end
  
  -- Load dynamically added projects from previous sessions
  for _, p in ipairs(persisted_projects) do add_project(p) end

  -- Define the command
  vim.api.nvim_create_user_command("LLMDocs", function(cmd_opts)
    local picker = require("llm-docs.picker")
    
    if cmd_opts.args ~= "" then
      local url = cmd_opts.args
      
      -- Create a new project object from the URL
      local new_project = {
        name = url:match("://([^/]+)"), -- e.g., "docs.vendure.io"
        url = url,
        base_url = url:match("(https?://[^/]+)") -- e.g., "https://docs.vendure.io"
      }
      
      -- If we've never seen this URL before, add it and save it
      if not seen_urls[new_project.url] then
        add_project(new_project)
        table.insert(persisted_projects, new_project)
        save_persisted_projects(persisted_projects)
        vim.notify("Saved " .. new_project.name .. " to LLM Docs library!", vim.log.levels.INFO)
      end
      
      -- Fetch and open immediately
      picker.fetch_llms_txt(new_project)
    else
      -- No args: open the standard project picker
      picker.open_project_picker(M.state.projects)
    end
  end, { nargs = "?" })
end

return M
