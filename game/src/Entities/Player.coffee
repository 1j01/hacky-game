
class @Player extends (require "../Ent")
	constructor: ->
		super
		@keys = {}
		@prev_keys = {}
		window.addEventListener "keydown", (e)=>
			@keys[e.keyCode] = on
		window.addEventListener "keyup", (e)=>
			delete @keys[e.keyCode]

	step: (t)->
		move = @keys[39]? - @keys[37]?
		jump = @keys[38]? and not @prev_keys[38]?
		
		@vx += 0.03 * move
		
		if jump and @grounded()
			@vy = -0.56
		
		@prev_keys = {}
		for k, v of @keys
			@prev_keys[k] = v
		
		super

module?.exports = @Player
