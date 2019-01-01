# Plugin Engine

**NOTE:** [This project was replaced by the functioning `pluginloader` project.](https://github.com/bevry/pluginloader)

Currently under construction. The goal is to have an API like:

``` coffee
# Import
{PluginEngine} = require('plugin-engine')

# Create Plugin Engine Instance
pluginEngine = new PluginEngine({
	# Where to load plugins from?
	modulesPaths: [__dirname+'/node_modules']
	
	# Loaded plugins must have this tag in their package.json file
	tag: 'docpad-plugin'

	# Ensure the plugin supports these engines
	engines:
		'docpad': '6.22.0'

	# Pass these options over to our plugins during instantiation
	instantiationOpts:
		BasePlugin: require(__dirname+'/out/base-plugin')
}).loadPlugins()
```

With an example plugin looking like:

```
module.exports = (instantiationOpts) ->
	{BasePlugin} = instantiationOpts
	class Plugin extends BasePlugin
```

Things to still figure out:

1. How to handle plugin and parent events
1. How to expose the parent object to the plugins
1. Priorities for events


## History

[You can discover the history inside the `History.md` file](https://github.com/bevry/plugin-system/blob/master/History.md#files)


## License

Licensed under the incredibly [permissive](http://en.wikipedia.org/wiki/Permissive_free_software_licence) [MIT License](http://creativecommons.org/licenses/MIT/)
<br/>Copyright &copy; 2012+ [Bevry Pty Ltd](http://bevry.me)
<br/>Copyright &copy; 2011 [Benjamin Lupton](http://balupton.com)
