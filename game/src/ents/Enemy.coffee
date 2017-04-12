
module.exports =
class @Enemy extends (require "./Ent")
	constructor: ->
		super
		@heading = 1
	step: (t)->
		@vx += 0.015 * @heading
		if @grounded() and not @collisionAt(@x + @heading * 1, @y + 0.1)
			# @heading = -@heading
			@vy = -0.5
		if (
			@collisionAt(@x + @heading * 0.01, @y - 0.1) and
			not @collisionAt(@x, @y - 0.1)
		)
			@heading = -@heading
		super
	draw: (ctx)->
		ctx.fillStyle = "red"
		ctx.beginPath()
		ctx.ellipse 16/2, 16/2, @w*16/2+0.1, @h*16/2+0.2, 0, Math.PI*2, no
		ctx.fill()
