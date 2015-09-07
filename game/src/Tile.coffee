
class @Tile
	constructor: (@x, @y, @value)->
	draw: (ctx)->
		ctx.fillStyle = ["#111", "#555", "#444"][@value]
		ctx.fillRect @x*16, @y*16, 16, 16

module?.exports = @Tile
