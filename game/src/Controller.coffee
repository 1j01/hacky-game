
module.exports =
class @Controller
	constructor: (player, @world)->
		@moveX = 0
		@jump = no
		@enterDoor = no
		@crouch = no
		@playerID = player.id
	
	toJSON: ->
		{@moveX, @jump, @enterDoor, @crouch, @playerID}
	
	sendControlsToServer: ->
		# FIXME: write after end will crash client
		if @world.socket
			@world.socket.sendMessage {controls: @}
	
	step: ->
