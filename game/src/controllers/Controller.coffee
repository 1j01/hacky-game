
module.exports =
class @Controller
	constructor: ->
		@moveX = 0
		@jump = no
		@enterDoor = no
		@crouch = no
	
	setPlayer: (player)->
		@playerID = player.id
		@world = player.world
	
	toJSON: ->
		{@moveX, @jump, @enterDoor, @crouch, @playerID}
	
	sendControlsToServer: ->
		if @world.socket
			@world.socket.sendMessage {controls: @}
	
	step: ->
