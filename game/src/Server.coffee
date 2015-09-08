
# Each client hosts a server
# The client starts out connected to it's server
# If a connection fails with a remote server, you get booted back to the local server

net = require "net"
hack = require "./savegame"
World = require "./World"

loaded = no

getFreePort = do ->
	port = 45035
	(cb)->
		port += 1
		server = net.createServer()
		server.listen port, ->
			server.once 'close', -> cb port
			server.close()
		server.on 'error', (err)->
			getPort cb

module.exports =
class Server
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
		
		@server = net.createServer (c)=>
			console.debug "a client connected", c
			clients.push c
			c.on "end", ->
				console.debug "a client disconnected", c
				clients.splice (clients.indexOf c), 1
			send_all_data()
		
		getFreePort (port)=>
			@server.listen port
			@port = port
			
		@iid = setInterval =>
			if global.window?.CRASHED
				console.log "Server: stopping, since the client crashed"
				@close()
				return
			@world.step()
			send_ents()
		, 1000 / 60
		# TODO: maybe step the server from the client?
		
		@slower_iid = setInterval =>
			send_all_data()
			# TODO: save
			# TODO: only save if there has been activity
			# if loaded
			# 	hack.save @world, (err)=>
			# 		console.error err if err
		, 500
		
		@world.applyRoomUpdate
			id: "the second room"
			tiles: """
				              ■▩
				              ■▩
				▬■■◤          ■▩
				              ■▩
				              ■▩
				▬    ◢■■■■  ■■■▩
				    ◢■▩▩▩■  ■▩▩▩
				■■■■■■▩▩▩■  ■▩▩▩
			""" # ■▩▬◢◤◥◣◫
			ents: [
				{id: 2, x: 2, y: 1, type: "Door", to: "the third room"}
				{id: 0, x: 1, y: 1, type: "Enemy"}
				{id: "p#{Math.random()}", x: 8, y: 3, type: "Player"}
			]
		
		@world.applyRoomUpdate
			id: "the third room"
			tiles: """
				■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                                                                         ■
				■                               ◣                                         ■
				■                               ◥■■■■■◣                                   ■
				■                                     ◥             ◥■■■■■◤               ■
				■                                                                         ■
				■                                                                         ■
				■                                         ◥■■■■■                          ■
				■                                              ■                          ■
				■                                              ■▬▬▬▬■■■■■◤                ■
				■                 ◢■■■■■■◣                     ■    ■                     ■
				■                ◢■◤   ◥■■                     ■    ■                     ■
				■               ◢■■◣    ◥■                     ◥▬▬▬▬◤                     ■
				■              ◢■◤ ◥◣    ■                                                ■
				■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
			""" # ■▩▬◢◤◥◣◫
			ents: [
				{id: 0, x: 30, y: 17, type: "Door", to: "the second room"}
				# {id: 0, x: 20, y: 5, type: "Enemy"} hahaha
				{id: 3, x: 20, y: 5, type: "Enemy"}
				{id: 4, x: 10, y: 5, type: "Enemy"}
				{id: 5, x: 71, y: 17, type: "Door", to: "the fourth room"}
				{id: 6, x: 22, y: 17, type: "HiddenDoor", from: "the fourth room", to: "the second room"}
			]
		
		@world.applyRoomUpdate
			id: "the fourth room"
			tiles: """
				■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
				■           ■                                                             ■
				■           ■                                                             ■
				■           ■                                                             ■
				■           ■                                                             ■
				■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
			""" # ■▩▬◢◤◥◣◫
			ents: [
				# {id: 0, x: 3, y: 3, type: "Door", from: "the third room"}
				# {id: 1, x: 71, y: 3, type: "Door", to: "the third room"}
				{id: 0, x: 15, y: 3, type: "Door", to: "the third room"}
				{id: 1, x: 71, y: 3, type: "Door", to: "the third room", from: "the third room"} # FIXME: this door also goes to the thing
			]
		
		# hack.load (err, world)=>
		# 	if err
		# 		console.error err # TODO: visible error
		# 	else if world
		# 		console.log "Game loaded", world
		# 		@world.applyUpdate world
		# 		loaded = yes
		# 	else
		# 		console.log "Start new game"
		# 		loaded = yes
	
	getPort: (callback)->
		iid = setInterval =>
			if @port
				clearInterval iid
				callback @port
		, 50
	
	close: ->
		@server.close()
		clearInterval @iid
		clearInterval @slower_iid
