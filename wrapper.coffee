
console.log "GAME?"

fs = require "fs"
{spawn} = require "child_process"
nexeres = require "nexeres"
path = require "path-extra"

datadir = path.datadir "hacky-game"
zip_file = path.join datadir, "game.zip"
nwjs_dl_folder = path.join datadir, "nw.js"
nwjs_url = "http://dl.nwjs.io/v0.12.3/nwjs-v0.12.3-win-x64.zip"
try fs.mkdirSync datadir
try fs.mkdirSync nwjs_dl_folder

zip = nexeres.get "game.zip"

console.log "Using locations", {zip_file, nwjs_dl_folder, nwjs_url}

fs.writeFile zip_file, zip, (err)->
	throw err if err
	console.log "Extracted zip from this executable"
	
	downloader = require "nw-builder/lib/downloader.js"
	downloader.downloadAndUnpack nwjs_dl_folder, nwjs_url
	.then ->
		console.log "Unpacked #{nwjs_dl_folder} from #{nwjs_url}"
		console.log "Launching game"
		nw = path.join nwjs_dl_folder, "nw.exe"
		proc = spawn nw, [zip_file]
		proc.stdout.on 'data', (data)->
			console.log 'stdout: ' + data
	
		proc.stderr.on 'data', (data)->
			console.log 'stderr: ' + data
	
		proc.on 'close', (code)->
			console.log 'child process (nw) exited with code ' + code
		
	.catch (err)->
		console.log "Failed to download and unpack #{temp_folder}/nw.zip from #{nwjs_url}: #{err}"

