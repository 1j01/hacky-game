
module.exports =
class @GamepadController extends (require "./Controller.coffee")
	precision = 0.09
	constructor: (@gamepad)->
		super
		
		{axes} = @gamepad
		
		# assuming @gamepad.mapping is "standard"
		
		@moveX = axes[0]
		@move_y = axes[1]
		
		@lookX = axes[2]
		@lookY = axes[3]
		
		@jump = @gamepad.buttons[0].pressed # which button?
		@enterDoor = @gamepad.buttons[1].pressed # which button?
		
		@moveX = 0 if Math.abs(@moveX) < precision
		@lookX = 0 if Math.abs(@lookX) < precision
		@lookY = 0 if Math.abs(@lookY) < precision
		
		# look in the direction you're moving if you're not looking a different way
		# look_amount = Math.sqrt(@lookX*@lookY + @lookY*@lookY)
		# if look_amount < 0.2
		# 	@lookX = @moveX
		# 	@lookY = 0
