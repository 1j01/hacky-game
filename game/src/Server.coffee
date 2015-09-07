
# Each client hosts a server
# The client starts out connected to it's server
# If a connection fails with a remote server, you get booted back to the local server

# console = require("nw.gui").Window.get().window.console
# log = (args...)->
# 	require("nw.gui").Window.get().window.console.log args...

# log = (args...)->
# 	process.stdout.write "ASSHOLE" + args[0] + args[1]

World = require "./World"

module.exports = class Server
	constructor: ->
		window.addEventListener "beforeunload", -> @close()
		
		@world = new World
		
		# io = (global.require "socket.io")()
		@io = (require "socket.io")()
		@io.on "connection", (socket)->
			console.log "client connected to server", socket
		@io.listen 3164, (err)->
			console.log "io.listen cb", arguments
		
		i = 0
		@iid = setInterval =>
			console.log "server emit room hey", i
			@io.emit "room", i++ # @world.rooms[0]
		, 550
	
	close: ->
		@io.close()
		clearInterval @iid
