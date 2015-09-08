
# ![](game/images/icon-64.png) Hacky Game

This is the start of a game involving some crazy technical jazz.

There's multiple rooms, but they're all bland and grey and boring and devoid of creativity.

**TODO:** monkey patch `nw-builder/lib/downloader.js` automatically

```js
// var ncp = require('graceful-ncp').ncp;
var ncp = require('cpr');
```

## TODO: Open Doors to Other Worlds

* Local multiplayer

	* Discover other clients through the filesystem

	* Allow the app (with the id "hacky-game") to be launched multiple times, but disallow multiple instances using the same executable

	* Manage input methods for multiple players


* Multiplayer over LAN

	* Discover other clients with SSDP

