
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
There are several rooms, but they're all bland and grey and boring and devoid of creativity.
Everything is basic shapes at this point.

The game is painstakingly architected for multiplayer.
The client hosts a server and communicates with it locally over TCP.
The world is simulated locally independent of the server,
a basic implementation of [client-side prediction][].


## Open Doors to Other Worlds

* Local multiplayer

	* Discovers other clients through the filesystem

	* **TODO:**
	  Manage input methods for multiple players.
	  You'll want to be able to play with two people on one keyboard
	  or use one or more gamepads,
	  and you won't be able to send input to two windows at once.


* **TODO:**
  Multiplayer over LAN

	* Discover other clients with SSDP

	* ~~I have two computers right next two each other, but they can't ping each other.~~
	  I've set up [LogMeIn Hamachi][] and it works great! Also enjoying [Synergy][] at the moment.
	  Now I can work on this!


[nexe]: https://github.com/jaredallard/nexe
[nexeres]: https://github.com/jaredallard/nexe/pull/93
[nw.js]: https://github.com/nwjs/nw.js/
[client-side prediction]: https://en.wikipedia.org/wiki/Client-side_prediction
[LogMeIn Hamachi]: https://secure.logmein.com/products/hamachi/
[Synergy]: http://synergy-project.org/
