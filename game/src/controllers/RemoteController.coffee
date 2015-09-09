
# Maybe "RemoteController" isn't the best name
# This is the Controller used on the server

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
