
class @Player extends (require "../Ent")
	step: (t)->
		@vx += 0.04
		if @collision @x, @y+0.1
			@vy = -0.56
		super

module?.exports = @Player
