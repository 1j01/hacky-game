
fs = require "fs"
path = require "path"
crypto = require "crypto"
ip = require "ip"
running = require "is-running"
ssdp = require "super-ssdp"
# discover = require "nanodiscover"
# discover = require "./nanodiscover"
game_exe = require "./exe-file"
{App} = window.require "nw.gui"
dir = path.join App.dataPath, "discovery"
try fs.mkdirSync dir
catch err then throw err if err.code isnt "EEXIST"

session_id = crypto.randomBytes(20).toString('hex')
my_json_fname = "#{process.pid}.json"
my_json_file = path.join dir, my_json_fname

writeMyJSONFile = ->
	global.server.getPort (port)->
		data = {session_id, game_exe, pid: process.pid, port}
		json = JSON.stringify data
		fs.writeFile my_json_file, json, "utf8", (err)->
			console.error err if err

checkFile = (file, callback)->
	fs.readFile file, "utf8", (err, json)->
		return callback err if err
		try
			data = JSON.parse json
		catch err
			# Sometimes the file comes up empty
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
# setTimeout ->
# 	global.server.getPort (port)->
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
	fs.readdir dir, (err, fnames)->
		return callback err if err
		other_fnames = (fname for fname in fnames when fname isnt my_json_fname)
		local_addresses = []
		checked = 0
		for fname in other_fnames
			do (fname)->
				file = path.join dir, fname
				checkFile file, (err, data)->
					return callback err if err
					checked += 1
					if data?.port?
						local_addresses.push "tcp://localhost:#{data.port}"
					if checked is other_fnames.length
						callback null, local_addresses.concat peer_addresses
		callback null, peer_addresses if other_fnames.length is 0

# TODO: fork super-ssdp and add a stop/end/close method?
# global.peer?.stop?()

setTimeout ->
	global.server.getPort (port)->
		console.log "ssdp.createPeer",
			name: "HackyGame"
			url: "tcp://#{ip.address()}:#{port}"
		peer = global.peer = ssdp.createPeer 
			name: "HackyGame"
			url: "tcp://#{ip.address()}:#{port}"
		peer.start()
		peer.on "found", (address)->
			console.log "Found peer!", address
			unless address in peer_addresses
				peer_addresses.push address
		# TODO: "unfind" peers
, 200
