
World = require "./World"

canvas = document.createElement "canvas"
ctx = canvas.getContext "2d"
canvas2x = document.createElement "canvas"
ctx2x = canvas2x.getContext "2d"
document.body.appendChild canvas2x

animate = ->
	return if window.CRASHED
	requestAnimationFrame animate
	world.step()
	# global.server?.world.step()
	canvas2x.width = innerWidth if canvas2x.width isnt innerWidth
	canvas2x.height = innerHeight if canvas2x.height isnt innerHeight
	canvas.width = Math.ceil(innerWidth / 2) if canvas.width isnt Math.ceil(innerWidth / 2)
	canvas.height = Math.ceil(innerHeight / 2) if canvas.height isnt Math.ceil(innerHeight / 2)
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	world.draw ctx
	ctx2x.imageSmoothingEnabled = off
	ctx2x.drawImage canvas, 0, 0, canvas2x.width, canvas2x.height

# TODO: make this a Map
window.worlds_by_address = {}

global.wait_for_local_server_address (address)->
	window.worlds_by_address[address] =
	window.world = new World onClientSide: yes, serverAddress: address
	animate()
