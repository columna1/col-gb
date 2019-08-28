local function gpu()
	local self = {
		--rom = {}
		buffer = {},--C000-DFFF/E000-FDFF
		scrollx = 0,
		scrolly = 0,
		bgtilemap = {},--FF80-FFFF
		canvas = love.graphics.newCanvas()
	}
	
	function self.reset()
		
	end
	
end