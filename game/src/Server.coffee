
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
					c.write "#{JSON.stringify {room: {id: room.id, ents: room.ents}}}\n"
		
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
				@close()
				return
			# console.log "Server: stepping, #{clients.length} client(s) connected"
			@world.step()
			send_ents()
		, 1000 / 60
		# TODO: maybe step the server from the client?
		
		@slower_iid = setInterval =>
			send_all_data()
			# TODO: save
			# TODO: only save if there has been activity
			# savegame.save world, (err)->
		, 500
		
		@world.applyRoomUpdate
			id: "the second room"
			tiles: """
				              ■▩
				              ■▩
				▬■■           ■▩
				              ■▩
				              ■▩
				▬    ◢■■■■  ■■■▩
				    ◢■▩▩▩■  ■▩▩▩
				■■■■■■▩▩▩■  ■▩▩▩
			""" # ■▩▬◢◣◫
			ents: [
				{id: 2, x: 2, y: 1, type: "Door", to: "the third room"}
				{id: 0, x: 1, y: 1, type: "Enemy"}
				{id: 1, x: 8, y: 3, type: "Player"}
			]
		
		@world.applyRoomUpdate
			id: "the third room"
			tiles: """
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                 ■■■■■                                   ■
				■                                                  ■■■■■                  ■
				■                                                                         ■
				■                                                                         ■
				■                                          ■■■■■                          ■
				■                                                                         ■
				■                                                   ■■■■■                 ■
				■                 ◢■■■■■■◣                                                ■
				■                ◢■     ■■                                                ■
				■               ◢■ ◣    ◣■                                                ■
				■              ◢■ ◣ ◣    ■◣                                               ■
				■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
			""" # ■▩▬◢◣◫
			ents: [
				{id: 0, x: 30, y: 10, type: "Door", to: "the second room"}
				# {id: 0, x: 20, y: 5, type: "Enemy"} hahaha
				{id: 3, x: 20, y: 5, type: "Enemy"}
				{id: 4, x: 10, y: 5, type: "Enemy"}
			]
		
		# TODO: load game from exe
		# load_game (err, savegame)->
		# 	if err
		# 		console.error err # TODO: visible error
		# 	else if savegame
		# 		console.log "Game loaded", savegame
		# 	else
		# 		console.log "Start new game"
	
	close: ->
		@server.close()
		clearInterval @iid
		clearInterval @slower_iid
