
module.exports =
class @Controller
	constructor: ->
		@moveX = 0
		@jump = no
		@enterDoor = no
		@crouch = no
	
	setPlayer: (player)->
		@playerID = player.id
		@socket = player.world.socket
	
	toJSON: ->
		{@moveX, @jump, @enterDoor, @crouch, @playerID}
	
	sendControlsToServer: ->
		@socket?.sendMessage {controls: @}
	
	step: ->
