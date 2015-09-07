
class @Enemy extends (require "../Ent")
	step: (t)->
		@vx += 0.02
		if @collision @x, @y+0.1
			@vy = -0.56
		super
	draw: (ctx)->
		ctx.fillStyle = "red"
		ctx.beginPath()
		ctx.ellipse @x*16+16/2, @y*16+16/2, @w*16/2, @h*16/2, 0, Math.PI*2, no
		ctx.fill()

module?.exports = @Enemy
