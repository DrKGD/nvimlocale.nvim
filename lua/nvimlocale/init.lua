-- # nvimlocale
local	ntf				= require('deatharte-api.hnd.notificator').new { name = 'nvimlocale', render = 'default' }

----------------
---   Deps   ---

-- # Deatharte api IS a requirement
local ok, _ = pcall(require, 'deatharte-api')
if not ok then
	vim.notify('‹deatharte.api.nvim› was not found, ensure it is installed!', vim.log.levels.ERROR, {
		plugin = 'nvimlocale'
	})

	return
end

---   Deps   ---
----------------
--- Internal ---

local defaults = { }
	-- # Which sources should be ‹sourced›
	--  At least one module is required
	--   Modules should have a setup function
	--   
	--  Available modules
	--   at nvimlocale/modules
	defaults.modules = { }

	-- # Global flags to disable custom commands and/or keybindings
	-- For all the given modules
	-- # Should be registering commands
	defaults.register_commands = true

	-- # Which absolute prefix should serve as selector
	-- May be disabled using false or empty string ‹''›
	-- 
	defaults.cmd_leader_prefix	= 'Locale'

	-- # Should be registering keybindings
	defaults.register_keybinds	= true

	-- # Which key combination should serve as "leader" prefix
	-- May be disabled using false or empty string ‹''›
	defaults.key_leader_prefix	= '<Leader>'

	-- # Default instance, I'd suggest to overwrite this with whichever
	-- the project name may be on the local configuration
	defaults.instance						= 'nvimlocale.default'

	-- # No info notifications on startup
	defaults.silent_on_startup	= false

local M = { }

--- Internal ---
----------------
---    API   ---

local function retmodule(mod)
	local hasmodule, setup = pcall(require, ('nvimlocale.modules.%s'):format(mod))

	if not hasmodule then
		ntf:warn({
				message = ("Module ‹%s› is not available!"):format(mod),
				nodismiss = true,
				noreplace = true
			})

		return false
	end

	return setup
end

local function retsetup(mod)
	local tmod = type(mod)

	-- # Custom function are accepted, but useless
	if tmod == 'function' then
		return mod, { } end

	-- # Check whether or not the setup is a string or a function
	if tmod == 'table'		then
		local setup = mod.name or mod.setup or mod[1]
		if type(setup) == 'string' then
			setup = retmodule(setup) end

		return setup, mod.opts or mod[2] or { }
	end

	-- # Check if string module is found
	if tmod == 'string'		then
		return retmodule(mod), { }
	end

	return false, false
end

-- # Setup plugin
M.setup = function(opts)
	-- # Extend config
	local config = vim.tbl_deep_extend("force", defaults, opts or { })

	-- # Check if any module was selected
	if #config.modules == 0 then
		ntf:warn({
				message = "No modules selected!",
				nodismiss = true,
				noreplace = true
			})

		return
	end

	-- # Warn if default instance is being used
	if config.instance == defaults.instance then
		ntf:warn({
				message = ("Default instance ‹%s› is being used, please enter a meaningful name to prevent unwanted behaviour!"):format(defaults.instance),
				nodismiss = true,
				noreplace = true,
			})
	end

	-- # Move modules to another table
	local modules = config.modules
	config.modules = nil

	-- # Run all specified setup(s)
	for _, module in ipairs(modules) do
		local msetup, mopts = retsetup(module)
		if msetup then msetup(config, mopts) end
	end
end

---    API   ---
----------------

return M
