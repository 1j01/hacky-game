
Controller = require "../controllers/Controller"

module.exports = @Ent =
class Ent
	constructor: (obj, room, world)->
		@unsynced_props = ["unsynced_props"]
		@unsynced {room, world, zIndex: 10}
		@x = 0
		@y = 0
		@w = @h = 1
		@vx = 0
		@vy = 0
		@applyUpdate obj
	
	unsynced: (obj)->
		for k, v of obj
			@unsynced_props.push(k) unless k in @unsynced_props
			@[k] = v
	
	toJSON: ->
		o = {}
		for k, v of @ when not (
			(k in @unsynced_props) or
			(typeof v is "function")
		)
			o[k] = v
		o
	
	applyUpdate: (obj)->
		for k, v of obj
			@[k] = v
	
	remove: ->
		i = @room.ents.indexOf @
		@room.ents.splice i, 1 if i >= 0
	
	step: (t)->
		@vx *= 0.9
		@vy += 0.04
		res = 0.01
		for new_x in [@x..@x+@vx] by (if @vx < 0 then -res else res)
			if tile = @collisionAt new_x, @y, @vx, @vy
				if not @collisionAt new_x, @y - res*2, @vx, @vy
					@x = new_x
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
					@y = new_y
				else if not @collisionAt @x + res*2, new_y, @vx, @vy
					@x += res*2
					@y = new_y
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
		@room.collisionAt at_x, at_y, @w, @h, vx, vy
	
	entsAt: (x, y, w, h)->
		ent for ent in @room.ents when ent isnt @ and
			x < ent.x + w and x + w > ent.x and
			y < ent.y + h and y + h > ent.y
	
	draw: (ctx)->
		ctx.fillStyle = "#FBF236"
		ctx.strokeStyle = "#8F974A"
		ctx.beginPath()
		ctx.ellipse 16/2, 16/2, @w*16/2+0.5, @h*16/2+0.5, 0, Math.PI*2, no
		ctx.fill()
		ctx.stroke()
