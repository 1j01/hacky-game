
require "coffee-script/register"
World = require "./src/World"
Server = require "./src/Server"

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

# TODO: maybe have a Client or Game class
# can contain worlds_by_address and handle transitions

window.worlds_by_address = new Map

window.addEventListener "unload", =>
	global.server?.close()
	global.peer?.close()
	worlds_by_address.forEach (world)->
		world.socket?._socket.destroy()

console.log "Starting server"
global.server = new Server (err)->
	console.error err if err

global.server.getAddress (address)->
	world = new World onClientSide: yes, serverAddress: address
	window.worlds_by_address.set(address, world)
	window.world = world
	animate()
