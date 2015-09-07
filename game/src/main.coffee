
# a local world for Dead Reckoning
world = new World
# each client has a server
# server = new Server
# each client starts out connected to their own server
# world.connect server

# localStorage.debug = "*"

socket = io.connect "http://localhost:3164", transports: ['websocket']
socket.on "connect", ->
	console.log "Connected to server!"
socket.on "disconnect", ->
	console.warn "Disconnect from server!"
texts = []
socket.on "room", (room)->
	console.log {room}
	texts.push room

canvas = document.createElement "canvas"
document.body.appendChild canvas
ctx = canvas.getContext "2d"
do animate = ->
	requestAnimationFrame animate
	canvas.width = innerWidth
	canvas.height = innerHeight
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, canvas.width, canvas.height
	ctx.fillStyle = "red"
	# ctx.fillRect 0, 0, 5, 5
	ctx.font = "#{Math.random()*50+5}px monospace"
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
