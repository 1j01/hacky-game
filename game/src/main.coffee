
# a local world, simulated for Dead Reckoning
world = new World
# the client starts out connected to it's own server

net = require "net"

socket = net.connect port: 3164
texts = []
socket.on "data", (json)->
	data = JSON.parse json
	texts.push data.text
socket.on "end", ->
	console.warn "Disconnect from server!"

canvas = document.createElement "canvas"
document.body.appendChild canvas
ctx = canvas.getContext "2d"
do animate = ->
	requestAnimationFrame animate
	canvas.width = innerWidth
	canvas.height = innerHeight
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	ctx.fillStyle = "rgba(255, 0, 0, 0.2)"
	ctx.font = "#{Math.random()*500+5}px monospace"
	ctx.textAlign = "center"
	ctx.textBaseline = "middle"
	for text in texts
		ctx.fillText text, Math.random() * canvas.width, Math.random() * canvas.height


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
