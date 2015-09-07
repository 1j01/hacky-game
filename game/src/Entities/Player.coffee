
keys = {}
window.addEventListener "keydown", (e)->
	keys[e.keyCode] = on
window.addEventListener "keyup", (e)->
	delete keys[e.keyCode]

class @Player extends (require "../Ent")
	step: (t)->
		move = keys[39]? - keys[37]?
		jump = keys[38]?
		@vx += 0.06 * move
		if jump and @collision @x, @y+0.1
			@vy = -0.56
		super

module?.exports = @Player
