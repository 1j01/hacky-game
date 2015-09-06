
stuff_div = document.createElement "div"
document.body.appendChild stuff_div
stuff_div.style.height = "100vh"
stuff_div.style.overflow = "hidden"


i = 5
setInterval ->
	stuff_div.innerHTML += "i = #{i *= 2.5}"
, 500

pkg = (require "nw.gui").App.manifest

setInterval ->
	stuff_div.innerHTML += "::#{pkg.keywords[~~(pkg.keywords.length * Math.random())]}::"
	stuff_div.scrollTop = stuff_div.scrollHeight
, 200

imgs = (img for img in require("fs").readdirSync "images" when img.match /\.(png|gif)/)
setInterval ->
	stuff_div.innerHTML += "<img src='images/#{imgs[~~(imgs.length * Math.random())]}'>"
	stuff_div.scrollTop = stuff_div.scrollHeight
, 900

div = document.createElement "div"
textarea = document.createElement "textarea"
document.body.appendChild div
div.appendChild textarea
div.className = "how-is-this-a-game"

last_savegame = {}

setInterval ->
	if textarea.value isnt last_savegame.text
		save_game {text: textarea.value}, (err, savegame)->
			if err
				console.error err
			else
				last_savegame = savegame
, 500

load_game (err, savegame)->
	if err
		console.error err
		alert "I'm sorry.\n#{err}\nGoodbye."
		process.exit()
	else if savegame
		console.log "Game loaded successfully", savegame
		textarea.value = savegame.text
		last_savegame = savegame
	else
		console.log "Start new game"
