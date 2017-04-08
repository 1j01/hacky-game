
# This is the Controller used on the server
# It receives remote controls from clients

# Maybe "NetworkedController" or "ServersideController" would be a better name
# I guess "ServersideController" since every `Controller` is somewhat networked with `Controller::sendControlsToServer`

module.exports =
class @RemoteController extends (require "../Controller.coffee")
	constructor: ->
		super
		@willJump = no
		@willEnterDoor = no
	
	applyUpdate: (controls)->
		for k, v of controls
			switch k
				when "jump" then @willJump or= v
				when "enterDoor" then @willEnterDoor or= v
				else @[k] = v
	
	step: ->
		@jump = @willJump
		@enterDoor = @willEnterDoor
		@willJump = no
		@willEnterDoor = no
