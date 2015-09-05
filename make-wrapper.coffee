
nexe = require "nexe"
zip = require "zip-folder"

game_folder = "game"
zip_file = "game.zip"

console.log "Zip", game_folder, "to", zip_file

zip game_folder, zip_file, (err)->
	throw err if err
	console.log "Compile wrapper.js to game.exe with nexe"
	nexe.compile
		input: "./wrapper.js"
		output: "./game.exe"
		nodeVersion: "latest"
		framework: "nodejs"
		nodeTempDir: "temp"
		python: process.env.PYTHON or "python"
		flags: true
		resourceFiles: [zip_file]
		(err)->
			throw err if err
			console.log "Done"
