# NvimLocale
Snippet(s) of custom, local-to-project configuration: powered by [deatharte.api](https://github.com/DrKGD/deatharte.api.nvim) and dependencies.

# TODO
- Consider more use-cases and/or interactions.
- Distinguish required and optional features for each module (e.g. previewer is not really required for latex module to work, and should be possible to disable it entirely)
- Provide a default system for instance selection, at the moment it is _almost_ a requirement to provide a meaningful name to the project.
- Define a global setup method
    - Permanent task configuration (e.g. always use pdf_previewer `okular` instead of `sioyek`)

## Installation
_Plug_ the configuration within your favorite package manager.

### e.g. Lazy.nvim
```lua
{ "DrKGD/deatharte.api.nvim",
    lazy = true,
    dependencies = {
        -- # Persistent tracker entries
        { 'kkharji/sqlite.lua' },

        -- # Async jobs
        { 'nvim-lua/plenary.nvim' },

        -- # Notificator wrapper for notifications
        { 'rcarriga/nvim-notify' },

        -- # Which-key integration
        { 'folke/which-key.nvim' }
    },

    config = function()
        require('deatharte').setup {
            -- ... options ...
        }
    end },

{ "DrKGD/nvimlocale.nvim",
    lazy = true,
    dependencies = {
        -- # Required 
        { "DrKGD/deatharte.api.nvim" },

        -- # Optional, store project configuration onto a local 
        -- file which has to be trusted by the user
        { "klen/nvim-config-local",
            lazy = false,
            config = function()
                require('config-local').setup {
                    -- # Store the local configuration in .nvim.lua
                    -- Will be automatically sourced when current working directory
                    --  matches a file with the following name
                    config_files = { '.nvim.lua' }
                }
            end }
    }
```

## Setup
Run the setup method, thus select and customize global and per-module settings/flags.

**Note** I'd suggest [nvim-config-local](https://github.com/klen/nvim-config-local) over the
built-in `exrc` for security reasons, thus the partial configuration has to be personally *trusted*
before getting sourced automatically. Upcoming feature `:trust` of nvim 0.9 will soon deprecate this requirment!


```lua
-- # Just require modules with the default configuration for the modules
require('nvimlocale').setup { modules = { 'latex' }, instance = 'my-project-name' }

-- # Pass in custom setup from the local project (e.g. using nvim-config-local)
require('nvimlocale').setup {
    instance = 'my-project-name',

	modules = {
		-- # Configure latex module
		{ 'latex', {
            -- # Replace current previewer with zathura instead
            preview = {
                command = 'zathura'
            }

			-- # Start previewer automatically
			init = {
				previewer = true
			}
		} }
	}
}
```

It is also possible to run `lua require('nvimlocale').setup{ ... }` from the nvim commandline instead.

# Available Modules
Each module has its own requirements, both binaries and other plugins.

## Latex
Write, compile and preview latex documents without ever quitting the nvim instance!

This module provides:
- _tracked_ files are permanently stored between per setup instance, powered by [sqlite](https://github.com/kkharji/sqlite.lua).
- auto-compile on tracked file change(s) (within the nvim instance, or with the aid of external programs, such as `gimp`) using inotifywait. This feature can be turned on and off whenever the user (you) requires to do so.
- manages a previewer instance (e.g. `sioyek`, `okular`, ...), thus the ability to start and kill the process automatically on nvim enter/quit.
- issuing a compile command automatically kills and restarts the process.
- custom defined keybindings and autocommands.

Required packages
- [deatharte.api.nvim](https://github.com/DrKGD/deatharte.api.nvim) which wraps all the following functionalities.
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) to spawn and handle external jobs from within nvim.
- [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify) for custom notifications.
- [kkharji/sqlite.lua](https://github.com/kkharji/sqlite.lua) for a persistent tracker.
- (optional) [folke/which-key](https://github.com/folke/which-key.nvim) to provide a keymap legend over mapped keys.

Required binaries
- A pdf previewer, by default is set to `sioyek`
- A latex compiler engine, by default set to `lualatex`
- [inotifywait](https://linux.die.net/man/1/inotifywait), to detect file changes using linux interface.

