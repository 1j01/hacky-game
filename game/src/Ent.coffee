
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
		@x += @vx *= 0.9
		@y += @vy += 0.05
		# TODO: collision
		if @y > 50
			@y = 50
			@vy = -Math.abs(@vy) * 0.5
		for row, y in @getRoom().tiles
			for tile, x in row
				if tile.value > 0
					if @x < x + 1 and @x + 1 > x
						if @y < y + 1 and @y + 1 > y
							@y = y - 1
							# @vy = -Math.abs(@vy) * 0.5
							@vy = 0
	
	draw: (ctx)->
		ctx.fillStyle = "yellow"
		ctx.fillRect @x*16, @y*16, @w*16, @h*16

module?.exports = @Ent
