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
- **Robust HTTP Client**:
- Uses `curl.nvim` when available for enhanced HTTP functionality.
- Automatically falls back to system `curl` command if `curl.nvim` is not installed.

## ⚡ Requirements

Neovim >= 0.9.0
`curl` installed on your system (required for HTTP requests).

## 📦 Installation

Install using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "atomicwerks/llm-docs.nvim",
  dependencies = {
    -- Optional: curl.nvim for enhanced HTTP functionality (falls back to system curl)
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

```vimscript
:LLMDocs
```
(or use your keymap).

If you have multiple projects saved, a picker will ask you to select a project.
Once a project is selected, a second picker will display all available
documentation files for that project.
Press <Enter> to open the content in a new vertical split.
The buffer is temporary (nofile) and will silently disappear when closed.

### 2. Add New Documentation on the Fly

Run

```vimscript
:LLMDocs <URL>
```

to quickly add a new llms.txt file. The URL can be entered with or without quotes/brackets.

### 3. Interactive Add Mode

Run

```vimscript
:LLMDocs add
```

to open an interactive prompt where you can:
- Enter the project URL (without quotes or brackets)
- Enter a custom name (or leave empty to use the hostname)
- The project will be saved permanently to your library.

### 4. Manage Projects

Run

```vimscript
:LLMDocs manage
```

to open the project manager where you can:
- View all saved projects
- Delete projects you no longer need
- Clean up your documentation library

Example:

```vimscript
:LLMDocs [https://fastapi.tiangolo.com/llms.txt](https://fastapi.tiangolo.com/llms.txt)
```

The plugin parses the base URL, fetches the index, and saves it to

```vimscript
~/.local/share/nvim/llm_docs_projects.json
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
      base_url = "https://docs.vendure.io",
    },
    {
      name = "OpenAI",
      url = "[https://platform.openai.com/llms.txt](https://platform.openai.com/llms.txt)",
      base_url = "[https://platform.openai.com](https://platform.openai.com)",
    },
  },
}

Note: Projects defined in opts are merged seamlessly with the projects you add via the command line.

