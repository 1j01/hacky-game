
class @Door extends (require "../Ent")
	step: (t)->
		super # I guess...
	draw: (ctx)->
		ctx.fillStyle = "#000"
		ctx.shadowColor = "#fff"
		ctx.shadowBlur = 100
		ctx.beginPath()
		ctx.ellipse @x*16+16/2, @y*16, @w*16/2, @h*16/2, 0, Math.PI*1, no
		ctx.lineTo @x*16+16, @y*16+16
		ctx.lineTo @x*16, @y*16+16
		ctx.fill()
		ctx.shadowBlur = 0

module?.exports = @Door
