
class @Tile
	constructor: (@x, @y, @value)->
	draw: (ctx)->
		ctx.fillStyle = ["transparent", "#555", "#444", "#555"][@value]
		if @value is 3
			ctx.beginPath()
			ctx.moveTo @x*16, @y*16+16
			ctx.lineTo @x*16+16, @y*16+16
			ctx.lineTo @x*16+16, @y*16
			ctx.fill()
		else
			ctx.fillRect @x*16, @y*16, 16, 16

module?.exports = @Tile
