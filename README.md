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

### 1. Main Menu (New!)

Run

```vimscript
:LLMDocs
```
(or use your keymap).

This opens a new main menu with options:
- **Browse Projects**: View and select from your saved projects
- **Manage Projects**: Clean up and organize your projects
- **Add New Project**: Interactive project addition

All pickers now include back buttons (⬅️ Back) for easy navigation between menus.

### 2. Browse Saved Documentation

When you select "Browse Projects" from the main menu:
- A picker will show all your saved projects
- Select a project to see its available documentation files
- Choose a file to open it in a new vertical split
- Use the back button to return to the project list without opening a file
- The buffer is temporary (nofile) and will silently disappear when closed.

### 5. Navigation Controls

All pickers support back navigation:
- **fzf-lua**: Press `Ctrl+B` to go back
- **Telescope**: Press `<Backspace>` to go back  
- **Native vim.ui.select**: Select the "⬅️ Back" option

Navigation flow:
```
Main Menu
├─ Browse Projects → Project List → Document List → Document View
│                                  ⬆ (Backspace)           ⬆ (Backspace)
│                                  └──────────────────────┘
├─ Manage Projects → (Delete options) → Main Menu
│                                   ⬆ (Backspace)
└─ Add New Project → (Input prompts) → Main Menu
```

Use `<Backspace>` at any time to return to the previous menu or quit the plugin.

### 2. Quick Add Mode

Run

```vimscript
:LLMDocs <URL>
```

to quickly add a new llms.txt file. The URL can be entered with or without quotes/brackets.

**Navigation Tip**: Use `<Backspace>` to go back to the main menu from any picker.

### 3. Interactive Add Mode

Run

```vimscript
:LLMDocs add
```

to open an interactive prompt where you can:
- Enter the project URL (without quotes or brackets)
- Enter a custom name (or leave empty to use the hostname)
- The project will be saved permanently to your library.

**Navigation Tip**: After adding, you'll return to the main menu automatically.

### 4. Manage Projects

Run

```vimscript
:LLMDocs manage
```

to open the project manager where you can:
- View all saved projects
- Delete projects you no longer need (select "🗑️ DELETE: project-name")
- Clean up your documentation library

**Navigation Tip**: Use `<Backspace>` to return to the main menu after managing projects.
- Use the back button to return to the main menu

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

