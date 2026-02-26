# llm-docs.nvim

A Neovim plugin to browse and read documentation from projects that provide an `llms.txt` file.
Powered by `curl.nvim` with seamless support for `fzf-lua` or `telescope.nvim`.

## ✨ Features

- **Zero-Friction Browsing**:
  - Asynchronously fetches and parses `llms.txt` files directly into temporary Markdown buffers.
- **Dynamic Persistence**:
  - Add new documentation URLs on the fly via the command line.
- They are automatically saved to your local Neovim data directory for future sessions.
  - **Picker Agnostic**:
- Automatically detects and uses `fzf-lua` or `telescope.nvim`.
  - Falls back to Neovim's native `vim.ui.select` if neither is installed.

## ⚡ Requirements

Neovim >= 0.9.0
`curl` installed on your system.

## 📦 Installation

Install using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/llm-docs.nvim",
  dependencies = {
    "oysandvik94/curl.nvim",
    -- Optional: highly recommended for the best UI experience
    "ibhagwan/fzf-lua", 
    -- "nvim-telescope/telescope.nvim",
  },
  cmd = "LLMDocs",
  opts = {}, -- See Configuration below to pre-seed projects
  keys = {
    { "<leader>ld", "<cmd>LLMDocs<cr>", desc = "Browse LLM Docs" }
  }
}
```

## 🚀 Usage

The plugin provides a single, smart command: :LLMDocs.

### 1. Browse Saved Documentation

Run

```sh :LLMDocs (or use your keymap).
```

If you have multiple projects saved, a picker will ask you to select a project.
Once a project is selected, a second picker will display all available
documentation files for that project.
Press <Enter> to open the content in a new vertical split.
The buffer is temporary (nofile) and will silently disappear when closed.

### 2. Add New Documentation on the Fly

Run

```sh :LLMDocs <URL>
```

to fetch a new llms.txt file, open the file picker,
and save it permanently to your library.

Example:

```sh :LLMDocs [https://fastapi.tiangolo.com/llms.txt](https://fastapi.tiangolo.com/llms.txt)
```

The plugin parses the base URL, fetches the index, and saves it to

```sh ~/.local/share/nvim/llm_docs_projects.json
```

Next time you run :LLMDocs, FastAPI will be in your project list.
⚙️ Configuration (Optional)

You don't need to define any URLs in your configuration; you can build your library
entirely via the command line. However, if you prefer to manage your sources
declaratively in your init.lua or version control, you can pass them into opts:

```Lua
opts = {
  projects = {
    {
      name = "Vendure",
      url = "[https://docs.vendure.io/llms.txt](https://docs.vendure.io/llms.txt)",
      base_url = "[https://docs.vendure.io](https://docs.vendure.io)",
    },
    {
      name = "OpenAI",
      url = "[https://platform.openai.com/llms.txt](https://platform.openai.com/llms.txt)",
      base_url = "[https://platform.openai.com](https://platform.openai.com)",
    },
  },
}

Note: Projects defined in opts are merged seamlessly with the projects you add via the command line.

