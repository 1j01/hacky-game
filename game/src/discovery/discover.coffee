
fs = require "fs"
path = require "path"
crypto = require "crypto"
ip = require "ip"
running = require "is-running"
ssdp = require "./super-ssdp"
# discover = require "./nanodiscover"
game_exe = require "../exe-file"
{App} = nw ? window.require "nw.gui"

dir = path.join App.dataPath, "discovery"
try fs.mkdirSync dir
catch err then throw err if err.code isnt "EEXIST"

session_id = crypto.randomBytes(20).toString('hex')
my_json_fname = "#{process.pid}.json"
my_json_file = path.join dir, my_json_fname

writeMyJSONFile = ->
	global.wait_for_local_server_port (port)->
		data = {session_id, game_exe, pid: process.pid, port}
		json = JSON.stringify data
		fs.writeFile my_json_file, json, "utf8", (err)->
			console.error err if err

checkFile = (file, callback)->
	fs.readFile file, "utf8", (err, json)->
		# TODO: no error if err.code is "ENOENT" (race condition)
		return callback err if err
		# Sometimes the file comes up empty
		if json.length is 0
			fs.unlink file, (err)->
				console.error "Trying to clean up empty discovery file", err if err
			callback null, null
			return
		try
			data = JSON.parse json
		catch err
			# If the file is corrupted, but not empty, we leave it in case it can be recovered.
			return callback err
		running data.pid, (err, is_running)->
			return callback err if err
			if is_running
				# TODO: prevent multiple instances from using the same executable
				# (but first, find a good way of running multiple instances in development)
				# if data.game_exe is game_exe
				# 	window.alert "This game is already running. Please start a new game.exe."
				# 	process.exit 1
				callback null, data
			else
				callback null, null
				fs.unlink file, (err)->
					console.error "Trying to clean up old discovery file", err if err

# global.announcer?.socket?.close?()
# global.browser?.socket?.close?()
# global.announcer?.close?()
# global.browser?.close?()

peer_addresses = []
# {name, version} = App.manifest
# ->
# 	wait_for_local_server_port (port)->
# 		global.announcer = discover.createAnnouncer name, version, "tcp://#{ip.address()}:#{port}"
# 		global.browser = browser = discover.createBrowser name, version
# 		# peer_addresses = browser.peers
# 
# 		browser.on "peerUp", (address, data)->
# 			peer_addresses.push data
# 			console.log "peerUp", address, peer_addresses
# 
# 		browser.on "peerDown", (address, data)->
# 			peer_addresses.splice (peer_addresses.indexOf data), 1 if data in peer_addresses
# 			console.log "peerDown", address, peer_addresses

module.exports = (callback)->
	writeMyJSONFile()
	# TODO: would be cleaner with a separate function like `checkFiles`
	fs.readdir dir, (err, fnames)->
		return callback err if err
		other_fnames = (fname for fname in fnames when fname isnt my_json_fname)
		local_addresses = []
		checked = 0
		for fname in other_fnames
			do (fname)->
				file = path.join dir, fname
				checkFile file, (err, data)->
					# XXX: looks like it could callback multiple times
					# (but I think it shouldn't since `checked` wouldn't reach `other_fnames.length`
					# since its incremented after the return)
					# also, TODO: should probably more or less ignore these errors
					return callback err if err
					checked += 1
					if data?.port?
						local_addresses.push "tcp://localhost:#{data.port}"
					if checked is other_fnames.length
						callback null, local_addresses.concat peer_addresses
		callback null, peer_addresses if other_fnames.length is 0

global.peer?.close()
global.peer = null

setTimeout ->
	global.wait_for_local_server_port (port)->
		options =
			name: App.manifest.name
			version: App.manifest.version
			url: "tcp://#{ip.address()}:#{port}"
		console.log "ssdp.createPeer", options
		peer = global.peer = ssdp.createPeer(options)
		peer.start()
		peer.on "found", (address)->
			console.log "Found peer!", address
			unless address in peer_addresses
				peer_addresses.push address
		# TODO: "unfind" peers
, 200
