
# Room = require "./Room"

class @Ent
	constructor: (obj, room, world)->
		@x = 0
		@y = 0
		@w = @h = 1
		@vx = 0
		@vy = 0
		@applyUpdate obj
		@getRoom = -> room
		@getWorld = -> world
	
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
			if tile = @collisionAt new_x, @y, @vx, @vy
				if not @collisionAt new_x, @y - res*2, @vx, @vy
					@x = new_x
					# @vx -= res*2
					# @vy -= res
					@y -= res*2
				else
					if tile.value in [undefined, "■", "▩"]
						if @vx > 0
							@x = tile.x - 1
						else if @vx < 0
							@x = tile.x + 1
					@vx = 0
					break
			else
				@x = new_x
		if @collisionAt @x, @y
			console.warn "entered collision state"
		for new_y in [@y..@y+@vy] by (if @vy < 0 then -res else res)
			if tile = @collisionAt @x, new_y, @vx, @vy
				if not @collisionAt @x - res*2, new_y, @vx, @vy
					@x -= res*2
					# @vx -= res
					@y = new_y
					@vy *= 0.3
				else if not @collisionAt @x + res*2, new_y, @vx, @vy
					@x += res*2
					# @vx += res
					@y = new_y
					@vy *= 0.3
				else
					if tile.value in ["■", "▩"]
						if @vy > 0
							@y = tile.y - 1
						else if @vy < 0
							@y = tile.y + 1
					@vy = 0
					break
			else
				@y = new_y
	
	grounded: ->
		@vy >= 0 and @collisionAt @x, @y+0.1
	
	collisionAt: (at_x, at_y, vx=0, vy=0)->
		return {x: -1, y: at_y} if at_x < 0
		return {y: -1, x: at_x} if at_y < 0 # unless open air?
		room = @getRoom()
		return {x: room.width + 1, y: at_y} if at_x + 1 > room.width
		return {y: room.height + 1, x: at_x} if at_y + 1 > room.height
		for row, y in room.tiles
			for tile, x in row
				if tile.value is "◢"
					if at_x < x + 1 and at_x + 1 > x
						if at_y < y + 1 and at_y + 1 > y
							if (at_x - x + 1) + (at_y - y) > 0
								return tile
				else if tile.value is "◣"
					if at_x < x + 1 and at_x + 1 > x
						if at_y < y + 1 and at_y + 1 > y
							if (x - at_x + 1) + (at_y - y) > 0
								return tile
				else if tile.value is "▬"
					if at_x < x + 1 and at_x + 1 > x
						if at_y < y + 1 and at_y + 1 > y
							if (at_y - y) < 0.1 and vy >= 0
								return tile
				else if tile.value isnt " "
					# TODO: DRY up (these two lines are repeated a lot)
					if at_x < x + 1 and at_x + 1 > x
						if at_y < y + 1 and at_y + 1 > y
							return tile
	
	entsAt: (x, y, w, h)->
		room = @getRoom()
		ent for ent in room.ents when ent isnt @ and
			x < ent.x + w and x + w > ent.x and
			y < ent.y + h and y + h > ent.y
	
	draw: (ctx)->
		ctx.fillStyle = "white"
		# ctx.fillRect @x*16, @y*16, @w*16, @h*16
		ctx.beginPath()
		ctx.ellipse @x*16+16/2, @y*16+16/2, @w*16/2, @h*16/2, 0, Math.PI*2, no
		ctx.fill()

module?.exports = @Ent
