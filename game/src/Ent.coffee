
# Room = require "./Room"

class @Ent
	constructor: (obj, room)->
		@x = 0
		@y = 0
		@w = @h = 1
		@vx = 0
		@vy = 0
		@applyUpdate obj
		@getRoom = -> room
	
	# toJSON: ->
	# 	o = {}
	# 	console.log "Room =", Room
	# 	for k, v of @ when (typeof v isnt "function") and not (v instanceof Room)
	# 		o[k] = v
	# 	o
	
	applyUpdate: (obj)->
		for k, v of obj
			@[k] = v
	
	step: (t)->
		@vx *= 0.9
		@vy += 0.04
		res = 0.01
		for new_x in [@x..@x+@vx] by (if @vx < 0 then -res else res)
			if tile = @collision new_x, @y
				if not @collision new_x, @y - res*2
					@x = new_x
					# @vx -= res*2
					# @vy -= res
					@y -= res*2
				else
					if @vx > 0
						@x = tile.x - 1
					else if @vx < 0
						@x = tile.x + 1
					@vx = 0
					break
			else
				@x = new_x
		if @collision @x, @y
			console.warn "entered collision state"
		for new_y in [@y..@y+@vy] by (if @vy < 0 then -res else res)
			if tile = @collision @x, new_y
				if not @collision @x - res*2, new_y
					@x -= res*2
					# @vx -= res
					@y = new_y
					@vy *= 0.3
				else if not @collision @x + res*2, new_y
					@x += res*2
					# @vx += res
					@y = new_y
					@vy *= 0.3
				else
					# if @vy > 0
					# 	@y = tile.y - 1
					# else if @vy < 0
					# 	@y = tile.y + 1
					@vy = 0
					break
			else
				@y = new_y
	
	collision: (at_x, at_y)->
		return {x: -1, y: at_y} if at_x < 0
		return {y: -1, x: at_x} if at_y < 0
		room = @getRoom()
		return {x: room.width + 1, y: at_y} if at_x + 1 > room.width
		return {y: room.height + 1, x: at_x} if at_y + 1 > room.height
		for row, y in room.tiles
			for tile, x in row
				if tile.value is 3
					if at_x < x + 1 and at_x + 1 > x
						if at_y < y + 1 and at_y + 1 > y
							if (at_x - x + 1) + (at_y - y) > 0
								return tile
				else if tile.value > 0
					if at_x < x + 1 and at_x + 1 > x
						if at_y < y + 1 and at_y + 1 > y
							return tile
	
	draw: (ctx)->
		ctx.fillStyle = "white"
		# ctx.fillRect @x*16, @y*16, @w*16, @h*16
		ctx.beginPath()
		ctx.ellipse @x*16+16/2, @y*16+16/2, @w*16/2, @h*16/2, 0, Math.PI*2, no
		ctx.fill()

module?.exports = @Ent
