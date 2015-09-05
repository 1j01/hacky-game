
console.log "Hi! So let's see, can we access some resources?"

# fs = require "fs"
# zip = require "./game.zip.js"
# fs.writeFile "game-extracted-but-of-course-still-in-a-still.zip", zip, (err)->
# 	throw err if err
# 	console.log "Sucsseses"

# nexeres = require "nexeres"
# console.log "game.zip:"
# # console.log nexeres.get "game.zip"
# console.log process.cwd()
# console.log __filename
# console.log __filepath

# zip = require "./game.zip.js"

fs = require "fs"
{spawn} = require "child_process"
nexeres = require "nexeres"
# nwbuild = require "nw-builder"
DecompressZip = require "nw-builder/node_modules/decompress-zip"
path = require "path-extra"
# console.log nexeres.get "Hacky Game.exe"
console.log "game.zip:"
console.log zip = nexeres.get "game.zip"
datadir = path.datadir "hacky-game"

# extract_game_to_path = "this-is-it"

# zip_file = "game-extracted-but-of-course-still-in-a-still.zip"

zip_file = path.join datadir, "game.zip"
nwjs_dl_folder = path.join datadir, "nw.js"
nwjs_url = "http://dl.nwjs.io/v0.12.3/nwjs-v0.12.3-win-x64.zip"
try fs.mkdirSync datadir
try fs.mkdirSync nwjs_dl_folder

console.log "Using locations", {zip_file, nwjs_dl_folder, nwjs_url}

fs.writeFile zip_file, zip, (err)->
	throw err if err
	console.log "Extracted zip from this executable"
	# console.log "Decompressing data chambers..."
	# 
	# unzipper = new DecompressZip zip_file
	# 
	# unzipper.on 'error', (err)->
	# 	console.error "ERROR extracting zip file"
	# 
	# unzipper.on 'extract', (log)->
	# 	console.log 'Finished extracting'
	# 	nw = (require "nw").findpath()
	# 	proc = spawn nw, [extract_game_to_path]
	# 	proc.stdout.on 'data', (data)->
	# 		console.log 'stdout: ' + data
	# 
	# 	proc.stderr.on 'data', (data)->
	# 		console.log 'stderr: ' + data
	# 
	# 	proc.on 'close', (code)->
	# 		console.log 'child process exited with code ' + code
	# 
	# 
	# unzipper.on 'progress', (fileIndex, fileCount)->
	# 	console.log "Extracted file #{fileIndex + 1} of #{fileCount}"
	# 
	# unzipper.extract
	# 	path: extract_game_to_path
	# 	filter: (file)-> file.type isnt "SymbolicLink"
	
	# try fs.mkdirSync temp_folder = "nw.js"
	
	downloader = require "nw-builder/lib/downloader.js"
	# downloader = require "./nw-downloader.js"
	downloader.downloadAndUnpack nwjs_dl_folder, nwjs_url
	.then ->
		console.log "Unpacked #{nwjs_dl_folder} from #{nwjs_url}"
		nw = path.join nwjs_dl_folder, "nw.exe"
		# proc = spawn nw, [extract_game_to_path]
		proc = spawn nw, [zip_file]
		proc.stdout.on 'data', (data)->
			console.log 'stdout: ' + data
	
		proc.stderr.on 'data', (data)->
			console.log 'stderr: ' + data
	
		proc.on 'close', (code)->
			console.log 'child process exited with code ' + code
		
	.catch (err)->
		console.log "Failed to download and unpack #{temp_folder}/nw.zip from #{nwjs_url}: #{err}"

