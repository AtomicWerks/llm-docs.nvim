local M = {}

-- Helper: Get curl safely only when needed
local function get_curl()
  local ok, curl = pcall(require, "curl")
  if not ok then
    vim.notify("llm-docs: curl.nvim not found in runtime path", vim.log.levels.ERROR)
    return nil
  end
  return curl
end

local function display_markdown(url, title)
  local curl = get_curl()
  if not curl or not curl.get then return end

  curl.get(url, {
    callback = function(res)
      if res.status ~= 200 then
        vim.schedule(function() print("Error: Failed to fetch " .. title) end)
        return
      end
      
      vim.schedule(function()
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Modern API for setting options
        vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
        vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
        vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
        vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
        
        local lines = vim.split(res.body, "\n")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        
        vim.api.nvim_command("vsplit")
        vim.api.nvim_win_set_buf(0, buf)
        vim.api.nvim_buf_set_name(buf, title)
      end)
    end,
  })
end

-- Abstracted picker logic remains the same (handles fzf/telescope/native)
local function universal_picker(title, items, callback)
  local has_fzf, fzf = pcall(require, "fzf-lua")
  if has_fzf then
    local fzf_items = {}
    for _, item in ipairs(items) do table.insert(fzf_items, item.name) end
    fzf.fzf_exec(fzf_items, {
      prompt = title .. "> ",
      actions = {
        ["default"] = function(selected)
          for _, item in ipairs(items) do
            if item.name == selected[1] then callback(item) break end
          end
        end,
      },
    })
    return
  end

  local has_tele, _ = pcall(require, "telescope")
  if has_tele then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
      prompt_title = title,
      finder = finders.new_table({
        results = items,
        entry_maker = function(entry)
          return { value = entry, display = entry.name, ordinal = entry.name }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          callback(selection.value)
        end)
        return true
      end,
    }):find()
    return
  end

  vim.ui.select(items, {
    prompt = title,
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then callback(choice) end
  end)
end

function M.fetch_llms_txt(project)
  local curl = get_curl()
  if not curl then return end

  curl.get(project.url, {
    callback = function(res)
      if res.exit ~= 0 then return end
      local files = {}
      
      -- Helper to normalize the base URL for joining
      local base = project.base_url:gsub("/$", "")
      
      for name, link in res.body:gmatch("%[(.-)%]%((.-)%)") do
        local full_link = link:match("^http") and link or (base .. "/" .. link:gsub("^/", ""))
        table.insert(files, { name = name, link = full_link })
      end
      
      vim.schedule(function()
        universal_picker("Docs: " .. project.name, files, function(selection)
          display_markdown(selection.link, selection.name)
        end)
      end)
    end,
  })
end

function M.open_project_picker(projects)
  if #projects == 1 then
    M.fetch_llms_txt(projects[1])
  else
    universal_picker("Select Project", projects, function(selection)
      M.fetch_llms_txt(selection)
    end)
  end
end

return M

