
{App} = nw ? window.require "nw.gui"

[game_exe] = App.argv
running_from_npm_start = game_exe is "--enable-logging"

if running_from_npm_start
	game_exe = "../game.exe"

module.exports = game_exe
