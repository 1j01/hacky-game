
Tile = require "./Tile"
Ent = require "./Ent"

class @Room
	constructor: (@id)->
		@width = 0
		@height = 0
		@tiles = []
		@ents = []
	
	toJSON: ->
		{@id, @ents, tiles:
			for row, y in @tiles
				for tile, x in row
					tile.value
		}
	
	applyUpdate: ({tiles, ents})->
		if tiles
			@tiles =
				for row, y in tiles
					for value, x in row
						new Tile x, y, value
			@height = @tiles.length
			@width = 0
			@width = Math.max(@width, row.length) for row in tiles
		if ents
			@ents =
				for ent in ents
					existing_ent = @getEntByID ent.id
					if existing_ent
						existing_ent.applyUpdate ent
						existing_ent
					else
						# TODO: instantiate subclasses
						new Ent ent, @
	
	getEntByID: (id)->
		return ent for ent in @ents when ent.id is id
	
	step: (t)->
		for ent in @ents
			ent.step t
	
	draw: (ctx)->
		for row in @tiles
			for tile in row
				tile.draw ctx
		for ent in @ents
			ent.draw ctx

module?.exports = @Room
