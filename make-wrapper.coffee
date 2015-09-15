
path = require "path"
{spawn} = require "child_process"
nexe = require "nexe"
zip = require "zip-folder"
winresourcer = require "nw-builder/node_modules/winresourcer"

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
							py = spawn "python.exe", ["pe.py", game_exe]
							py.on "error", (err)->
								throw err
							output = ""
							py.stderr.on "data", (data)->
								output += data
							py.stdout.on "data", (data)->
								output += data
							py.on "close", (exit_code)->
								if exit_code is 0
									console.log "Done"
								else
									console.error "Python exited with code #{exit_code}:\n#{output}"
