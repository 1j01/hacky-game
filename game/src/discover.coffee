
# TODO: SSDP (LAN discovery)

fs = require "fs"
path = require "path"
crypto = require "crypto"
{App} = window.require "nw.gui"
running = require "is-running"
game_exe = require "./exe-file"
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

module.exports = (callback)->
	writeMyJSONFile()
	fs.readdir dir, (err, fnames)->
		return callback err if err
		other_fnames = (fname for fname in fnames when fname isnt my_json_fname)
		ports = []
		for fname in other_fnames
			do (fname)->
				file = path.join dir, fname
				checkFile file, (err, data)->
					return callback err if err
					ports.push data?.port
					if ports.length is other_fnames.length
						callback null, ports.filter (v)-> v?
		callback null, [] if other_fnames.length is 0
