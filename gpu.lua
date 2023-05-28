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
	}
	
	function self.reset()
		self.buffer = {}
		self.scrollX = 0
		self.scrollY = 0
		self.bgtilemap = {}
		
		self.bgtile = 0
		self.bmap = 0
		
		self.tileSet = {}
		for i = 0,511 do
			self.tileSet[i] = {}
			for y = 0,7 do
				self.tileSet[i][y] = {}
				for x = 0,7 do
					self.tileSet[i][y][x] = 3
				end
			end
		end
		
		self.palette = {}
		
		self.palette[3] = {1,1,1}--white
		self.palette[2] = {0.6,0.6,0.6}--light gray
		self.palette[1] = {0.3,0.3,0.3}--dark gray
		self.palette[0] = {0,0,0}--black
		
		self.vram = {}
		for i = 0,0x2000 do
			self.vram[i] = 0
		end
		
		self.scrdata = {}
		for x = 0,160 do
			self.scrdata[x] = {}
			for y = 0,144 do
				self.scrdata[x][y] = 0
			end
		end
		
		
		self.canvas = love.graphics.newCanvas(160,144)
		self.mode = 0
		self.clock = 0
		self.line = 0
		
		self.lineMode = 2
		self.lineClock = 0 
		
		self.bgmap = false
		self.switchbg = false
		self.bgtile = false
		self.winEnable = false
		self.switchlcd = false
	end
	
	function self.updateLine(dt)
		self.lineClock = self.lineClock + dt
		if self.lineMode == 0 then--hblank
			if self.lineClock >= 204 then
				self.renderScanLine()
				self.lineClock = self.lineClock - 204
				self.line = self.line + 1
				if self.line >= 144 then
					--print("set gpu interupt")
					self.mmu.setByte(bit.bor(self.mmu.getByte(0xFF0F),1),0xFF0F)
					self.lineMode = 1
				end
			end
		elseif self.lineMode == 1 then--vblank
			if self.lineClock >= 456 then
				self.lineClock = self.lineClock - 456
				self.line = self.line + 1
				if self.line >= 154 then
					self.line = 0
					self.lineMode = 2
					--self.mmu.setByte(bit.band(self.mmu.getByte(0xFF0F),0xFE),0xFF0F)
				end
			end
		elseif self.lineMode == 2 then--OAM scan
			if self.lineClock >= 80 then
				self.lineClock = self.lineClock - 80
				self.lineMode = 3
			end
		elseif self.lineMode == 3 then--Pixel drawing
			if self.lineClock >= 172 then
				self.lineClock = self.lineClock - 172
				self.lineMode = 0
			end
		end
	end
	
	function self.updateTile(addr,val)
		addr = bit.band(addr,0x1FFE)
		local saddr = addr
		if bit.band(addr,1) == 1 then
			saddr = saddr - 1
			addr = addr - 1
		end
		local tile = bit.band(bit.rshift(addr,4),0x1FF)
		local y = bit.band(bit.rshift(addr,1),7)
		--print("y",y)
		local sx = 0
		for x = 0,7 do
			sx = bit.lshift(1,7-x)
			if not self.tileSet[tile] then self.tileSet[tile] = {} end
			if not self.tileSet[tile][y] then self.tileSet[tile][y] = {} end
			--print(saddr,self.vram[saddr])
			self.tileSet[tile][y][x] = ((bit.band(self.vram[saddr],sx) > 0) and 1 or 0) + ((bit.band(self.vram[saddr+1],sx) > 0) and 2 or 0)
			--print(self.vram[addr],addr)
		end
	end
	
	function self.renderScanLine()
		local line = self.line
		line = line + self.scrollY
		line = bit.band(line,0xFF)--limit value and perform screen roll
		local xoff = self.scrollX
		local y = line
		for xx = 0,160 do
			local x = xx+xoff
			x = bit.band(x,0xFF)
			local tilex = math.floor(x/8)
			local tiley = math.floor(y/8)
			local n = (tiley*32)+tilex
			if gbCPU.gpu.bgmap then
				n = n + 0x9C00
			else
				n = n + 0x9800
			end
			if not gbCPU.gpu.bgtile then
				tilenum = gbCPU.gpu.vram[bit.band(n,0x1FFF)]
				if bit.band(tilenum,0x80) > 0 then
					tilenum = -(bit.band(bit.bnot(tilenum),0xFF)+1)
				end
				tilenum = 256+tilenum
			else
				tilenum = gbCPU.gpu.vram[bit.band(n,0x1FFF)]
			end
			local tile = gbCPU.gpu.tileSet[tilenum]
			if tile then 
				self.scrdata[xx][self.line] = tile[y%8][x%8] 
			else 
				self.scrdata[xx][self.line] = 0 
			end
		end
	end
	
	function self.step(dt)
		if mode == 2 then
			--OAM read, scanline is active
			if self.clock >= 80 then
				self.clock = 0
				--self.clock = self.clock-80
				self.mode = 3
			end
		elseif mode == 3 then
			--vram read mode, scanline is active
			--end of scanline
			if self.clock >= 172 then
				self.clock = 0
				----self.clock = self.clock-172
				self.mode = 0
				
				self.renderScanLine()
			end
		elseif mode == 0 then
			--hblank
			if self.clock >= 204 then
					self.clock = 0
					--self.clock = self.clock-204
					self.line = self.line + 1
					
					if self.line == 143 then
						--enter vblank
						self.mode = 1
						self.renderCanvas()
					else
						--start next line
						self.mode = 2
					end
			end
		elseif mode == 1 then
			--vblank for 10 lines
			if self.clock >= 456 then
				self.clock = 0
				--self.clock = self.clock-456
				self.line = self.line + 1
				if self.line > 153 then
						self.mode = 2
						self.line = 0
				end
			end
		end
	end
	
	
	self.reset()
	return self
end

return gpu
