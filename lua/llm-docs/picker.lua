local M = {}

-- Helper: Get curl safely only when needed
function M.get_curl()
  -- Try to require it normally
  local ok, curl = pcall(require, "curl")

  -- If it's not loaded (likely due to lazy loading), try to force load it
  if not ok or type(curl) ~= "table" or not curl.get then
    local has_lazy, lazy = pcall(require, "lazy")
    if has_lazy then
      lazy.load({ plugins = { "curl.nvim" } })
      ok, curl = pcall(require, "curl")
    end
  end

  if not ok or type(curl) ~= "table" or not curl.get then
    vim.notify("llm-docs: curl.nvim API not found. Falling back to system curl.", vim.log.levels.WARN)
    -- Return a fallback implementation using system curl
    return {
      get = function(url, opts)
        local callback = opts and opts.callback
        if not callback then
          vim.notify("llm-docs: No callback provided for HTTP request", vim.log.levels.ERROR)
          return
        end

        -- Use vim.system if available (Neovim 0.10+), otherwise fall back to vim.fn.system
        local function make_request()
          local cmd = { "curl", "-s", "-S", url }

          local function on_exit(obj)
            if obj.code ~= 0 then
              callback({ status = obj.code, body = obj.stderr or "" })
            else
              callback({ status = 200, body = obj.stdout or "" })
            end
          end

          if vim.system then
            vim.system(cmd, { text = true }, on_exit)
          else
            -- Fallback for older Neovim versions
            local handle = io.popen(table.concat(cmd, " ") .. " 2>&1")
            local result = handle:read("*a")
            handle:close()

            -- Simple check: if result contains common error patterns, consider it an error
            if result:match("curl:%") or result:match("Failed to connect") or result:match("Could not resolve") then
              callback({ status = 1, body = result })
            else
              callback({ status = 200, body = result })
            end
          end
        end

        vim.schedule(make_request)

        return { cancel = function() end } -- Return a mock object with cancel method
      end
    }
  end
  return curl
end

local function display_markdown(url, title)
  local curl = M.get_curl()
  if not curl or not curl.get then
    return
  end

  curl.get(url, {
    callback = function(res)
      if res.status ~= 200 then
        vim.schedule(function()
          print("Error: Failed to fetch " .. title)
        end)
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
    for _, item in ipairs(items) do
      table.insert(fzf_items, item.name)
    end
    fzf.fzf_exec(fzf_items, {
      prompt = title .. "> ",
      actions = {
        ["default"] = function(selected)
          for _, item in ipairs(items) do
            if item.name == selected[1] then
              callback(item)
              break
            end
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

    pickers
      .new({}, {
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
      })
      :find()
    return
  end

  vim.ui.select(items, {
    prompt = title,
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      callback(choice)
    end
  end)
end

function M.fetch_llms_txt(project)
  local curl = M.get_curl()
  if not curl then
    vim.notify("llm-docs: Cannot fetch documentation - curl.nvim not available", vim.log.levels.ERROR)
    return
  end

   curl.get(project.url, {
    callback = function(res)
      if res.status ~= 200 then
        return
      end
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
