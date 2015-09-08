
Door = require "./Door"

class @Player extends (require "../Ent")
	constructor: ->
		super
		@entering = no
		@keys = {}
		@prev_keys = {}
		window.addEventListener "keydown", (e)=>
			@keys[e.keyCode] = on
		window.addEventListener "keyup", (e)=>
			delete @keys[e.keyCode]
	
	step: (t)->
		move = @keys[39]? - @keys[37]?
		jump = @keys[38]? and not @prev_keys[38]?
		enter = @keys[40]? and not @prev_keys[40]?
		crouch = @keys[40]?
		
		unless @entering
			@vx += 0.03 * move
			
			if jump and @grounded()
				@vy = -0.56
		
		@prev_keys = {}
		for k, v of @keys
			@prev_keys[k] = v
		
		door = ent for ent in @entsAt @x, @y, @w, @h when ent instanceof Door
		if door?
			if @entering
				if Math.abs(door.x - @x) < 0.1
					door.enter()
					@entering = no
				else
					@vx += 0.01 * Math.sign(door.x - @x)
			else if enter
				@entering = yes
		else
			@entering = no # in case you get pushed away from the door
		
		super

module?.exports = @Player
