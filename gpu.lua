local function gpu()
	--[[
		for a speedup(probably)
		we could probably set up a dedicated tile map
		and store the tiles in an easily draw-able/
		manipulatible format so as not to have to do
		so much on-the-fly bit manipulation while
		drawing to the screen, these maps will be
		updated when the tilemap areas in memory
		are written to.
	]]
	
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