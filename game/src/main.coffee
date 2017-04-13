
require "coffee-script/register"
# NOTE: requires relative to page
Client = require "./src/Client"
Server = require "./src/Server"

window.addEventListener "unload", =>
	global.server?.close()
	global.peer?.close()
	global.client?.closeConnections()

console.log "Starting server"
global.server = new Server (err)->
	console.error err if err

global.server.getAddress (address)->
	console.log "Starting client"
	global.client = new Client
	global.client.start(address)
