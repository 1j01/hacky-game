
Tile = require "./Tile"
Ent = require "./ents/Ent"

module.exports =
class @Room
	constructor: (@id, @world)->
		@width = 0
		@height = 0
		@tiles = []
		@ents = []
	
	toJSON: ->
		{@id, @ents, tiles:
			(for row, y in @tiles
				str = ""
				for tile, x in row
					str += tile.value
				str
			).join "\n"
		}
	
	applyUpdate: ({tiles, ents})->
		# console.log "Room#applyUpdate", @id, @world["[[ID]]"]
		if tiles
			@tiles =
				for row, y in tiles.split "\n"
					for value, x in row
						new Tile x, y, value
			@height = @tiles.length
			@width = 0
			@width = Math.max(@width, row.length) for row in @tiles
			# TODO: reenable when there are actual updates
			# delete @tiles_canvas
			# delete @tiles_ctx
		
		if ents
			@ents =
				for ent in ents
					existing_ent = @getEntByID ent.id
					if existing_ent
						existing_ent.applyUpdate ent
						existing_ent
					else
						if ent.type and ent.type.match /\w+/
							EntClass = require "./ents/#{ent.type}"
							new EntClass ent, @, @world
						else
							new Ent ent, @, @world
	
	getEntByID: (id)->
		return ent for ent in @ents when ent.id is id
	
	hasPlayers: ->
		return yes for ent in @ents when ent.type is "Player"
		return no
	
	getPlayers: ->
		ent for ent in @ents when ent.type is "Player"
	
	getPlayer: (id = global.clientPlayerID)->
		@getEntByID(id)
	
	step: (t)->
		ent.step t for ent in @ents by -1
	
	collisionAt: (at_x, at_y, at_w, at_h, vx=0, vy=0)->
		return {x: -1, y: at_y} if at_x < 0
		return {y: -1, x: at_x} if at_y < 0 # unless open air?
		return {x: @width + at_w, y: at_y} if at_x + at_w > @width
		return {y: @height + at_h, x: at_x} if at_y + at_h > @height
		for y_off in [0, Math.ceil(at_h)]
			y = ~~at_y + y_off
			row = @tiles[y]
			continue unless row?
			for x_off in [0, Math.ceil(at_w)]
				x = ~~at_x + x_off
				tile = row[x]
				continue unless tile?
				continue if tile.value is " "
				if at_x < x + 1 and at_x + at_w > x
					if at_y < y + 1 and at_y + at_h > y
						switch tile.value
							when "◢"
								return tile if at_x + at_w - x + at_y + at_h - y > 1
							when "◣"
								return tile if x - at_x + at_y + at_h - y > 0
							when "◤"
								return tile if at_x - x + at_y - y < +1
							when "◥"
								return tile if x - at_x + at_y - y < +1
							when "▬"
								if at_y + at_h - y < 0.1 and vy >= 0
									return tile
							else # "■", "▩"...
								return tile
	
	draw: (ctx)->
		ctx.strokeStyle = "rgba(255, 255, 255, 0.4)"
		if localStorage.debug_mode is "true"
			ctx.strokeStyle = simple_color_hash(@world.serverAddress)
		ctx.strokeRect -1.5, -1.5, @width*16+3, @height*16+3
		
		# ctx.fillStyle = "#000"
		# ctx.fillRect 0, 0, @width*16, @height*16
		
		unless @bg_img
			@bg_img = new window.Image
			@bg_img.onload = =>
				@bg = ctx.createPattern @bg_img, 'repeat'
			@bg_img.src = "images/bg.png"
		
		ctx.save()
		ctx.fillStyle = @bg
		vx = ~~(@world.view.cx*16 / 2)
		vy = ~~(@world.view.cy*16 / 2)
		ctx.translate vx, vy
		ctx.fillRect -vx, -vy, @width*16, @height*16
		ctx.restore()
		
		unless @tiles_canvas
			@tiles_canvas = ctx.canvas.ownerDocument.createElement "canvas"
			@tiles_ctx = @tiles_canvas.getContext "2d"
			@tiles_canvas.width = @width * 16
			@tiles_canvas.height = @height * 16
			for row in @tiles
				for tile in row
					@tiles_ctx.save()
					@tiles_ctx.translate(
						~~(tile.x * 16)
						~~(tile.y * 16)
					)
					tile.draw @tiles_ctx
					@tiles_ctx.restore()
			
			for row in @tiles
				for tile in row when tile.value isnt " "
					for [0..15]
						x = tile.x + Math.random()
						y = tile.y - Math.random()
						if @collisionAt x, y, 1/16, 1/16
							for [0..10]
								y += 1/16
								break if @collisionAt x, y-1/16, 1/16, 1/16
							if @collisionAt x, y, 1/16, 1/16
								continue # what a poorly named statement
						for [0..10]
							y += 1/16
							break if @collisionAt x, y-1/16, 1/16, 1/16
						if ground = @collisionAt x, y+1/16, 1/16, 1/16
							unless ground.value is "▬"
								line(@tiles_ctx,
									if Math.random() < 0.4 then "#99E550" else "#4B692F"
									~~(x * 16)
									~~(y * 16)
									~~(x * 16 + Math.random() * 2 - 1)
									~~(y * 16 - Math.random() * 5 - 2)
								)
		
		ctx.drawImage @tiles_canvas, 0, 0
		
		for ent in (@ents.sort (e1, e2)-> e1.zIndex - e2.zIndex)
			ctx.save()
			ctx.translate(
				~~(ent.x * 16)
				~~(ent.y * 16)
			)
			ent.draw ctx
			ctx.restore()
