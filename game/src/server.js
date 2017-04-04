
global.wait_for_local_server_port = function(callback){
	var wait_for_server_iid = setInterval(function (){
		if(global.server){
			clearInterval(wait_for_server_iid);
			global.server.getPort(callback);
		}else{
			console.log("waiting for global.server");
		}
	}, 50);
};

exports.init = function(window, callback){
	var console = window.console;
	var log = function (text){
		console.log("%cserver.js:%c " + text, "font-size:1.5em;color:gray","font-size:1.3em;font-family:sans-serif");;
	};
	var start_sever = function(){
		require("coffee-script/register");
		var Server = require("./Server.coffee");
		log("start new server");
		global.server = new Server(function (err){
			callback(err, global.server);
		});
	};
	var old_server = global.server;
	if(old_server){
		log("close old server");
		global.server = null;
		old_server.close(start_sever);
	}else{
		log("no old server");
		start_sever();
	}
};
