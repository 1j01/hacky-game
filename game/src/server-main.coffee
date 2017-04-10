
ip_address = require("ip").address()

exports.init = ->
	global.wait_for_local_server_port = (callback)->
		wait_for_server_iid = setInterval ->
			if global.server
				clearInterval wait_for_server_iid
				global.server.getPort callback
			else
				console.log "waiting for global.server"
		, 50

	global.wait_for_local_server_address = (callback)->
		global.wait_for_local_server_port (port)->
			address = "tcp://#{ip_address}:#{port}"
			callback address

	log = (text) ->
		console.log "%cserver-main:%c #{text}", "font-size:1.5em;color:gray", "font-size:1.3em;font-family:sans-serif"

	start_sever = ->
		Server = require "./Server.coffee"
		log "start new server"
		global.server = new Server (err)->
			console.error err if err

	old_server = global.server
	if old_server
		log "close old server"
		global.server = null
		old_server.close start_sever
	else
		log "no old server"
		start_sever()
