
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
my_discovery_file_name = "#{process.pid}.json"
my_discovery_file_path = path.join dir, my_discovery_file_name

waiting_for_port = no
writeMyDiscoveryFile = ->
	return if waiting_for_port
	waiting_for_port = yes
	global.wait_for_local_server_port (port)->
		waiting_for_port = no
		data = {session_id, game_exe, pid: process.pid, port}
		json = JSON.stringify data
		fs.writeFile my_discovery_file_path, json, "utf8", (err)->
			console.error err if err

checkDiscoveryFile = (file_path, callback)->
	fs.readFile file_path, "utf8", (err, json)->
		if err?.code is "ENOENT"
			# The file may have been deleted after reading the directory
			return callback null, null
		return callback err if err
		# Sometimes the file comes up empty
		if json.length is 0
			fs.unlink file_path, (err)->
				console.error "Failed to clean up corrupted discovery file (file is empty)", err if err
			return callback null, null
		try
			data = JSON.parse json
		catch err
			fs.unlink file_path, (err)->
				console.error "Failed to clean up corrupted discovery file (invalid JSON, #{err})", err if err
			return callback null, null
		running data.pid, (err, is_running)->
			return callback err if err
			if is_running
				# TODO: prevent multiple instances from using the same executable
				# (but first, find a good way of running multiple instances in development)
				# if data.game_exe is game_exe
				# 	window.alert "This game is already running. Please start a new game.exe."
				# 	process.exit 1
				console.log "Found local client", data
				return callback null, data
			else
				fs.unlink file_path, (err)->
					console.error "Failed to clean up old discovery file (process #{data.pid} no longer running)", err if err
				return callback null, null

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

checkDiscoveryFiles = (callback)->
	fs.readdir dir, (err, fnames)->
		return callback err if err
		other_fnames = (fname for fname in fnames when fname isnt my_discovery_file_name)
		local_addresses = []
		checked = 0
		for fname in other_fnames
			do (fname)->
				file_path = path.join dir, fname
				checkDiscoveryFile file_path, (err, data)->
					# XXX: looks like it could callback multiple times
					# (but I think it shouldn't since `checked` wouldn't reach `other_fnames.length`
					# since its incremented after the return)
					# also, TODO: should probably more or less ignore these errors
					return callback err if err
					checked += 1
					if data?.port?
						local_addresses.push "tcp://localhost:#{data.port}"
					if checked is other_fnames.length
						callback null, local_addresses
		callback null, local_addresses if other_fnames.length is 0

module.exports = (callback)->
	writeMyDiscoveryFile()
	checkDiscoveryFiles (err, local_addresses)->
		addresses = local_addresses.concat(peer_addresses)
		callback null, addresses
	# TODO: callback right away when new peers found
	# not based on the local discovery interval
	# which btw could use fs watching (if not rely on it)

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
