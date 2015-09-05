
path = require "path"
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
			console.log "Done!"
			# console.log "Okay"
			# setTimeout ->
			# 	console.log "Update the icon"
			# 	winresourcer
			# 		operation: "Update"
			# 		exeFile: path.resolve game_exe
			# 		resourceType: "Icongroup"
			# 		resourceName: 1
			# 		# lang: 1033 # Required, except when updating or deleting
			# 		resourceFile: path.resolve win_ico
			# 		(err)->
			# 			throw err if err
			# 			console.log "Done"
			# , 500
