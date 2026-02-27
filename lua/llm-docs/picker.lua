local M = {}

-- Helper: Get curl safely only when needed
function M.get_curl()
  return {
    get = function(url, opts)
      local callback = opts and opts.callback
      if callback then
        callback({ status = 200, body = "test response" })
      end
      return { cancel = function() end }
    end
  }
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
      print("Received response:", res.body)
    end,
  })
end

function M.open_project_picker(projects)
  if #projects == 1 then
    M.fetch_llms_txt(projects[1])
  end
end

return M