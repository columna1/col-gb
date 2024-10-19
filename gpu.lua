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
		self.scrollX = 0
		self.scrollY = 0
		self.winX = 0
		self.winY = 0
		self.bgtilemap = {}
		self.lcdc = 0
		self.STAT = 0
		self.LYC = 0

		self.bgtile = 0

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

		self.oamMem = {}
		for i = 0xfe00,0xfe9f do
			self.oamMem = 0
		end
		self.oam = {}
		for i = 1,40 do
			self.oam[i] = {0,0,0,0}--y,x,index,flags
		end

		self.palette = {4,3,2,1}
		self.paletteb = 0
		self.obp0b = 0
		self.obp1b = 0
		self.obp0 = {4,3,2,4}
		self.obp1 = {1,2,3,4}
		self.palette[0] = 1
		self.obp0[0] = 1
		self.obp1[0] = 1

		self.vram = {}
		for i = 0,0x2000 do
			self.vram[i] = 0
		end

		self.scrdata = {}
		for x = 0,160 do
			self.scrdata[x] = {}
			for y = 0,144 do
				self.scrdata[x][y] = 1
			end
		end


		self.canvas = love.graphics.newCanvas(160,144)
		self.mode = 0
		self.clock = 0
		self.line = 0
		self.wLine = 0

		self.lineMode = 2
		self.lineClock = 0

		self.objEnable = 0
		self.objSize = 0
		self.bgmap = false
		self.switchbg = false
		self.bgtile = false
		self.winEnable = false
		self.switchlcd = false
		self.frames = 0

		self.fps = 0
		self.lastTime = love.timer.getTime()
	end

	function self.updateLine(dt)

		local function incLine()
			self.line = self.line + 1
			if (self.winX >= 0) and (self.winX <= 166) and (self.winY >= 0) and (self.winY <= 143) then
				self.wLine = self.wLine + 1
			end
			--check for LYC STAT int
			local statByte = self.mmu.getByte(0xFF41)
			if self.line == self.LYC then
				self.mmu.setByte(bit.bor(self.mmu.getByte(0xFF0F),2),0xFF0F)--STAT int IF flag
				self.mmu.setByte(bit.bor(statByte,0x02),0xFF41)--mode 1 int select
			end
		end

		self.lineClock = self.lineClock + dt
		if self.lineMode == 0 then--hblank
			if self.lineClock >= 204 then
				self.renderScanLine()
				self.lineClock = self.lineClock - 204
				incLine()
				if breaking then
					running = false
					print(line,self.line)
				end
				if self.line >= 144 then
					--print("set gpu interupt")
					self.mmu.setByte(bit.bor(self.mmu.getByte(0xFF0F),1),0xFF0F)--vblank int
					self.lineMode = 1

					local statByte = self.mmu.getByte(0xFF41)
					if bit.band(statByte,0x10) == 0 then --don't run if bit is on: STAT blocking
						self.mmu.setByte(bit.bor(self.mmu.getByte(0xFF0F),2),0xFF0F)--STAT int
						self.mmu.setByte(bit.bor(statByte,0x10),0xFF41)--mode 1 int select
					end
				end
			end
		elseif self.lineMode == 1 then--vblank
			if self.lineClock >= 456 then
				self.lineClock = self.lineClock - 456
				incLine()

				if self.line >= 154 then
					self.line = 0
					self.wLine = 0
					self.lineMode = 2
					--self.mmu.setByte(bit.band(self.mmu.getByte(0xFF0F),0xFE),0xFF0F)
					self.frames = self.frames + 1
					local ft = love.timer.getTime()
					self.fps = (self.fps+(1/(ft-self.lastTime)))/2
					self.lastTime = ft
					--print("frame",self.frames)
					local statByte = self.mmu.getByte(0xFF41)
					if bit.band(statByte,0x20) == 0 then --don't run if bit is on: STAT blocking
						self.mmu.setByte(bit.bor(self.mmu.getByte(0xFF0F),2),0xFF0F)--STAT int
						self.mmu.setByte(bit.bor(statByte,0x20),0xFF41)--mode 2 int select
					end
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

				local statByte = self.mmu.getByte(0xFF41)
				if bit.band(statByte,0x08) == 0 then --don't run if bit is on: STAT blocking
					self.mmu.setByte(bit.bor(self.mmu.getByte(0xFF0F),2),0xFF0F)--STAT int
					self.mmu.setByte(bit.bor(statByte,0x08),0xFF41)--mode 0 int select
				end
			end
		end
	end

	function self.getOAM(addr)
		local n = bit.band(addr,0xFF)
		local tilenum = math.floor(n/4)
		local b = n-(tilenum*4)
		return self.oam[tilenum+1][b+1]
	end
	function self.updateOAM(addr,val)
		local n = bit.band(addr,0xFF)
		local tilenum = math.floor(n/4)
		local b = n-(tilenum*4)
		self.oam[tilenum+1][b+1] = val
	end

	function self.updateTile(addr,val)
		addr = bit.band(addr,0x1FFE)
		local tile = bit.band(bit.rshift(addr,4),0x1FF)
		local y = bit.band(bit.rshift(addr,1),7)
		local sx = 0
		for x = 0,7 do
			sx = bit.lshift(1,7-x)
			if not self.tileSet[tile] then self.tileSet[tile] = {} end
			if not self.tileSet[tile][y] then self.tileSet[tile][y] = {} end
			self.tileSet[tile][y][x] = ((bit.band(self.vram[addr],sx) > 0) and 1 or 0) + ((bit.band(self.vram[addr+1],sx) > 0) and 2 or 0)
		end
	end

	function self.renderScanLine()
		local line = self.line
		line = line + self.scrollY
		line = bit.band(line,0xFF)--limit value and perform screen roll
		local xoff = self.scrollX
		local y = line

		local lineObjects = {}

		--[[During each scanline’s OAM scan, the PPU compares LY (using LCDC bit 2 to determine their size) to each object’s Y position to select up to 10 objects to be drawn on that line. The PPU scans OAM sequentially (from $FE00 to $FE9F), selecting the first (up to) 10 suitably-positioned objects.

Since the PPU only checks the Y coordinate to select objects, even off-screen objects count towards the 10-objects-per-scanline limit. Merely setting an object’s X coordinate to X = 0 or X ≥ 168 (160 + 8) will hide it, but it will still count towards the limit, possibly causing another object later in OAM not to be drawn. To keep off-screen objects from affecting on-screen ones, make sure to set their Y coordinate to Y = 0 or Y ≥ 160 (144 + 16). (Y ≤ 8 also works if object size is set to 8×8.)]]

		--if self.objEnable then
			for o = 1,40 do -- search through all oam objects to find what objects are visible on this line
				local height = 8
				if self.objSize then height = 0 end
				if (self.oam[o][1] > self.line+height) and (self.oam[o][1] <= self.line+16) then--y pos
					table.insert(lineObjects,self.oam[o])

					if #lineObjects > 9 then break end--todo account for priority https://gbdev.io/pandocs/OAM.html#object-priority-and-conflicts
				end
			end
		--end
		--if self.line == 69 then
		--	for til = 1,#lineObjects do
		--		local o = lineObjects[til]
		--		print(string.format("%d xy %d %d oam tile %d",til,o[2],o[1],o[3] ))
		--	end
		--	--printTable(lineObjects)
		--end

		for xx = 0,160 do
			local x = xx+xoff
			x = bit.band(x,0xFF)
			local tilex = math.floor(x/8)
			local tiley = math.floor(y/8)
			local n = (tiley*32)+tilex
			if self.bgmap then
				n = n + 0x9C00
			else
				n = n + 0x9800
			end

			--background map rendering--
			local tilenum = 0
			if not self.bgtile then
				tilenum = self.vram[bit.band(n,0x1FFF)]
				--if bit.band(tilenum,0x80) > 0 then
				--	tilenum = -(bit.band(bit.bnot(tilenum),0xFF)+1)
				--end
				tilenum = (tilenum+128)%256

				tilenum = 128+tilenum
			else
				tilenum = self.vram[bit.band(n,0x1FFF)]
			end
			local tile = self.tileSet[tilenum]
			if tile then
				--self.scrdata[xx][self.line] = tile[y%8][x%8]
				self.scrdata[xx][self.line] = self.palette[tile[y%8][x%8]]
			else
				self.scrdata[xx][self.line] = 1
			end
			if not self.switchbg then
				self.scrdata[xx][self.line] = 1
			end

			--window rendering--
			local se = self.winEnable-- and self.switchbg
			if (self.line >= self.winY) and (xx+7 >= self.winX) and se then
				local wx = xx-self.winX+7
				local wy = self.wLine-self.winY
				local tilex = math.floor(wx/8)
				local tiley = math.floor(wy/8)
				local n = (tiley*32)+tilex



				if self.winMap then
					n = n + 0x9C00
				else
					n = n + 0x9800
				end
				tilenum = 0
				if not self.bgtile then
					tilenum = self.vram[bit.band(n,0x1FFF)]
					--if bit.band(tilenum,0x80) > 0 then
					--	tilenum = -(bit.band(bit.bnot(tilenum),0xFF)+1)
					--end
					tilenum = (tilenum+128)%256

					tilenum = 128+tilenum
				else
					tilenum = self.vram[bit.band(n,0x1FFF)]
				end
				--tilenum = self.vram[bit.band(n,0x1FFF)]
				tile = self.tileSet[tilenum]

				if tile then
					--print("drawing tile",xx,x,y,self.line,tile[y%8][x%8])
					--print("drawing wile",xx,wx,wy,self.line,tile[wy%8][wx%8])
					--self.scrdata[xx][self.line] = tile[y%8][x%8]
					self.scrdata[xx][self.line] = self.palette[tile[wy%8][wx%8]]
				else
					self.scrdata[xx][self.line] = 3
				end

			end


			--object rendering--
			local cp = self.scrdata[xx][self.line] --cp is
			local pixelX = 1000--the current x priority of the object on this pixel. if the x priority is lower then we can draw over otherwise just ignore

			if self.objEnable then--Todo, maybe put this in a better place? it was being moved around because I had a bug elsewhere
				for i = #lineObjects,1,-1 do
					if (lineObjects[i][2] > xx) and (lineObjects[i][2] <= xx+8) then--x pos
						--printTable(self.oam[i])
						local objx = lineObjects[i][2]
						local ll = lineObjects[i][1]-16
						local xxx = lineObjects[i][2]-8
						--print(line-ll)
						ll = self.line-ll
						xxx = xx-xxx
						if bit.band(lineObjects[i][4],0x20) > 0 then--horizontal flip bit 5
							xxx = 7-xxx
						end
						--print(line,x,ll,xxx)
						local t = {}
						if self.objSize then
							if bit.band(lineObjects[i][4],0x40) > 0 then
								if ll >= 8 then
									t = self.tileSet[bit.band(lineObjects[i][3],0xFE)]
								else
									t = self.tileSet[bit.band(lineObjects[i][3],0xFE)+1]
								end
							else
								if ll >= 8 then
									t = self.tileSet[bit.band(lineObjects[i][3],0xFE)+1]
								else
									t = self.tileSet[bit.band(lineObjects[i][3],0xFE)]
								end
							end
						else
							t = self.tileSet[lineObjects[i][3]]
						end
						--if not t[ll] then print(ll,ll%8,t) end
						local lt = ll%8
						if (bit.band(lineObjects[i][4],0x40) > 0) then--vertical flip bit 6
							lt = 7-lt
						end
						local p = t[lt][xxx]
						if p ~= 0 then
							--priorty bit
							if (not (bit.band(lineObjects[i][4],0x80) > 0)) or ((bit.band(lineObjects[i][4],0x80) > 0)
							and cp == 1) then
								--object palette
								if objx <= pixelX then
									if bit.band(lineObjects[i][4],0x10) > 0 then
										self.scrdata[xx][self.line] = self.obp1[p]
										pixelX = objx
									else
										self.scrdata[xx][self.line] = self.obp0[p]
										pixelX = objx
									end
								end
							end
						end
					end
				end
			end
		end
	end

	self.reset()
	return self
end

return gpu
