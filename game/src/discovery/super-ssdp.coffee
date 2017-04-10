os = require('os')
{EventEmitter} = require('events')
util = require('util')

ssdp = require('peer-ssdp')
uuid_v4 = require('uuid/v4')

SuperSSDP = (options)->
	@peer = ssdp.createPeer()
	@locations = []
	@service_name = options.name
	@service_version = options.version ? "0.0.0"
	# @extra_headers = options.headers ? {}
	@uuid = options.uuid ? uuid_v4()
	@LOCATION = options.url
	@SERVER = "#{os.type()}/#{os.release()} UPnP/1.1 #{@service_name}/#{@service_version}"
	# should we use "urn:schemas-upnp-org:service:a-unique-name-assigned-by-a-UPnP-forum-working-committee:1"?
	# it would be heterological and amusingly recalcitrant
	@ST = options.serviceType ? "upnp:rootdevice"
	@USN = "uuid:#{@uuid}"
	return

util.inherits SuperSSDP, EventEmitter

SuperSSDP::start = ->
	search = =>
		# console.log("[SSDP] searching for peers...")
		@peer.search ST: @ST
		return

	@peer
	.on 'search', (headers, address)=>
		# console.log("[SSDP] responding to search by: #{address.address}", headers)
		ST = headers.ST
		reply_headers =
			LOCATION: @LOCATION
			SERVER: @SERVER
			ST: @ST
			USN: @USN
		# for k, v of @extra_headers
		# 	reply_headers[k] = v
		# console.log("[SSDP] responding with", reply_headers)
		@peer.reply reply_headers, address
		return
	.on 'found', (headers, address)=>
		# console.log("[SSDP] found:", headers)
		if (
			# @locations.indexOf(headers.LOCATION) < 0 and
			headers.LOCATION isnt @LOCATION and
			# should the above be `headers.USN isnt @USN and`?
			headers.SERVER.indexOf(@service_name) >= 0
		)
			# @locations.push headers.LOCATION
			# search()
			@emit 'found', headers.LOCATION
	.on 'notify', (headers, address)=>
		# console.log("[SSDP] recieved notify:", headers)
		# NOTE: timeout to theoretically thwart network congestion
		setTimeout search, Math.random() * 100
	.on 'close', =>
		# console.log("[SSDP] closed")
		@emit 'close'
	.on 'ready', =>
		console.log("[SSDP] broadcasting")
		search()
		@peer.alive({})
		@interval = setInterval search, 3000
	.start()

SuperSSDP::close = (callback)->
	clearInterval @interval
	@once('close', callback) if callback
	@peer.close()

exports.createPeer = (options)->
	new SuperSSDP(options)
