
Tile = require "./Tile"
Ent = require "./Ent"

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
		if tiles
			@tiles =
				for row, y in tiles.split "\n"
					for value, x in row
						new Tile x, y, value
			@height = @tiles.length
			@width = 0
			@width = Math.max(@width, row.length) for row in @tiles
		if ents
			@ents =
				for ent in ents
					existing_ent = @getEntByID ent.id
					if existing_ent
						existing_ent.applyUpdate ent
						existing_ent
					else
						if ent.type and ent.type.match /\w+/
							EntClass = require "./Entities/#{ent.type}"
							new EntClass ent, @, @world
						else
							new Ent ent, @, @world
	
	getEntByID: (id)->
		return ent for ent in @ents when ent.id is id
	
	step: (t)->
		# ent.beginStep? t for ent in @ents
		ent.step t for ent in @ents
		# ent.endStep? t for ent in @ents
	
	draw: (ctx)->
		ctx.fillStyle = "#111"
		ctx.fillRect 0, 0, @width*16, @height*16
		ctx.strokeStyle = "rgba(255, 255, 255, 0.4)"
		ctx.strokeRect -1.5, -1.5, @width*16+3, @height*16+3
		
		for row in @tiles
			for tile in row
				tile.draw ctx
		
		for ent in @ents
			ent.draw ctx
