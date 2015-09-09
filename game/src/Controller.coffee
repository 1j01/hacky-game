
module.exports =
class @Controller
	constructor: (player, {@onClientSide})->
		@moveX = 0
		@jump = no
		@enterDoor = no
		@crouch = no
		@playerID = player.id
	
	toJSON: ->
		{@moveX, @jump, @enterDoor, @crouch, @playerID}
	
	sendControlsToServer: ->
		if @onClientSide
			window.socket.write "#{JSON.stringify {controls: @}}\n"
	
	step: ->
		# console.error "#{@constructor.name} does not define a step method."
