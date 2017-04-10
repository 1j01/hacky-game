
module.exports =
class @KeyboardController extends (require "./Controller.coffee")
	constructor: ->
		super
		@keys = {}
		@prev_keys = {}
		window.addEventListener "keydown", (e)=>
			@keys[e.keyCode] = on
		window.addEventListener "keyup", (e)=>
			delete @keys[e.keyCode]
	
	justPressed: (keyCode)=>
		@keys[keyCode]? and not @prev_keys[keyCode]?
	
	step: ->
		@moveX = Math.min(1, Math.max(-1, @keys[39]? - @keys[37]? + @keys[68]? - @keys[65]?))
		@jump = (@justPressed 38) or (@justPressed 87) or (@justPressed 32)
		@enterDoor = (@justPressed 40) or (@justPressed 83) or (@justPressed 13)
		@crouch = @keys[40]? or @keys[83]?
		
		@prev_keys = {}
		for k, v of @keys
			@prev_keys[k] = v
		
		@sendControlsToServer()
