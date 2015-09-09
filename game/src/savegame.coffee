
fs = require "fs"
game_exe = require "./exe-file"

find_saved_game = (callback)->
	fs.stat game_exe, (err, stats)->
		return callback err if err
		fs.open game_exe, "r+", (err, fd)->
			_cb = callback
			callback = (args...)->
				fs.close fd, (err)->
					return _cb err if err
					_cb args...
			
			buffer_size = 1024
			buffer = new Buffer(buffer_size)
			position = stats.size - buffer_size
			
			fs.read fd, buffer, 0, buffer_size, position, (err)->
				return callback err if err
				if buffer[buffer.length - 1] is "}".charCodeAt(0)
					combined = ""
					do read_backwards_until_json_is_parsable = ->
						buffer_str = buffer.toString "utf8"
						
						for char, i in buffer_str when char is "{"
							potential_json = "#{buffer_str.substring i}#{combined}"
							try gamesave = JSON.parse potential_json
							if gamesave
								file_position = stats.size - Buffer.byteLength potential_json
								return callback null, gamesave, file_position
						
						combined = "#{buffer_str}#{combined}"
						position -= buffer_size
						fs.read fd, buffer, 0, buffer_size, position, (err)->
							return callback err if err
							read_backwards_until_json_is_parsable()
				else
					callback()

module.exports =
	exists: (callback)->
		find_saved_game (err, savegame, file_position)->
			return callback err if err
			callback null, savegame?
	
	erase: erase_game = (callback)->
		find_saved_game (err, savegame, file_position)->
			return callback err if err
			return callback null unless savegame
			if savegame
				fs.truncate game_exe, file_position, callback
			else
				callback()
	
	load: (callback)->
		find_saved_game (err, savegame, file_position)->
			return callback err if err
			callback null, savegame
	
	save: (savegame, callback)->
		# TODO: operate atomicically
		erase_game (err)->
			return callback err if err
			json = JSON.stringify savegame
			fs.appendFile game_exe, json, (err)->
				return callback err if err
				callback null, savegame # in case you've forgotten what you passed into this function
