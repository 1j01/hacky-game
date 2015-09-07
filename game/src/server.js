
exports.init = function(window){
	var console = window.console;
	if(global.server){
		console.log("old server detected, closing");
		global.server.close();
	}
	console.log("coffee-script/register");
	require("coffee-script/register");
	console.log("require Server.coffee");
	var Server = require("./Server.coffee");
	console.log("new Server");
	global.server = new Server;
};
