
forEachPointOnLine = (x0, y0, x1, y1, callback)->
	dx = Math.abs(x1 - x0)
	dy = Math.abs(y1 - y0)
	sx = if (x0 < x1) then 1 else -1
	sy = if (y0 < y1) then 1 else -1
	err = dx - dy
	loop
		callback(x0, y0)
		break if ((x0 is x1) and (y0 is y1))
		e2 = 2*err
		if (e2 >-dy) then (err -= dy; x0 += sx)
		if (e2 < dx) then (err += dx; y0 += sy)

# XXX: have to use global, not window or @ because basically everything is in Node's context
# the drawing stuff I feel like should *really* not be
global.line = (ctx, color, x0, y0, x1, y1)->
	ctx.fillStyle = color
	forEachPointOnLine x0, y0, x1, y1, (x, y)->
		ctx.fillRect(x, y, 1, 1)

global.simple_color_hash = (str)->
	n = 0
	for c, i in str
		n = ((n ^ c) ** i) %% 0xFFFFFF
	color = "#" + ("00000" + (n | 0).toString(16)).substr(-6)
