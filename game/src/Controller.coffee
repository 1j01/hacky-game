
module.exports =
class @Controller
	constructor: ->
		@moveX = 0
		@jump = no
		@enterDoor = no
		@crouch = no
	sendControlsToServer: ->
		# if we're on the client
		if self?.socket
			self.socket.write "#{JSON.stringify {controls: @}}\n"
