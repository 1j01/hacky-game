
class @World
	constructor: ->
		@rooms = []
	toJSON: ->
		{@rooms}

module?.exports = @World
