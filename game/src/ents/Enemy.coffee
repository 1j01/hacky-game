
module.exports =
class @Enemy extends (require "./Ent")
	step: (t)->
		@vx += 0.02
		if @grounded()
			@vy = -0.46
		super
	draw: (ctx)->
		ctx.fillStyle = "red"
		ctx.beginPath()
		ctx.ellipse 16/2, 16/2, @w*16/2+0.1, @h*16/2+0.2, 0, Math.PI*2, no
		ctx.fill()
