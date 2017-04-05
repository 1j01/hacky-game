
module.exports =
class @Tile
	constructor: (@x, @y, @value)->
	draw: (ctx)->
		ctx.fillStyle = switch @value
			when " " then "transparent"
			when "▩" then "#2a0a00"
			else "#310"
		
		fill = =>
			ctx.fill()
			ctx.clip()
			for [0..10]
				if Math.random() < 0.5
					ctx.fillStyle = "rgba(55, 55, 55, 0.2)"
				else
					ctx.fillStyle = "rgba(0, 0, 0, 0.2)"
				ctx.beginPath()
				w = ~~(Math.random() * 1) + 1
				h = ~~(Math.random() * 1) + 1
				ctx.ellipse ~~(16*Math.random()), ~~(24*Math.random()-3), w, h, 0, Math.PI*2, no
				ctx.fill()
		
		tri = (x1,y1, x2,y2, x3,y3)=>
			ctx.beginPath()
			ctx.moveTo 16*x1, 16*y1
			ctx.lineTo 16*x2, 16*y2
			ctx.lineTo 16*x3, 16*y3
			fill()
		
		switch @value
			when " "
				return
			when "◢"
				tri 0,1, 1,1, 1,0
			when "◣"
				tri 1,1, 0,1, 0,0
			when "◤"
				tri 0,1, 0,0, 1,0
			when "◥"
				tri 1,1, 1,0, 0,0
			when "▬"
				ctx.fillStyle = "#847E87"
				ctx.fillRect 0, 0, 16, 4
				ctx.fillStyle = "#CBDBFC"
				ctx.fillRect 0, 0, 16, 1
				return
			else
				ctx.beginPath()
				ctx.rect 0, 0, 16, 16
				fill()
