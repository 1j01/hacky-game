
# console.log "GAME?"

fs = require "fs"
{spawn} = require "child_process"
nexeres = require "nexeres"
path = require "path-extra"

datadir = path.datadir "hacky-game"
zip_file = path.join datadir, "game.zip"
nwjs_dl_folder = path.join datadir, "nw.js"
nwjs_exe = path.join nwjs_dl_folder, "nw.exe"
nwjs_url = "http://dl.nwjs.io/v0.12.3/nwjs-v0.12.3-win-x64.zip"
try fs.mkdirSync datadir
try fs.mkdirSync nwjs_dl_folder

zip = nexeres.get "game.zip"

# console.log "Using locations", {zip_file, nwjs_dl_folder, nwjs_url}

# require("repl").start useGlobal: yes

run = ->
	# console.log "Launching game"
	proc = spawn nwjs_exe, [zip_file, process.execPath], detached: yes, stdio: ['ignore', 'ignore', 'ignore']
	# process.exit()
	proc.unref()
	# proc.on 'open', -> # this is not an event that exists btw
	# 	console.log "Have good times of having fun, thank you."
	# 	process.exit()
	# proc.stdout.on 'data', (data)->
	# 	console.log 'stdout: ' + data
	# 
	# proc.stderr.on 'data', (data)->
	# 	console.log 'stderr: ' + data
	# 
	# proc.on 'close', (code)->
	# 	console.log 'child process (nw) exited with code ' + code

fs.writeFile zip_file, zip, (err)->
	throw err if err
	# console.log "Extracted zip from this executable"
	
	# console.log "Check existance of #{nwjs_exe}"
	if fs.existsSync nwjs_exe
		# console.log "File exists, run it!"
		run()
	else
		# console.log "File isn't there (yet), time to download nw.js"
		downloader = require "nw-builder/lib/downloader.js"
		downloader.downloadAndUnpack nwjs_dl_folder, nwjs_url
		.then ->
			# console.log "Unpacked #{nwjs_dl_folder} from #{nwjs_url}"
			run()
		.catch (err)->
			console.error "Failed to download and unpack #{temp_folder}/nw.zip from #{nwjs_url}: #{err}"

