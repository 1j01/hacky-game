
i = 5
setInterval ->
	document.body.innerHTML += "i = #{i *= 2.5}"
, 500

pkg = (require "nw.gui").App.manifest

setInterval ->
	document.body.innerHTML += "::#{pkg.keywords[~~(pkg.keywords.length * Math.random())]}::"
	document.body.scrollTop = document.body.scrollHeight
, 200
