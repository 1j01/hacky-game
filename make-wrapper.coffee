
path = require "path"
nexe = require "nexe"
zip = require "zip-folder"
winresourcer =
	if (try require.resolve "winresourcer")
		require "winresourcer"
	else
		require "nw-builder/node_modules/winresourcer"
change_exe_subsystem = require './subsystem'

game_folder = "game"
game_exe = "game.exe"
zip_file = "game.zip"
win_ico = "#{game_folder}/images/game.ico"

console.log "Zip", game_folder, "to", zip_file

zip game_folder, zip_file, (err)->
	throw err if err
	console.log "Compile ./wrapper.js to #{game_exe} with nexe"
	nexe.compile
		input: "./wrapper.js"
		output: game_exe
		nodeVersion: "latest"
		framework: "nodejs"
		nodeTempDir: "temp"
		python: process.env.PYTHON or "python"
		flags: true
		resourceFiles: [zip_file]
		(err)->
			throw err if err
			console.log "Delete the Node.js icon from #{game_exe}"
			winresourcer
				operation: "Delete"
				exeFile: path.resolve game_exe
				resourceFile: path.resolve win_ico
				resourceType: "Icon"
				resourceName: 1
				lang: 1033
				(err)->
					throw err if err
					console.log "Add the new icon to #{game_exe}"
					winresourcer
						operation: "Add"
						exeFile: path.resolve game_exe
						resourceFile: path.resolve win_ico
						resourceType: "Icon"
						resourceName: 1
						lang: 1033
						(err)->
							throw err if err
							console.log "Make the exe into a GUI app so it doesn't show the console"
							change_exe_subsystem game_exe, "GUI"
							console.log "Done!"
