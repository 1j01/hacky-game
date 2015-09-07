
exports.init = function(window){
	var console = window.console;
	var log = function (text){
		console.log("%cserver.js:%c " + text, "font-size:1.5em;color:gray","font-size:1.3em;font-family:sans-serif");;
	};
	if(global.server){
		log("close old server");
		global.server.close();
	}
	require("coffee-script/register");
	var Server = require("./Server.coffee");
	log("start new server");
	global.server = new Server;
};
