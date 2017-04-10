
ssdp = require "./super-ssdp"
{App} = nw

module.exports = (callback)->
	global.wait_for_local_server_address (address)->
		options =
			name: App.manifest.name
			version: App.manifest.version
			url: address
			serviceType: "urn:1j01-github-io:service:game-server:1"
		peer = global.peer = ssdp.createPeer(options)
		peer.start()
		callback(peer)
