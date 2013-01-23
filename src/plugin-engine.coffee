# Require
balUtil = require('bal-util')
{EventEmitter} = require('events')

# Plugin Engine
class PluginEngine extends EventEmitter

	# Plugins that are loading really slow
	slowPlugins: null  # {}

	# Loaded plugins indexed by name
	loadedPlugins: null  # {}

	# Config
	config: {}

	# Constructor
	constructor: (config) ->
		# Extend and dereference our configuration
		@config = balUtil.extend({},@config,config)

		# Chain
		@

	# Log
	log: (args...) =>
		# Log
		@emit('log', args...)

		# Chain
		@

	# Get a plugin by it's name
	getPlugin: (pluginName) ->
		@loadedPlugins[pluginName]

	# Check if we have any plugins
	hasPlugins: ->
		return balUtil.isEmptyObject(@loadedPlugins) is false

	# Load Plugins
	loadPlugins: (next) ->
		# Prepare
		me = @
		locale = @getLocale()

		# Snore
		@slowPlugins = {}
		snore = balUtil.createSnore ->
			me.log 'notice', util.format(locale.pluginsSlow, _.keys(me.slowPlugins).join(', '))

		# Async
		tasks = new balUtil.Group (err) ->
			me.slowPlugins = {}
			snore.clear()
			return next(err)

		# Load website plugins
		_.each @config.pluginsPaths or [], (pluginsPath) =>
			exists = balUtil.existsSync(pluginsPath)
			if exists
				tasks.push (complete) =>
					@loadPluginsIn(pluginsPath, complete)

		# Load specific plugins
		_.each @config.pluginPaths or [], (pluginPath) =>
			exists = balUtil.existsSync(pluginPath)
			if exists
				tasks.push (complete) =>
					@loadPlugin(pluginPath, complete)

		# Execute the loading asynchronously
		tasks.async()

		# Chain
		@

	# Loaded Plugin
	# Checks if a plugin was loaded succesfully
	# next(err,loaded)
	loadedPlugin: (pluginName,next) ->
		# Prepare
		me = @

		# Check
		loaded = me.loadedPlugins[pluginName]?
		next(null,loaded)

		# Chain
		@

	# Load PLugin
	# next(err)
	loadPlugin: (fileFullPath,_next) ->
		# Prepare
		me = @
		config = @config
		locale = @getLocale()
		next = (err) ->
			# Remove from slow plugins
			delete me.slowPlugins[pluginName]
			# Forward
			return _next(err)

		# Prepare variables
		loader = new PluginLoader(
			dirPath: fileFullPath
			docpad: @
			BasePlugin: BasePlugin
		)
		pluginName = loader.pluginName
		enabled = (
			(config.enableUnlistedPlugins  and  config.enabledPlugins[pluginName]? is false)  or
			config.enabledPlugins[pluginName] is true
		)

		# If we've already been loaded, then exit early as there is no use for us to load again
		if me.loadedPlugins[pluginName]?
			return _next()

		# Add to loading stores
		me.slowPlugins[pluginName] = true

		# Check
		unless enabled
			# Skip
			me.log 'debug', util.format(locale.pluginSkipped, pluginName)
			return next()
		else
			# Load
			me.log 'debug', util.format(locale.pluginLoading, pluginName)

			# Check existance
			loader.exists (err,exists) ->
				# Error or doesn't exist?
				return next(err)  if err or not exists

				# Check support
				loader.unsupported (err,unsupported) ->
					# Error?
					return next(err)  if err

					# Unsupported?
					if unsupported
						# Version?
						if unsupported is 'version' and  me.config.skipUnsupportedPlugins is false
							me.log 'warn', util.format(locale.pluginContinued, pluginName)
						else
							# Type?
							if unsupported is 'type'
								me.log 'debug', util.format(locale.pluginSkippedDueTo, pluginName, unsupported)

							# Something else?
							else
								me.log 'warn', util.format(locale.pluginSkippedDueTo, pluginName, unsupported)
							return next()

					# Load the class
					loader.load (err) ->
						return next(err)  if err

						# Create an instance
						loader.create {}, (err,pluginInstance) ->
							return next(err)  if err

							# Add to plugin stores
							me.loadedPlugins[loader.pluginName] = pluginInstance

							# Log completion
							me.log 'debug', util.format(locale.pluginLoaded, pluginName)

							# Forward
							return next()

		# Chain
		@

	# Load Plugins
	loadPluginsIn: (pluginsPath, next) ->
		# Prepare
		me = @
		locale = @getLocale()

		# Load Plugins
		me.log 'debug', util.format(locale.pluginsLoadingFor, pluginsPath)
		@scandir(
			# Path
			path: pluginsPath

			# Skip files
			fileAction: false

			# Handle directories
			dirAction: (fileFullPath,fileRelativePath,_nextFile) ->
				# Prepare
				pluginName = pathUtil.basename(fileFullPath)
				return _nextFile(null,false)  if fileFullPath is pluginsPath
				nextFile = (err,skip) ->
					if err
						me.warn(util.format(locale.pluginFailedToLoad, pluginName, fileFullPath)+'\n'+locale.errorFollows, err)
					return _nextFile(null,skip)

				# Forward
				me.loadPlugin fileFullPath, (err) ->
					return nextFile(err,true)

			# Next
			next: (err) ->
				me.log 'debug', util.format(locale.pluginsLoadedFor, pluginsPath)
				return next(err)
		)

		# Chain
		@
