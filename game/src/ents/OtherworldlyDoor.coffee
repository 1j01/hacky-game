
module.exports =
class @OtherworldlyDoor extends (require "./Door")
	constructor: ->
		super
		@unsynced particles: []
	draw: (ctx)->
		ctx.save()
		
		ctx.save()
		
		ctx.globalAlpha = if @to and not @locked then 1 else 0.3
		ctx.fillStyle = "black"
		ctx.shadowColor = "rgba(0, 155, 255, 1)"
		ctx.shadowBlur = 90
		ctx.beginPath()
		ctx.ellipse 16/2, 0, @w*16/2, @h*16/2, 0, Math.PI*1, no
		ctx.lineTo 16, 16
		ctx.lineTo 0, 16
		ctx.fill()
		ctx.clip()
		unless @locked
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
			
			target_x = @w*16 / 2
			target_y = @h*16 / 2
			for particle in @particles
				particle.x += particle.vx
				particle.y += particle.vy
				dist = Math.hypot(target_x - particle.x, target_y - particle.y)
				force = 0.1
				drag = -0.01
				particle.vx += (target_x - particle.x) / dist * force
				particle.vy += (target_y - particle.y) / dist * force
				particle.vx /= 1 + drag
				particle.vy /= 1 + drag
				ctx.fillStyle = "rgba(0, 155, 255, 0.5)"
				ctx.fillRect(particle.x, particle.y, 1, 1)
			@particles.push {
				x: target_x + (Math.random() * 2 - 1) * 3
				y: target_y + (Math.random() * 2 - 1) * 3 + 20
				vx: (Math.random() * 2 - 1) * 0.5
				vy: (Math.random() * 2 - 1) * 0.5
			}
			if @particles.length > 50
				@particles.splice(0, 1)
		
		ctx.restore()
		
		if localStorage.debug_mode is "true"
			ctx.fillStyle = "white"
			ctx.fillStyle = simple_color_hash(@address)
			ctx.textAlign = "right"
			ctx.textBaseline = "bottom"
			ctx.translate(0, -20)
			# ctx.rotate(Math.PI/2)
			ctx.rotate(0.9)
			ctx.fillText(@address, @w*16/2, 0)
		ctx.restore()
