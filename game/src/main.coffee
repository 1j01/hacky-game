
net = require "net"

# a local world, simulated for Dead Reckoning
world = new World

# close any existing socket (for reloading in development)
if global.socket
	global.socket.removeAllListeners "end"
	global.socket.end()

# the client starts out connected to it's own server
global.socket = socket = net.connect port: 3164
socket.on "end", ->
	console.warn "Disconnected from server!"
socket.setEncoding "utf8"
socket.on "data", (json)->
	return if window.CRASHED
	# @TODO: handle this stream properly and split messages
	try
		message = JSON.parse json
	catch e
		console.warn "failed to parse json message", json
	if message?.room
		world.applyRoomUpdate message.room
	else
		console.warn "unknown message"

canvas = document.createElement "canvas"
document.body.appendChild canvas
ctx = canvas.getContext "2d"
do animate = ->
	return if window.CRASHED
	requestAnimationFrame animate
	canvas.width = innerWidth
	canvas.height = innerHeight
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	world.step()
	world.draw ctx

# world.applyRoomUpdate
# 	id: "first room ever"
# 	tiles: [
# 		[0,0,0,0,0,0,3]
# 		[0,0,0,0,0,0,1]
# 		[0,0,0,0,0,1,2]
# 		[1,1,1,1,1,2,2]
# 	]
# 	ents: [
# 		{x: 1, y: 1}
# 	]

console.log world

# last_savegame = {}
# 
# setInterval ->
# 	if textarea.value isnt last_savegame.text
# 		save_game {text: textarea.value}, (err, savegame)->
# 			if err
# 				console.error err
# 			else
# 				last_savegame = savegame
# , 500
# 
# load_game (err, savegame)->
# 	if err
# 		console.error err
# 		alert "I'm sorry.\n#{err}\nGoodbye."
# 		process.exit()
# 	else if savegame
# 		console.log "Game loaded successfully", savegame
# 		textarea.value = savegame.text
# 		last_savegame = savegame
# 	else
# 		console.log "Start new game"
