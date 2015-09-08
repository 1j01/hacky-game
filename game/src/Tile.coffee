
module.exports =
class @Tile
	constructor: (@x, @y, @value)->
	draw: (ctx)->
		ctx.fillStyle = switch @value
			when " " then "transparent"
			when "▩" then "#444"
			else "#555"
		
		tri = (x1,y1, x2,y2, x3,y3)=>
			ctx.beginPath()
			ctx.moveTo @x*16+16*x1, @y*16+16*y1
			ctx.lineTo @x*16+16*x2, @y*16+16*y2
			ctx.lineTo @x*16+16*x3, @y*16+16*y3
			ctx.fill()
		
		switch @value
			when "◢"
				tri 0,1, 1,1, 1,0
			when "◣"
				tri 1,1, 0,1, 0,0
			when "◤"
				tri 0,1, 0,0, 1,0
			when "◥"
				tri 1,1, 1,0, 0,0
			when "▬"
				ctx.fillRect @x*16, @y*16, 16, 4
			else
				ctx.fillRect @x*16, @y*16, 16, 16
