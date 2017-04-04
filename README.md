
# ![](game/images/icon-32.png) Hacky Game

This is the start of a game involving some crazy technical jazz,
for the sake of magical minimalism.

The game will be a platformer,
with lots of interconnected rooms and various enemies,
taking some inspiration from [Kirby & the Amazing Mirror][].

(Some basics are implemented, like blocks, slopes, one-way platforms, and doors.
There are several rooms, but they're pretty boring,
and the art is very preliminary.)

The game supports LAN multiplayer,
and the client's world is simulated in between updates from the server,
a basic implementation of [client-side prediction][].

Single player is treated the same: the client hosts a server and communicates with it locally over TCP.
This might change.

When other servers are discovered,
a magic door is opened to another world.

Players can travel between each other's worlds,
and you can even have two players in each other's worlds.
(But the player's client has to be online for their world to be available.)

You should be able to get a feel for the game in single-player,
with a substantial world to explore, but
I think multiplayer will be the real focal point of the game
and I think it would be interesting to have parts of the world that you can only explore with a friend.

Oh, did I mention the worlds are gonna be procedurally generated?
That's probably kind of important.
It might have a good amount of pre-made/human-formulated content,
maybe some areas that are the same in all worlds, like a tutorial level,
or just fairly similar but still functionally identical.

Both players should gain from exploring either players world.
It should be like the worlds combined make up the space to explore,
and which one to do first shouldn't feel contentious.

There could be doors that require multiple keys, that you need to get from several people.
There could be keys that belong to random other worlds and you have to find the one player that 
There could be halves of items (including keys)

The game runs in [nw.js][] (so it can include both client and server),
but the final `game.exe` is a wrapper.
The wrapper currently built with [nexe][],
although this essentially means distributing two Node.js runtimes,
which is a considerable amount of overhead which could ultimately be avoided.
It downloads the [nw.js][] runtime (on first load)
and extracts a zip file from [a resource in the executable][nexeres] containing the main application.
Then it launches the game, passing in the path to the executable.
It does all this so it can read and write game state from the end of the `exe` file.
(At the moment this functionality is disabled.
I did a tech demo of this first, but there are no persistent elements to the world yet.)


## Open Doors to Other Worlds

* Local multiplayer

	* Discovers other clients through tiny JSON files stored with ports and PIDs.
	(**NOTE**: Will need to choose a new directory when updating `nw` from `0.12.x`;
	the `single-instance` option is deprecated and you have to pass separate `--user-data-dir` values
	which the directory is currently based on)

	* **TODO**:
	  Remove the need for client-side prediction on the client's own server;
	  maybe fully merge the client and the server so they use one `World`,
	  or at least try stepping the server from the client.

	* **TODO:**
	  Manage input methods for multiple players.
	  You'll want to be able to play with two people on one keyboard
	  or use one or more gamepads,
	  and you won't be able to send input to two windows at once.


* Multiplayer over LAN

	* Discovers other clients with [SSDP][]

	* **TODO/FIXME:**
	  Handle connection ending
	  (don't crash on `ECONNRESET`, boot you from the world with a nice animation)
	
	* **TODO:**
	  Get booted if server isn't responding
	
	<!-- * **FIXME:**
	  Repeated `EADDRINUSE` errors from `super-ssdp` module -->
	<!-- This may be fixed, but I probably broke discovery entirely -->
	
	* **FIXME:**
	  Disparity between `localhost` and the IP address used when reentering your own world


<!-- would indent this but currently it applies even to single player: -->

* **TODO:**
  Implement [client-side prediction][] smoothing

* **FIXME:**
  There is a [race condition][] when going back and forth between rooms
  where you can get viewing a room that you aren't in.
  Entering a door involves sending a command to the server
  but you switch the room you're viewing instantly.



[nexe]: https://github.com/jaredallard/nexe
[nexeres]: https://github.com/jaredallard/nexe/pull/93
[nw.js]: https://github.com/nwjs/nw.js/
[client-side prediction]: https://en.wikipedia.org/wiki/Client-side_prediction
[SSDP]: https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol "Simple Service Discovery Protocol"
[race condition]: https://en.wikipedia.org/wiki/Race_condition
[Kirby & the Amazing Mirror]: https://en.wikipedia.org/wiki/Kirby_%26_the_Amazing_Mirror
