
module.exports =
class @OtherworldlyDoor extends (require "./Door")
	draw: (ctx)->
		ctx.save()
		ctx.save()
		ctx.globalAlpha = Math.random() * if @to and not @locked then 2 else 0.5
		ctx.fillStyle = "black"
		ctx.shadowColor = "rgba(0, 155, 255, 1)"
		ctx.shadowBlur = 90
		ctx.beginPath()
		ctx.ellipse 16/2, 0, @w*16/2, @h*16/2, 0, Math.PI*1, no
		ctx.lineTo 16, 16
		ctx.lineTo 0, 16
		ctx.fill()
		ctx.clip()
		ctx.shadowColor = "#fff"
		ctx.shadowBlur = 100
		for [0..10]
			ctx.fillStyle = "rgba(0, 155, 255, 0.1)"
			ctx.beginPath()
			r = Math.random() * 2 + 2
			ctx.ellipse 16*Math.random(), 24*Math.random()-3, r, r, 0, Math.PI*2, no
			ctx.fill()
		ctx.shadowBlur = 0
		ctx.globalAlpha = 1
		ctx.restore()
		if localStorage.debug_mode is "true"
			ctx.fillStyle = "white"
			ctx.fillStyle = simple_color_hash(@address)
			ctx.rotate(-0.3)
			ctx.fillText(@address, 0, 0)
		ctx.restore()
