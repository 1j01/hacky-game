
module.exports =
class @OtherworldlyDoor extends (require "./Door")
	draw: (ctx)->
		ctx.globalAlpha = Math.random() * 0.8
		super
		ctx.globalAlpha = 1
