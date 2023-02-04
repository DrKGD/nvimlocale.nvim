--- # latex
local utilvim		= require('deatharte.util.vim')
local utildeps	= require('deatharte.util.deps')
local	ntf				= require('deatharte.hnd.notificator').new { name = 'nvimlocale.module.latex', render = 'default' }

----------------
---   Deps   ---

---   Deps   ---
----------------
--- Internal ---

local KEEP = {
	WATCHER			= nil,
	TRACKER			= nil,
	COMPILE			= nil,
	PREVIEWER		= nil,
}

local DEFAULTS = {
	-- # Module key prefix
	key_prefix = 'w',

	-- # Handle inotifywait
	inotifywait = {
		-- # Filter out these from the notifications
		filter	= {
			type = 'blacklist',
			extension	= {
				'aux', 'log', 'synctex.gz', 'pdf', 'out', 'toc', 'ptc'
			},
		},

		-- # Works specifically on these events
		events	= { 'modify' },

		-- # Stats callback
		on_status_update = {
			{ condition = function(status) return status end, callback = function(_, obj)
					obj.notify:info('Watcher is now active 🌴 ')
				end, bypass = true },

			{ condition = function(status) return not status end, callback = function(_, obj)
					obj.notify:info('Watcher is now disabled 🌵 ')
				end, bypass = true },
		},

		on_stdout = {
			function(_, _, _, _, store)
				if store.output.evlist.MODIFY then
					vim.schedule(function()
						local abspath = vim.fn.fnamemodify(store.output.file, ':.')

						KEEP.TRACKER:callback(abspath, function()
							KEEP.COMPILE:respawn()
						end )
					end)
				end
			end
		},

		on_stderr = { },
	},

	preview = {
		-- # Internal name for the prochandler
		name = 'previewer',

		-- # Preview document using sioyek
		cwd = './',

		-- # Process
		command = 'sioyek',
		args = { },

		-- # Disable stdout, stderr
		on_stdout = { },
		on_stderr = { },

		-- # Events which fires upon starting the job
		on_start	= {
			function(_, obj)
				obj.notify:info(('Previewer ‹%s› was opened!'):format(obj._init.name))
			end
		},

		on_exit		= {
			function(_, _, _, obj)
				obj.notify:info(('Previewer ‹%s› was closed!'):format(obj._init.name))
			end
		},
	},

	compile = {
		-- # Internal name for the prochandler
		name = 'compiler',

		-- # Name of the document which has to be compiled
		compile_src = 'main',

		-- # Document is compiled at the current folder 
		cwd = './',

		-- # Allow process even after nvim instance has expired (quit)
		persist_onexit = true,

		-- # Disable stdout, stderr
		on_stdout = { },
		on_stderr = { },

		-- # Compile engine
		command = 'lualatex',
		args = {
			"--synctex=1",
			"--shell-escape",
			"--halt-on-error",
			"--interaction=batchmode",
		},

		-- # Events which fires upon starting the job
		on_start	= {
			function(_, obj)
				obj.notify:info({ message = ('Compilation job for ‹%s.pdf› started 🟢 ')
					:format(obj._init.compile_src), nodismiss = true })
			end
		},

		-- # Events which fires upon exiting
		on_exit	= {
			{ condition = function(_, ecode, signal) return ecode == 0 and signal == 0 end,
				callback = function(_, _, _, obj)
					obj.notify:info({ message = ('Document ‹%s.pdf› has been updated 🟩 '):format(obj._init.compile_src), timeout = 1000 })
				end },

			{ condition = function(_, ecode) return ecode ~= 0 end, callback = function(_, _, _, obj)
					obj.notify:warn({ message= ('Compilation job for ‹%s.pdf› failed 🟥 '):format(obj._init.compile_src), timeout = 1000 })

				end }
		},

		-- # Events which fires upon killing the compilation job
		on_kill = {
			function(obj)
				obj.notify:info({ message = ('Compilation job for ‹%s.pdf› was aborted 🟧 '):format(obj._init.compile_src), timeout = 1000 })
			end
		},

		-- # Events which fires upon respawning the compilation job
		on_respawn = {
			function(obj)
				obj.notify:info({ message = ('Compilation job for ‹%s.pdf› restarted 🟦 '):format(obj._init.compile_src), nodismiss = true})
			end
		}
	},

	-- # Which processes should be initialized
	init = {
		-- # Watcher is already watching 
		watcher = true,

		-- # Open previewer automatically
		previewer = true,
	}
}

local wl_toggle_filebuffer = function()
	-- # Check whether or not the file has a valid name
	local fn = vim.api.nvim_buf_get_name(0)
	if vim.fn.empty(fn) == 1 then
		return ntf:warn('Unnamed buffer could not be added to the tracker!') end

	-- # Only "file" buffers will be tracked
	if vim.fn.empty(vim.bo.buftype) == 0 then
		return ntf:warn('Special buffers will not be tracked!') end

	-- # Ultimately add the relative path to the file to the tracker list
	local fnformat = vim.fn.fnamemodify(fn, ':.')
	KEEP.TRACKER:toggle(fnformat)
end

local wl_hasfile = function()
	local fn = vim.api.nvim_buf_get_name(0)
	if vim.fn.empty(fn) == 1 then
		return ntf:warn('Currently on an unnamed buffer!') end

	local fnformat = vim.fn.fnamemodify(fn, ':.')
	if KEEP.TRACKER:has(fnformat) then
		ntf(('Current file ‹%s› is being watched 👀 '):format(fnformat), 'info')
	else
		ntf(('Current file ‹%s› is not on the watch 😤 '):format(fnformat), 'info')
	end
end


local COMMANDS = {
	-- # Manage inotifywait watcher status
	{ 'ToggleWatcher',	function() KEEP.WATCHER:toggle_callbacks() end },

	-- # Manage Watchlist
	{ 'WatchlistToggleFile', wl_toggle_filebuffer },
	{ 'WatchlistHasFile', wl_hasfile},

	-- # Handle compilation job manually
	{ 'CompileNow', function() KEEP.COMPILE:respawn() end },
	{ 'CompileHalt', function() KEEP.COMPILE:kill() end },

	-- # Previewer
	{ 'TogglePreviewer', function()
		KEEP.PREVIEWER:spawn_or_kill()
	end },
}

local KEYBINDINGS = {
	-- # Watcher (inotifywait) events
	{ 'p', function() KEEP.WATCHER:toggle_callbacks() end,
		description = 'Toggle watcher', mode = { 'n' }},

	-- # Previewer
	{ 'v', function() KEEP.PREVIEWER:spawn_or_kill() end,
		description = 'Toggle previewer', mode = { 'n' }},

	-- # Manual compilation related
	{ 'c', function() KEEP.COMPILE:respawn() end,
		description = 'Compile document', mode = { 'n' }},
	{ 'k', function() KEEP.COMPILE:kill() end,
		description = 'Kill current compilation process', mode = { 'n' }},

	-- # Watchlist related
	{ 'a', wl_toggle_filebuffer, description = 'Toggle document from watchlist', mode = { 'n' }},
	{ '?', wl_hasfile, description = 'Check whether or not the file is being watched', mode = { 'n' }},
}

--- Internal ---
----------------
local loaded_configuration = nil

-- # Cleanup function in case parameters were changed 
local reload = function()
	if KEEP.WATCHER		then KEEP.WATCHER:kill() end
	if KEEP.PREVIEWER then KEEP.PREVIEWER:kill() end
	KEEP = { }

	-- # Delete user keybindings
	if loaded_configuration.register_keybinds then
		utilvim.delete_keybindings(KEYBINDINGS, loaded_configuration)
	end

	-- # Delete user commands
	if loaded_configuration.register_commands then
		utilvim.delete_usercommands(COMMANDS, loaded_configuration)
	end

	ntf:info({ message = 'Configuration was reloaded!'})
end

local reqs = function(config)
	local reqdeps = {
		{ binary = "inotifywait", desc = "Check files for update"},
		{ binary = config.preview.command, desc = "Preview output document"},
		{ binary = config.compile.command, desc = "Compile source" },
	}

	local missingdeps = utildeps.missingdeps(reqdeps)
	if missingdeps then
		local msg = { 'The following dependencies are not satisfied:' }
		---@diagnostic disable-next-line: param-type-mismatch
		for _, missing in ipairs(missingdeps or { }) do
			msg[#msg + 1] = ('   ‹%s›, %s, which is required for «%s»'):format(missing.name, missing.type, missing.desc)
		end

		ntf:error { message = msg }
		return false
	end

	print(vim.inspect(missingdeps))

	return true
end

return function(globalopts, moduleopts)
	-- # Whether the configuration was reloaded
	if loaded_configuration then reload() end

	-- # Merge all configuration tables
	local config = vim.deepcopy(DEFAULTS)
		config = vim.tbl_deep_extend("force", config, globalopts)
		config = vim.tbl_deep_extend("force", config, moduleopts)

	-- # Do not configure if configuration is missing
	if not reqs(config) then return end

	loaded_configuration = config

	-- # Start inotifywait watcher
	KEEP.WATCHER = require('deatharte.jobs.builtin.inotifywait').new(config.inotifywait)

	-- # Initialize watchlist (will automatically source all the watched files)
	KEEP.TRACKER = require('deatharte.hnd.tracker').new(('lualatex.%s'):format(config.instance))

	-- # Initializze compile job
	config.compile.args[#config.compile.args+1] =
		('%s.tex'):format(config.compile.compile_src)
	KEEP.COMPILE = require('deatharte.jobs.prochandler').new(config.compile)

	-- # Initialize previewer job
	config.preview.args[#config.preview.args+1] =
		('%s.pdf'):format(config.compile.compile_src)
	KEEP.PREVIEWER = require('deatharte.jobs.prochandler').new(config.preview)

	-- # Setup bindings
	if config.register_commands then
		utilvim.setup_usercommands(COMMANDS, config)
	end

	if config.register_keybinds then
		utilvim.setup_keybindings(KEYBINDINGS, config)
	end

	-- # No callbacks at startup if so required
	if config.silent_on_startup then
		KEEP.WATCHER:block_callbacks(true)
		KEEP.PREVIEWER:block_callbacks(true)
	end

	-- # Startup section handler
	KEEP.WATCHER:start()
	KEEP.WATCHER:set_callbacks(config.init.watcher, true)
	if config.init.previewer then KEEP.PREVIEWER:start() end

	-- # Resume callbacks from this point on
	KEEP.PREVIEWER:resume_callbacks(true)
end
