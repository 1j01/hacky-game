
# Each client hosts a server
# The client starts out connected to it's server
# If a connection fails with a remote server, you get booted back to the local server

World = require "./World"
savegame = require "./savegame"
net = require "net"

module.exports = class Server
	constructor: ->
		@world = new World
		
		clients = []
		
		send_all_data = =>
			for c in clients
				for id, room of @world.rooms
					c.write "#{JSON.stringify {room}}\n"
		
		send_ents = =>
			for c in clients
				for id, room of @world.rooms
					c.write "#{JSON.stringify {room: room.ents}}\n"
		
		@server = net.createServer (c)->
			console.debug "a client connected", c
			clients.push c
			c.on "end", ->
				console.debug "a client disconnected", c
				clients.splice (clients.indexOf c), 1
			send_all_data()
		
		@server.listen 3164
		
		@iid = setInterval =>
			if global.window?.CRASHED
				console.log "Server: stopping, since the client crashed"
				clearInterval @iid
				return
			# console.log "Server: stepping, #{clients.length} client(s) connected"
			@world.step()
			send_ents()
		, 1000 / 30
		
		@slower_iid = setInterval =>
			send_all_data()
		, 500
		
		@world.applyRoomUpdate
			id: "first room ever"
			tiles: [
				[0,0,0,0,0,0,2]
				[0,0,0,0,0,0,1]
				[0,0,0,0,0,1,2]
				[1,1,1,1,1,2,2]
			]
			ents: [
				{x: 1, y: 1}
			]
		
		# setInterval =>
		# 	# TODO: only save if there has been activity
		# 	savegame.save {}, (err)->
		# , 500
	
	close: ->
		@server.close()
		clearInterval @iid
		clearInterval @slower_iid
