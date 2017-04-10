
exports.init = ->
	Server = require "./Server.coffee"
	console.log "Starting server"
	global.server = new Server (err)->
		console.error err if err
