
# Each client hosts a server
# The client starts out connected to it's server
# If a connection fails with a remote server, you get booted back to the local server

World = require "./World"
net = require "net"

module.exports = class Server
	constructor: ->
		@world = new World
		
		clients = []
		@server = net.createServer (c)->
			console.log "a client connected", c
			clients.push c
			c.on "end", ->
				console.log "a client disconnected", c
				clients.splice (clients.indexOf c), 1
		@server.listen 3164
		
		setInterval =>
			for c in clients
				c.write JSON.stringify {text: ~~(Math.random()*500)}
		, 550
	
	close: ->
		@server.close()
		clearInterval @iid
