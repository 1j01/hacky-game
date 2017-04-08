
path = require "path"
{App} = nw ? window.require "nw.gui"

[arg] = App.argv
running_from_npm_start = arg is "--enable-logging"

# Return the path to the executable binary
module.exports =
	if running_from_npm_start
		path.resolve("../game.exe")
	else
		arg
