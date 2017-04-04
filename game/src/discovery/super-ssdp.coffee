os = require('os')
events = require('events')
util = require('util')

ssdp = require('peer-ssdp')

SuperSSDP = (options)->
	@peer = ssdp.createPeer()
	@locations = []
	@service_location = options.url
	@service_name = options.name
	@service_version = options.version
	@SERVER = "#{os.type()}/#{os.release()} UPnP/1.1 #{@service_name}/#{@service_version}"
	@uuid = @service_name
	return

util.inherits SuperSSDP, events.EventEmitter

SuperSSDP::start = ->
	onReady = =>
		# console.log("[SSDP] searching for peers...")
		@peer.search ST: 'upnp:rootdevice'
		return

	@peer
	.on('search', (headers, address)=>
		# console.log("[SSDP] responding to search by: #{address.address}", headers)
		ST = headers.ST
		reply_headers =
			LOCATION: @service_location
			SERVER: @SERVER
			ST: "upnp:rootdevice"
			USN: "uuid:#{@uuid}::upnp:rootdevice"
			'BOOTID.UPNP.ORG': 1
		# console.log("[SSDP] responding with", reply_headers)
		@peer.reply reply_headers, address
		return
	).on('found', (headers, address)=>
		# console.log("[SSDP] found:", headers)
		if (
			@locations.indexOf(headers.LOCATION) < 0 and
			headers.LOCATION isnt @service_location and
			headers.SERVER.indexOf(@service_name) >= 0
		)
			@locations.push headers.LOCATION
			onReady()
			@emit 'found', headers.LOCATION
	).on('close', =>
		# console.log("[SSDP] closing")
		@emit 'close'
	).on('ready', ->
		onReady()
		setInterval onReady, 3000
	).start()

SuperSSDP::close = (callback)->
	@once('close', callback) if callback
	@peer.close()

exports.createPeer = (options)->
	new SuperSSDP(options)
