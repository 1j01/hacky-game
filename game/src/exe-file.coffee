
{App} = nw ? window.require "nw.gui"
[game_exe] = App.argv

if game_exe is "--enable-logging"
	# running from npm start
	game_exe = "../game.exe"
# else
	# running from nexe

module.exports = game_exe
