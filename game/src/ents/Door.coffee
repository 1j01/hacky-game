
module.exports =
class @Door extends (require "../Ent")
	step: (t)->
		super # I guess...
	draw: (ctx)->
		ctx.beginPath()
		ctx.ellipse 16/2-0.5, 0, @w*16/2, @h*16/2, 0, Math.PI*1, no
		ctx.lineTo 16, 16
		ctx.lineTo 0, 16
		ctx.lineTo 0, 0
		ctx.closePath()
		ctx.fillStyle = if @to then "#100" else "rgba(0, 0, 0, 0.5)"
		ctx.fill()
		ctx.strokeStyle = "#E5461D"
		ctx.stroke()
	zIndex: 0
