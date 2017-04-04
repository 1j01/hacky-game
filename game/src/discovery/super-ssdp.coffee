os = require('os')
events = require('events')
util = require('util')

ssdp = require('peer-ssdp')

SuperSSDP = (options)->
	@peer = ssdp.createPeer()
	@locations = []
	# @disc = []
	@service_location = options.url
	@service_name = options.name
	@SERVER = "#{os.type()}/#{os.release()} UPnP/1.1 #{@service_name}/0.0.1"
	@uuid = @service_name
	return

util.inherits SuperSSDP, events.EventEmitter

SuperSSDP::start = ->
	onReady = =>
		#console.log('sending info request to the wild')
		@peer.search ST: 'upnp:rootdevice'
		return

	@peer
	# .on('notify', (headers, address)=>
	.on('search', (headers, address)=>
		#console.log('search>>')
		#console.log('telling about me to:')
		#console.log(address.address)
		#console.log(headers)
		ST = headers.ST
		headers =
			LOCATION: @service_location
			SERVER: @SERVER
			ST: "upnp:rootdevice"
			USN: "uuid:#{@uuid}::upnp:rootdevice"
			'BOOTID.UPNP.ORG': 1
		#console.log('search>>answer<<')
		#console.log(headers)
		@peer.reply headers, address
		return
	).on('found', (headers, address)=>
		#console.log('found>>')
		#console.log(headers)
		if (
			@locations.indexOf(headers.LOCATION) < 0 and
			headers.LOCATION isnt @service_location and
			headers.SERVER.indexOf(@service_name) >= 0
		)
			@locations.push headers.LOCATION
			onReady()
			@emit 'found', headers.LOCATION
	).on('close', =>
		# @disc.splice address.address, 1
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
