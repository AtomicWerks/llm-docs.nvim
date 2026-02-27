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
  f:write(vim.json.encode(projects) .. "\n")
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
      -- Extract base URL by removing the filename part
      p.base_url = p.url:gsub("/[^/]+$", "")
      -- If that results in empty string (e.g., for root URLs), use the full domain
      if p.base_url == "" then
        p.base_url = p.url:match("(https?://[^/]+)")
      end
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
    
    if cmd_opts.args == "add" then
      -- Interactive add mode
      vim.ui.input({ prompt = "Enter project URL:" }, function(url)
        if url and url ~= "" then
          -- Remove quotes and brackets if present
          url = url:gsub("^['\"]+", ""):gsub("['\"]+$", ""):gsub("^%[+", ""):gsub("%]+$", "")
          
          local name = url:match("://([^/]+)") or "New Project"
          
          vim.ui.input({ prompt = "Enter project name (leave empty to use hostname):", default = name }, function(input_name)
            if input_name and input_name ~= "" then
              name = input_name
            end
            
            local new_project = {
              name = name,
              url = url,
              is_config = false
            }
            
            add_project(new_project, false)
            save_persisted(vim.tbl_filter(function(v) return not v.is_config end, M.state.projects))
            vim.notify("Added project: " .. name .. " (" .. url .. ")", vim.log.levels.INFO)
          end)
        end
      end)
    elseif cmd_opts.args == "manage" then
      -- Project management mode
      picker.open_project_manager(M.state.projects, function(updated_projects)
        M.state.projects = updated_projects
        save_persisted(vim.tbl_filter(function(v) return not v.is_config end, M.state.projects))
        vim.notify("Projects updated", vim.log.levels.INFO)
      end)
    elseif cmd_opts.args ~= "" then
      -- Quick add mode: :LLMDocs https://url/llms.txt
      local url = cmd_opts.args
      -- Remove quotes and brackets if present
      url = url:gsub("^['\"]+", ""):gsub("['\"]+$", ""):gsub("^%[+", ""):gsub("%]+$", "")
      
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
      -- Main menu with navigation options
      local main_menu = {
        {
          name = "Browse Projects",
          action = function()
            picker.open_project_picker(M.state.projects, function()
              -- When back from project picker, show main menu again
              M.setup(opts)
            end)
          end
        },
        {
          name = "Manage Projects",
          action = function()
            picker.open_project_manager(M.state.projects, function(updated_projects)
              M.state.projects = updated_projects
              save_persisted(vim.tbl_filter(function(v) return not v.is_config end, M.state.projects))
              vim.notify("Projects updated", vim.log.levels.INFO)
              -- After managing projects, show main menu again
              M.setup(opts)
            end)
          end
        },
        {
          name = "Add New Project",
          action = function()
            -- Reuse the add functionality
            vim.ui.input({ prompt = "Enter project URL:" }, function(url)
              if url and url ~= "" then
                url = url:gsub("^['\"]+", ""):gsub("['\"]+$", ""):gsub("^%[+", ""):gsub("%]+$", "")
                local name = url:match("://([^/]+)") or "New Project"
                vim.ui.input({ prompt = "Enter project name (leave empty to use hostname):", default = name }, function(input_name)
                  if input_name and input_name ~= "" then
                    name = input_name
                  end
                  local new_project = {
                    name = name,
                    url = url,
                    is_config = false
                  }
                  add_project(new_project, false)
                  save_persisted(vim.tbl_filter(function(v) return not v.is_config end, M.state.projects))
                  vim.notify("Added project: " .. name .. " (" .. url .. ")", vim.log.levels.INFO)
                  -- After adding, show main menu again
                  M.setup(opts)
                end)
              end
            end)
          end
        }
      }
      
       -- Add quit option
       table.insert(main_menu, {
         name = "❌  Quit",
         action = function() end
       })
       
       -- Use the universal picker for the main menu
       local picker_module = require("llm-docs.picker")
       picker_module.universal_picker("LLM Docs Main Menu", main_menu, function(selected)
         if selected.name ~= "❌  Quit" then
           selected.action()
         end
       end)
    end
  end, { nargs = "?", complete = function(arglead, cmdline, cursorpos)
    if cmdline:match("LLMDocs%s+$") then
      return { "add", "manage" }
    end
    return {}
  end })
end

return M

