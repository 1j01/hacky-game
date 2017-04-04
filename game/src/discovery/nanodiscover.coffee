
{EventEmitter} = require("events")
dgram = require "dgram"
ip = require "ip"

port = 59544
interval = 400
timeout = interval * 2

class DiscoverAnnouncer
	constructor: (name, version, data)->
		json = JSON.stringify data
		@message = new Buffer [name, version, json].join "\0"
		@socket = dgram.createSocket "udp4"
		@socket.bind port + 1, =>
			@socket.setBroadcast yes
			@socket.on "error", -> # Ignore errors
			@interval = setInterval =>
				@socket.send @message, 0, @message.length, port, "255.255.255.255"
			, interval
	close: ->
		@socket.close()
		clearInterval @interval

class DiscoverBrowser extends EventEmitter
	constructor: (name, version)->
		@peerAddresses = []
		@peerData = []
		@peerTimeouts = []
		@timeout = (address)=>
			pos = @peerAddresses.indexOf address
			remote_data = @peerData[pos]
			unless pos is -1
				@peerTimeouts.splice pos, 1
				@peerAddresses.splice pos, 1
				@peerData.splice pos, 1
			@emit "peerDown", address
		@socket = dgram.createSocket "udp4"
		@socket.bind port
		@socket.on "message", (message, remote)=>
			[remote_name, remote_version, remote_json] = message.toString().split "\0"
			if remote_name is name and remote_version is version
				return if remote.address is ip.address()
				remote_data = if remote_json then try JSON.parse remote_json
				pos = @peerAddresses.indexOf remote.address
				if pos >= 0
					clearTimeout @peerTimeouts[pos]
					@peerTimeouts[pos] = setTimeout @timeout, timeout, remote.address
				else
					@peerAddresses.push remote.address
					@peerData.push remote_data
					@peerTimeouts.push setTimeout @timeout, timeout, remote.address
					@emit "peerUp", remote.address, remote_data
	close: ->
		@socket.close()

module.exports =
	createBrowser: (name, version="latest")->
		new DiscoverBrowser name, version
	createAnnouncer: (name, version="latest", data)->
		new DiscoverAnnouncer name, version, data
