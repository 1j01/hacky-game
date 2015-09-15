
# ![](game/images/icon-32.png) Hacky Game

This is the start of a game involving some crazy technical jazz.

The final `game.exe` is built with [nexe][].
It downloads the [nw.js][] runtime (on first load on a computer) and extracts a zip file from [a resource in the executable][nexeres] containing the main application.
Then it launches the game, passing in the path to the executable.
The game is able to erase/read/write JSON directly from the end of the `exe` file.
This can be used for saving/loading.
(At the moment it's disabled.)

The game is a platformer.
There are blocks, slopes, one-way platforms and doors.
There are several rooms, but they're pretty boring.
The art is preliminary.

The game supports LAN multiplayer.
Even in single player the client hosts a server and communicates with it locally over TCP.
The world is simulated locally independent of the server,
a basic implementation of [client-side prediction][].
When other servers are discovered,
a magic door is opened to another world.
A sort of portal. A doortal.


## Open Doors to Other Worlds

* Local multiplayer

	* Discovers other clients through the filesystem

	* **TODO:**
	  Manage input methods for multiple players.
	  You'll want to be able to play with two people on one keyboard
	  or use one or more gamepads,
	  and you won't be able to send input to two windows at once.


* Multiplayer over LAN

	* Discovers other clients with SSDP

	* **TODO/FIXME:**
	  Handle connection ending
	  (don't crash on `ECONNRESET`, boot you from the world with a nice animation)
	
	* **TODO:**
	  Get booted if server isn't responding
		
	* **FIXME:**
	  Repeated `EADDRINUSE` errors from `super-ssdp` module
	
	* **FIXME:**
	  Disparity between `localhost` and the IP address used when reentering your own world


* **TODO:**
  Implement [client-side prediction][] smoothing


* **FIXME:**
  There is a [race condition][] when going back and forth between rooms
  where you can get viewing a room that you aren't in,
  because entering a door involves sending a command the server
  but you switch the room you're viewing instantly.



[nexe]: https://github.com/jaredallard/nexe
[nexeres]: https://github.com/jaredallard/nexe/pull/93
[nw.js]: https://github.com/nwjs/nw.js/
[client-side prediction]: https://en.wikipedia.org/wiki/Client-side_prediction
[race condition]: https://en.wikipedia.org/wiki/Race_condition

