
fs = require "fs"
nexe = require "nexe"
zip = require "zip-folder"
base91 = require "base91"

build_folder = "./nw-builds/Hacky Game/win64/"
zip_file = "./nw-builds/game.zip"
console.log "Zip", build_folder, "to", zip_file

zip build_folder, zip_file, (err)->
	throw err if err
	console.log "Read zip file into memory"
	fs.readFile zip_file, (err, buffer)->
		throw err if err
		console.log "Encode zip file to base91"
		b91encoded = base91.encode buffer
		console.log "Write to a JS module"
		fs.writeFile "game.zip.js", """
			var base91 = require("./base91.js");
			var b91encoded = '#{b91encoded}';
			var buffer = base91.decode(b91encoded);
			module.exports = buffer;
		""", "utf-8", (err)->
			throw err if err
			
			console.log "Compile wrapper.js to game.exe with nexe"
			nexe.compile
				input: "./wrapper.js"
				output: "./game.exe"
				nodeVersion: "latest"
				framework: "nodejs"
				nodeTempDir: "temp"
				python: "python"
				flags: true
				# resourceFiles: [zip_file]
				# resourceFiles: ["./nw-builds/Hacky Game/win64/Hacky Game.exe"] # still too big
				resourceFiles: ["game.zip"]
				(err)->
					throw err if err
					console.log "Done"
