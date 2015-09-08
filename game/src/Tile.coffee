
class @Tile
	constructor: (@x, @y, @value)->
	draw: (ctx)->
		ctx.fillStyle = "#555"
		ctx.fillStyle = ["transparent", "#555", "#444", "#555"][@value]
		if @value is 3
			ctx.beginPath()
			ctx.moveTo @x*16, @y*16+16
			ctx.lineTo @x*16+16, @y*16+16
			ctx.lineTo @x*16+16, @y*16
			ctx.fill()
		else if @value is 4
			ctx.beginPath()
			ctx.moveTo @x*16+16, @y*16+16
			ctx.lineTo @x*16, @y*16+16
			ctx.lineTo @x*16, @y*16
			ctx.fill()
		else if @value is 7
			ctx.fillRect @x*16, @y*16, 16, 4
		else
			ctx.fillRect @x*16, @y*16, 16, 16

module?.exports = @Tile
