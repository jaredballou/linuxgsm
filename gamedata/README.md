# Game Data Files
## General Info
These files are the proof of concept of my new method of supporting all the games LGSM covers. It's basically a hierarchial way to define three things:
 * Script Parameters: These are things like executable, game name, local directories, and all the rest.
 * Server Parameters: These are the command-line switches that we give to the actual game server daemon. There is a little bit of smarts around the Source and GoldSource parsers, we feed it "minus parameters" and "plus parameters", and it spits them out in a somewhat sane order.
 * Server Settings: These are the items that go into _default.cfg for each game. They include the values for the two types of parameters, and are overridden hierarchially by sourcing _default.cfg, then _common.cfg, then $instance.cfg from the cfg/servers directory.
The gamedata files themselves use a few simple functions to do their magic.
## Functions
---
### fn_flush_game_settings()
This function clears out all the collector files in $settingsdir (default is ${lgsmdir}/settings.tmp). It is run at every execution of the script right now, eventually the goal is to only regenerate these files when gamedata updates are pulled.
---
### fn_import_game_settings()
This function takes one parameter, the name of the gamedata file to load. The main script calls it with the name of the main script file being called. With this method, the same "basic" script is used for all game servers, and we simply name it "insserver" or "csgoserver" for instance. Symlinks then pick up the main script to make this work for multiple-instance deployments.
In the gamedata files themselves, they are used to pull in other gamedata files. This is done in sequence, so it's usually best to do the import at the top of the file, and then overwrite. It is possible to import multiple files inside a single gamedata file, for instance include _source and _source_workshop to pull in Source engine sane defaults and the Workshop variables. Any "base" gamedata file (that is, not for a specific game) should be prefixed with a "_". The gamedata files for each engine should be named _${engine}.
---
### fn_set_game_params()
Takes four parameters:
 * param_set: The set of key-value pairs to update. You can create as many sets as you want, the only restriction is the set name must validate as a usable file name. For instance, I use parms_minus and parms_plus to separate the "-" and "+" parameters for the Server, and then I parse them in fn_parms() to assemble them. The reserved names are:
 ** settings: which will be parsed into the values in cfg/servers/*.cfg
 ** parms: Common name for server daemon parameters. Should have one key declared, also named "parms" which is a string of the command-line arguments to pass to the game server.
 * param_name: The "key", this will be a Bash variable name so it should only be alphanumeric if you want to parse it. The parms_(minus|plus) files break this convention, as part of how we process them, but ideally they would all be able to be sourced and return the expectec values.
 * param_value: The "default" to set the key to. Should be a single string, escape all quotes. If you want to reference a variable, use the \${varname} syntax, that way the actual value saved to that set will retain the variabe name, rather than interpolating. Special values are:
 ** "--UNSET--" or "": the parser will REMOVE that key from the param_set. Useful if an engine usually has a certain parameter, but one specific game does not. This allows you to set the default in the engine gamedata file, and then just deletre it for the specific games that don't need it.
 ** "--EMPTY--": This will set the value to "" (an empty string) and add it to the param set. This is useful for parameters that must be defined, but have no default value.
 * param_comment: This is the comment to append at the end of the line. If overriding a key set earlier in the hierarchy, leaving this blank will reuse the original comment. If you want to delete the comment, use "--EMPTY--".
---
### fn_parms()
This is the same old function from the original LGSM main scripts, the difference is we now have a "sane default" one in _default that just dumps params, and then each engine/game can get fancy if need be. This function gets overridden by the highest-ordered declaration, and for most games the default should be fine. The idea here is that we define flexible functions in each engine, and then allow the games to add/modify/delete keys in the data.
## Examples
This is an example of a gamedata file for the Widgets engine. We'll call it _widgets for the sake of argument:
```bash
# Import default settings
fn_import_game_settings _default

# This is the way we create a script that collates and parses the parameters
fn_parms(){
	parms="$(echo $(sed -e 's/=\"/ /g' -e 's/\"$//g' ${settingsdir}/parms_minus)) ${srcds_parms} $(echo $(sed -e 's/=\"/ /g' -e 's/\"$//g' ${settingsdir}/parms_plus))"
}
# The parms that start with - go first
fn_set_game_params parms_minus "game" "\${game}"
fn_set_game_params parms_minus "strictportbind" "--EMPTY--"
fn_set_game_params parms_minus "ip" "\${ip}"
fn_set_game_params parms_minus "tickrate" "\${tickrate}"
fn_set_game_params parms_minus "port" "\${port}"

# Then the parms that start with +
fn_set_game_params parms_plus "servercfgfile" "\${servercfg}"
fn_set_game_params parms_plus "map" "\${defaultmap}"

# And the settings for defaults
fn_set_game_params settings "appid" "99999" "Steam App ID"
fn_set_game_params settings "defaultmap" "my_map" "Default map to load"
fn_set_game_params settings "engine" "widgets" "Game Engine"
fn_set_game_params settings "game" "widgets" "Name of game to pass to srcds"
fn_set_game_params settings "gamename" "widgets" "Name for subdirectory in GitHub repo"
fn_set_game_params settings "port" "99999" "Port to bind for server"
fn_set_game_params settings "servercfg" "\${selfname}.cfg" "Server Config file"
fn_set_game_params settings "steampass" "--EMPTY--" "Steam Password"
fn_set_game_params settings "steamuser" "anonymous" "Steam Username"

# These are values that the script uses, they don't get used by the srcds server directly
fn_set_game_params settings "systemdir" "\${filesdir}/\${game}"
fn_set_game_params settings "gamelogdir" "\${systemdir}/logs"
fn_set_game_params settings "executabledir" "\${filesdir}"
fn_set_game_params settings "executable" "./widgets_server"
fn_set_game_params settings "servercfg" "\${servicename}.cfg"
fn_set_game_params settings "servercfgdir" "\${systemdir}/cfg"
fn_set_game_params settings "servercfgfullpath" "\${servercfgdir}/\${servercfg}"
fn_set_game_params settings "servercfgdefault" "\${servercfgdir}/lgsm-default.cfg"
```
Then, we need a game! DooDads is the name of the game, and just imports the defaults from its engine.
```bash
# Import SRCDS
fn_import_game_settings _widgets

# Delete tickrate parameter. This will remove it from the parameters, and remove it from _default.cfg
fn_set_game_params parms_minus "tickrate" "--UNSET--"
fn_set_game_params settings "tickrate" "--UNSET--"

# Add playlist parameter
fn_set_game_params parms_plus "sv_playlist" "\${playlist}"

# Override some server settings
fn_set_game_params settings "executable" "./doodads_server"
fn_set_game_params settings "appid" "100000"
fn_set_game_params settings "defaultmap" "special_map"
fn_set_game_params settings "game" "doodads"
fn_set_game_params settings "playlist" "custom" "Server Playlist"
fn_set_game_params settings "gamename" "DooDads"
```
With this, we inherit everything from _widgets, but remove the tickrate setting, add playlist, and override some of the settings to make sure we install the right game via Steam. End users can then override the defaults in _connon.cfg and ${servicename}.cfg for doing things their own way. The script will keep the gamedata files in sync with GitHub, as of right now the _default.cfg is regenerated only when the $lgsm_version that created it differs from the script's $version. The next step is to only regenerate the settings files when the gamedata itself is updated, which would be much more efficient.
---
## TODO
 * [ ] Look into better handling of parms, especially with the "-" and "+" ordering in Source.
 ** Perhaps put a "before" and "after" field in the parms, so we can do a little more complex ordering?
 * [ ] Clean up gamedata files for all engines/games.
 * [ ] When _default.cfg updates, read all other configs. Add in commented key/value/comment lines so that other configs have the keys and default values available.
 * [ ] Add dependency installation for games, simple array of packages needed for debian,ubuntu,redhat for each game.
 * [ ] Allow values to append or replace individual items, i.e. for dependencies layer on the needed packages from _default _engine and game data files.
 * [ ] Parser should read the value and identify variable names, and make sure that this key is declared after those variables that the value references.
 * [ ] Move insserver script (the POC common LGSM script) somewhere else to denote its new role