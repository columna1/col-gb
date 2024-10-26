local function mmu(file,testing,state)
	local self = {}

	local bios = {}
	local serialstr = ""
	function self.reset()
		--print("mmu reset")
		--error()
		self.workingRam = {}--C000-DFFF/E000-FDFF
		self.zeroPage = {}--FF80-FFFF
		self.romBank0 = {}--0000-3FFF
		self.romBank1 = {}--4000-7FFF

		--MBC related
		self.fn = file
		self.mbcType = 0
		self.memBank = 1
		self.ramBank = 0
		self.eRamEnable = false
		self.eRam = {}
		self.rtcEn = 0
		self.bigRom = false

		self.ipend = false


		self.sc = 0--serial control


		for i = 0xC000,0xDFFF do
			self.workingRam[i-0xC000] = 0--init working ram to 0
		end
		for i = 0xFF80,0xFFFF do
			self.zeroPage[i-0xFF80] = 0--init working ram to 0
		end
		bios = {[0]=0x31, 0xFE, 0xFF, 0xAF, 0x21, 0xFF, 0x9F, 0x32, 0xCB, 0x7C, 0x20, 0xFB, 0x21, 0x26, 0xFF, 0x0E,
	0x11, 0x3E, 0x80, 0x32, 0xE2, 0x0C, 0x3E, 0xF3, 0xE2, 0x32, 0x3E, 0x77, 0x77, 0x3E, 0xFC, 0xE0,
	0x47, 0x11, 0x04, 0x01, 0x21, 0x10, 0x80, 0x1A, 0xCD, 0x95, 0x00, 0xCD, 0x96, 0x00, 0x13, 0x7B,
	0xFE, 0x34, 0x20, 0xF3, 0x11, 0xD8, 0x00, 0x06, 0x08, 0x1A, 0x13, 0x22, 0x23, 0x05, 0x20, 0xF9,
	0x3E, 0x19, 0xEA, 0x10, 0x99, 0x21, 0x2F, 0x99, 0x0E, 0x0C, 0x3D, 0x28, 0x08, 0x32, 0x0D, 0x20,
	0xF9, 0x2E, 0x0F, 0x18, 0xF3, 0x67, 0x3E, 0x64, 0x57, 0xE0, 0x42, 0x3E, 0x91, 0xE0, 0x40, 0x04,
	0x1E, 0x02, 0x0E, 0x0C, 0xF0, 0x44, 0xFE, 0x90, 0x20, 0xFA, 0x0D, 0x20, 0xF7, 0x1D, 0x20, 0xF2,
	0x0E, 0x13, 0x24, 0x7C, 0x1E, 0x83, 0xFE, 0x62, 0x28, 0x06, 0x1E, 0xC1, 0xFE, 0x64, 0x20, 0x06,
	0x7B, 0xE2, 0x0C, 0x3E, 0x87, 0xE2, 0xF0, 0x42, 0x90, 0xE0, 0x42, 0x15, 0x20, 0xD2, 0x05, 0x20,
	0x4F, 0x16, 0x20, 0x18, 0xCB, 0x4F, 0x06, 0x04, 0xC5, 0xCB, 0x11, 0x17, 0xC1, 0xCB, 0x11, 0x17,
	0x05, 0x20, 0xF5, 0x22, 0x23, 0x22, 0x23, 0xC9, 0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B,
	0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D, 0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E,
	0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99, 0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC,
	0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E, 0x3C, 0x42, 0xB9, 0xA5, 0xB9, 0xA5, 0x42, 0x3C,
	0x21, 0x04, 0x01, 0x11, 0xA8, 0x00, 0x1A, 0x13, 0xBE, 0x20, 0xFE, 0x23, 0x7D, 0xFE, 0x34, 0x20,
	0xF5, 0x06, 0x19, 0x78, 0x86, 0x23, 0x05, 0x20, 0xFB, 0x86, 0x20, 0xFE, 0x3E, 0x01, 0xE0, 0x50}--bios rom WARNING © NINTENDO

		self.rom = {}
		for i = 1,0x7FFF do
			--if i-1 == 0x4244 then print(string.byte(str:sub(i,i))) end
			self.rom[i-1] = 0
		end
		if testing then-- json tests
			self.testingram = {}
			for i = 1,0xFFFF do
				--if i-1 == 0x4244 then print(string.byte(str:sub(i,i))) end
				self.testingram[i-1] = 0
			end
			--print("setting state")
			for i = 1,#state do
				--print(state[i][2],state[i][1])
				self.setByte(state[i][2],state[i][1])
			end
		else
			if not file then error("no rom to load") end
			local romFile = io.open(file,"rb")
			if not romFile then error("could not open rom") end
			local str = romFile:read("*a")
			romFile:close()
			--local str,size = love.filesystem.read(file)
			--if not str then
			--	error("could not open rom")
			--end
			for i = 1,#str do
				--if i-1 == 0x4244 then print(string.byte(str:sub(i,i))) end
				self.rom[i-1] = string.byte(str:sub(i,i))
			end
			print("rom size: "..self.rom[0x0148])--todo: utilize these
			print("ram size: "..self.rom[0x0149])
			print(string.format("CGB flag: 0x%02x",self.rom[0x0143]))
			local ramLUT = {
				[0] = 0,
				[1] = 0,
				[2] = 1024*8,
				[3] = 1024*32,
				[4] = 1024*128,
				[5] = 1024*64
			}
			self.ramNum = self.rom[0x0149]
			self.ramSize = ramLUT[self.ramNum]
			print(self.ramSize)
			for i = 0x00,self.ramSize-1 do--persistant storage for saves and such
				self.eRam[i] = 0
			end
			self.title = ""
			for i = 0x0134,0x0143 do
				if self.rom[i] == 0 then break end
				self.title = self.title..string.char(self.rom[i])
			end


			print("mbth "..string.format("%02x",self.rom[0x0147]))
			--self.mbcType = self.rom[0x0147] == 0x13 and 3 or 0
			local mbt = self.rom[0x0147]
			print("mbtd "..mbt)
			if mbt == 0x03 then--MBC1 + Ram + Battery
				self.mbcType = 1
				--if #self.rom > 102400 then self.bigRom = true end
			elseif mbt == 0 then --no MBC
				print("mbc type 0")
			elseif mbt == 19 then --MBC3+RAM+BATTERY
				self.mbcType = 3
				if #self.rom > 102400 then self.bigRom = true end
			elseif mbt == 17 then --MBC3
				self.mbcType = 3
				if #self.rom > 102400 then self.bigRom = true end
			elseif mbt == 1 then --MBC1
				self.mbcType = 1
				--if #self.rom > 102400 then self.bigRom = true end
			elseif mbt == 25 then --MBC5
				self.mbcType = 5
				--if #self.rom > 102400 then self.bigRom = true end
			elseif mbt == 27 then --MBC5+Ram+Battery
				self.mbcType = 5
				--if #self.rom > 102400 then self.bigRom = true end
			else
				error(string.format("MBC type %s not implemented",mbt))
			end
			print("MBC ID: "..self.mbcType)
			--self.mbcType = 0
			--[[
			for i = 0x0000,0x3FFF do
				self.romBank0[i] = self.rom[i]
			end
			if self.mbcType == 0 then
				for i = 0x4000,0x7FFF do
					self.romBank1[i] = self.rom[i]
				end
			end]]--
			self.inBootRom = 0
		end
		self.intFlags = 0
		--print("value",self.rom[786432])
	end

	function self.getByte(addr)
		if testing then
			return self.testingram[addr]
		end
		--print("read",addr)
		local function getBits(len)--calculate the number of bits needed to mask a certain size, then return mask
			--get bits needed
			len = len / 0x4000--the number of pages needed
			local bits = math.floor(math.log(len) / math.log(2))
			local mask = 1
			for i = 1,bits do
				mask = bit.lshift(mask,1)
				mask = mask+1
			end
			return mask
		end
		--print(string.format("get byte addr: 0x%x(%d)",addr,addr))
		local function pr(num)
			--print(string.format("returned value: 0x%x(%d)",num,num))
		end
		if (addr >= 0x00) and (addr < 0x100) and (self.inBootRom == 0) then
			--accessing bios
			--print("get byte ",addr,
			--print(self.inBootRom)
			return bios[addr]
		elseif addr >= 0x0000 and addr <= 0x3FFF then
			--print("get byte ",addr,rom[addr-0x100])
			--print("from rom")
			--pr(self.romBank0[addr])
			----return self.romBank0[addr]
			if self.mbcType == 1 and self.bigRom then
				local adr = addr
				--if self.memBank ~= 1 then print(self.memBank) end
				local mb = bit.band(bit.band(self.memBank,0x60),getBits(#self.rom))--wtf why
				--print()
				--print(mb,bit.band(self.memBank,0x30),self.memBank)
				--if mb == 16 then mb = 0 end--todo MBC1M
				adr = addr + (0x4000*(mb))
				--print("returning",adr,mb)
				return self.rom[adr]
			end
			return self.rom[addr]
		elseif addr >= 0x4000 and addr <= 0x7FFF then
			if self.mbcType == 0 then
				----return self.romBank1[addr]
				return self.rom[addr]
			elseif self.mbcType == 1 then--todo other un-reachable pages in MBC1
				local adr = addr
				--if self.memBank ~= 1 then print(self.memBank) end
				local mb = bit.band(self.memBank,getBits(#self.rom))
				if bit.band(self.memBank,0x1F) == 0 then mb = mb + 1 end
				adr = addr + (0x4000*(mb-1))
				return self.rom[adr]
			elseif self.mbcType == 3 then
				local adr = addr
				local mb = bit.band(self.memBank,getBits(#self.rom))
				if mb == 0 then mb = 1 end
				adr = addr + (0x4000*(mb-1))
				return self.rom[adr]
			elseif self.mbcType == 5 then
				local adr = addr
				local mb = bit.band(self.memBank,getBits(#self.rom))
				--if mb == 0 then mb = 1 end
				--print(mb)
				--print(self.cpu.PC)
				--error()
				adr = addr + (0x4000*(mb-1))
				return self.rom[adr]
			end
		elseif addr >=0x8000 and addr <= 0x9FFF then--gpu memory
			return self.gpu.vram[bit.band(addr,0x1FFF)]
		elseif addr >= 0xA000 and addr <= 0xBFFF then
			--MBC1 External ram
			--print("read from ram")
			if self.mbcType == 1 and self.eRamEnable then--todo MBC1 big roms
				--print("somethin")
				if not self.bigRom then
					--print("mode 0 read")
					return self.eRam[(addr-0xA000)]
				else
					--print("mode 1 ram read, retrning ",self.eRam[(addr-0xA000)+(self.ramBank*0x2000)],(addr-0xA000)+(self.ramBank*0x2000))
					return self.eRam[(addr-0xA000)+(self.ramBank*0x2000)]
				end
			elseif self.mbcType == 3 and self.eRamEnable then
				return self.eRam[(addr-0xA000)+(self.ramBank*0x2000)]--todo RTC
			elseif self.mbcType == 5 and self.eRamEnable then
				return self.eRam[(addr-0xA000)+(self.ramBank*0x2000)]
			else
				return 0xFF
			end--[[
			if self.eRamEnable then
				if self.rtcEn == 0x08 then--seconds
					return 30
				elseif self.rtcEn == 0x09 then--minutes
					return 5
				elseif self.rtcEn == 0x0A then--hours
					return 5
				elseif self.rtcEn == 0x0B then--day lower 8 bits
					return 100
				elseif self.rtcEn == 0x0C then--day higher 1 bit
					return 0
				elseif self.mbcType == 3 then
					return self.eRam[(addr-0xA000)+(self.ramBank*0x2000)]
				end
			end]]
		elseif addr >= 0xC000 and addr <= 0xDFFF then
			--print("from ram")
			pr(self.workingRam[addr-0xC000])
			return self.workingRam[addr-0xC000]
		elseif addr >= 0xE000 and addr <= 0xFDFF then--shadow
			--print("from ram copy")
			pr(self.workingRam[addr-0xE000])
			return self.workingRam[addr-0xE000]
		elseif addr >= 0xFE00 and addr <= 0xFE9F then--gpu OAM map
			return self.gpu.getOAM(addr)
		elseif addr >= 0xFF00 and addr <= 0xFF7F then--device flags
			if addr == 0xFF00 then--controler
				return self.joy.rb()
			elseif addr >= 0xFF01 and addr <= 0xFF02 then--serial
				if addr == 0xFF02 then
					return bit.bor(self.sc,0x7E) --0111110
				end
			elseif addr >= 0xFF04 and addr <= 0xFF07 then
				return self.timer.rb(addr)
			elseif addr == 0xFF0F then
				return bit.bor(self.intFlags,0xE0)
			elseif addr >= 0xFF10 and addr <= 0xFF3F then
				return 0 --stub, fix when impl audio
			elseif addr == 0xFF40 then--LCD control
				return self.gpu.lcdc
			elseif addr == 0xFF41 then
				return bit.bor(self.gpu.STAT,bit.band(self.gpu.lineMode,0x3))
			elseif addr == 0xFF42 then
				return self.gpu.scrollY
			elseif addr == 0xFF43 then
				return self.gpu.scrollX
			elseif addr == 0xFF44 then
				--return 0x90
				--print("read line",self.gpu.line,self.cpu.PC)
				return self.gpu.line
			elseif addr == 0xFF45 then
				return self.gpu.LYC
			elseif addr == 0xFF47 then
				return self.gpu.paletteb
			elseif addr == 0xFF48 then
				return self.gpu.obp0b
			elseif addr == 0xFF49 then
				return self.gpu.obp1b
			elseif addr == 0xFF4A then
				return self.gpu.winY
			elseif addr == 0xFF4B then
				return self.gpu.winX
			elseif addr == 0xFF4D then
				return 0xFF
			end
		elseif addr >= 0xFF80 and addr <= 0xFFFF then
			--print("from zero page")
			--pr(self.workingRam[addr-0xE000])
			return self.zeroPage[addr-0xFF80]
		end
		print(string.format("unhandled mmu read at address 0x%02x",addr))
		--error(string.format("unhandled mmu read at address 0x%02x",addr))
		return 0xff
	end




	function self.setByte(byte,addr)
		--print(string.format("set byte addr: 0x%x(%d) value: 0x%x(%d) PC: 0x%02x mb: %d",addr,addr,byte,byte,self.cpu.PC,self.memBank))
		if testing then
			self.testingram[addr] = byte
			return
		end
		if addr >= 0x0000 and addr <= 0x1FFF then--ram enable/disable
			--print("ram enable")
			if (self.mbcType == 3) or (self.mbcType == 1) or (self.mbcType == 5) then
				if bit.band(0x0F,byte) == 0x0A then
					--print("ram enable",byte)
					self.eRamEnable = true
				else
					--print("ram disabled")
					self.eRamEnable = false
				end
			end
			--print(addr,byte)
		elseif addr >= 0x2000 and addr <= 0x3FFF then --rom bank number
			--print("rom bank num")
			--print(addr,byte)
			if self.mbcType == 1 then
				self.memBank = bit.band(self.memBank,0x600) + bit.band(0x1F,byte)--mbc1
			elseif self.mbcType == 3 then
				--print("Set memory bank",bit.band(0x7F,byte),byte)
				self.memBank = bit.band(0x7F,byte)--mbc3
				--if self.memBank == 0 then self.memBank = 1 end--?
			elseif self.mbcType == 5  and addr <= 0x2FFF then
				self.memBank = bit.band(0xFF,byte)--mbc5
			elseif self.mbcType == 5  and addr >= 0x3000 then
				self.memBank = bit.bor(bit.band(self.memBank,0xFF),bit.lshift(bit.band(0x01,byte),8))--mbc5 upper bits
			end--mbc3
		elseif addr >= 0x4000 and addr <= 0x5FFF then --ram bank number BANK2
			--if byte ~=0 then error("not yet implemented") end
			if self.mbcType == 1 or self.mbcType == 5 then
				if self.bigRom then
					print("bigmode",byte)
					--print(self.memBank)
					--print("setting ram bank # ",byte)
					self.ramBank = bit.band(0x03,byte)
					--print(self.memBank)
					self.memBank = bit.bor(bit.band(self.memBank,0x1F),bit.lshift(bit.band(0x03,byte),5))--mbc1
				else
					self.ramBank = bit.band(0x03,byte)
					self.memBank = bit.bor(bit.band(self.memBank,0x1F),bit.lshift(bit.band(0x03,byte),5))--mbc1
				end
				if self.ramNum == 2 then
					self.ramBank = 0--we only have one ram page, don't do anything
				end
			elseif self.mbcType == 3 then
				if byte >= 0x08 and byte <= 0x0C then
					print("RTC bank num")
					print(addr,byte)
					self.rtcEn = byte
				else
					--print("RAM bank number")
					--print(bit.band(0x03,byte),byte)
					self.ramBank = bit.band(0x03,byte)
					self.rtcEn = 0
				end
			end
		elseif addr >= 0x6000 and addr <= 0x7FFF then
			if self.mbcType == 1 then
				if bit.band(byte,1) > 0 then
					self.bigRom = true
				else
					self.bigRom = false
				end
				--print("MBC1 banking mode changed to",byte)
				--if byte ~= 0 then error("MBC1 banking mode is not fully implemented") end
			elseif self.mbcType == 3 then
				--todo? RTC
				print("RTC written to")
			end
		elseif addr >= 0xA000 and addr <= 0xBFFF then
			if self.rtcEn > 0 then return end
			if self.mbcType == 3 and self.eRamEnable then
				self.eRam[(addr-0xA000)+(self.ramBank*0x2000)] = byte
			end
			if self.mbcType == 5 and self.eRamEnable then
				self.eRam[(addr-0xA000)+(self.ramBank*0x2000)] = byte
			end
			if self.mbcType == 1 and self.eRamEnable then
				if not self.bigRom then
					self.eRam[(addr-0xA000)] = byte
				else
					--print("mode 1 ram write",self.ramBank,addr)
					self.eRam[(addr-0xA000)+(self.ramBank*0x2000)] = byte
				end
			end
		elseif addr >= 0xC000 and addr <= 0xDFFF then
			--print("to ram")
			self.workingRam[addr-0xC000] = byte
		elseif addr >= 0xE000 and addr <= 0xFDFF then--shadow
			--print("to ram copy")
			self.workingRam[addr-0xE000] = byte
		elseif addr >= 0xFE00 and addr <= 0xFE9F then--gpu OAM map
			self.gpu.updateOAM(addr,byte)
		elseif addr >= 0xFEA0 and addr <= 0xFEFF then--prohibited
			--nothing
		elseif addr >= 0xFF00 and addr <= 0xFF7F then
			--print(byte,string.format("%02x",addr))
			if addr == 0xFF00 then--controler
				self.joy.wb(byte)
			elseif addr == 0xFF01 then
				--print("serial transfer byte set to")
				--print(byte,string.char(byte))
				--serialstr = serialstr..string.char(byte)
				--print(serialstr)
				--io.write(string.char(byte))
			elseif addr == 0xFF02 then
				--print("serial transfer control set to")
				--print(byte)
				self.sc = byte
			elseif addr >= 0xFF04 and addr <= 0xFF07 then
				self.timer.wb(byte,addr)
			elseif addr == 0xFF0F then
				--print(byte)
				self.intFlags = bit.band(byte,0x1F)
				if bit.band(self.getByte(0xFFFF),self.getByte(0xFF0F)) > 0 then
					self.ipend = true
				end
			elseif addr == 0xFF40 then--LCD
				if breaking then print(byte) end
				self.gpu.switchbg  = bit.band(byte,bit.lshift(1,0)) > 0
				self.gpu.objEnable = bit.band(byte,bit.lshift(1,1)) > 0
				self.gpu.objSize   = bit.band(byte,bit.lshift(1,2)) > 0
				self.gpu.bgmap     = bit.band(byte,bit.lshift(1,3)) > 0
				self.gpu.bgtile    = bit.band(byte,bit.lshift(1,4)) > 0
				self.gpu.winEnable = bit.band(byte,bit.lshift(1,5)) > 0
				self.gpu.winMap    = bit.band(byte,bit.lshift(1,6)) > 0
				self.gpu.switchlcd = bit.band(byte,bit.lshift(1,7)) > 0
				self.gpu.lcdc = byte
				print(self.gpu.frames,byte)
			elseif addr == 0xFF41 then--LCD STAT register
				self.gpu.STAT = bit.bor(bit.band(byte,0xFC),self.gpu.STAT)--bits 0-2 are read only
			elseif addr == 0xFF42 then
				self.gpu.scrollY = byte
			elseif addr == 0xFF43 then
				self.gpu.scrollX = byte
			elseif addr == 0xFF45 then--LYC: LY compare
				self.gpu.LYC = byte
			elseif addr == 0xFF46 then--OAM DMA write https://gbdev.io/pandocs/OAM_DMA_Transfer.html#oam-dma-transfer
				--todo DMA bus conflicts: cpu can only read from HRAM
				--print(string.format("0x%02x",bit.lshift(byte,8)))
				for i = 0,159 do
					local b = self.getByte(bit.lshift(byte,8)+i)
					self.setByte(b,0xFE00+i)
				end
			elseif addr == 0xFF47 then--bg pallete
				--print("palette",byte)
				self.gpu.paletteb = byte
				for i = 0,3 do
					local v = bit.band(bit.rshift(byte,i*2),3)
					if v == 0 then
						self.gpu.palette[i] = 1--white
					elseif v == 1 then
						self.gpu.palette[i] = 2--light gray
					elseif v == 2 then
						self.gpu.palette[i] = 3--dark gray
					elseif v == 3 then
						self.gpu.palette[i] = 4--black
					end
				end
			elseif addr == 0xFF48 then--ob0 pallete
				--print("palette 0",byte)
				self.gpu.obp0b = byte
				for i = 0,3 do
					local v = bit.band(bit.rshift(byte,i*2),3)
					if v == 0 then
						self.gpu.obp0[i] = 1--white
					elseif v == 1 then
						self.gpu.obp0[i] = 2--light gray
					elseif v == 2 then
						self.gpu.obp0[i] = 3--dark gray
					elseif v == 3 then
						self.gpu.obp0[i] = 4--black
					end
				end
				--printTable(self.gpu.obp0)
			elseif addr == 0xFF49 then--ob1 pallete
				--print("palette 1",byte)
				self.gpu.obp1b = byte
				for i = 0,3 do
					local v = bit.band(bit.rshift(byte,i*2),3)
					if v == 0 then
						self.gpu.obp1[i] = 1--white
					elseif v == 1 then
						self.gpu.obp1[i] = 2--light gray
					elseif v == 2 then
						self.gpu.obp1[i] = 3--dark gray
					elseif v == 3 then
						self.gpu.obp1[i] = 4--black
					end
				end
				--printTable(self.gpu.palette)
			elseif addr == 0xFF4A then--WY window y pos
				self.gpu.winY = byte
			elseif addr == 0xFF4B then--WX window x pos
				self.gpu.winX = byte
			elseif addr == 0xFF50 then--boot rom disable/enable
				self.inBootRom = byte
				--self.cpu.IME = 0
				--self.gpu.frames = -10
			end
		elseif addr >= 0xFF80 and addr <= 0xFFFE then
			--print("to zero page")
			self.zeroPage[addr-0xFF80] = byte
		elseif addr == 0xFFFF then
			if bit.band(self.getByte(0xFFFF),self.getByte(0xFF0F)) > 0 then
				self.ipend = true
			end
			self.zeroPage[addr-0xFF80] = byte
		elseif addr >= 0x8000 and addr <= 0x9FFF then--gpu memory
			self.gpu.vram[bit.band(addr,0x1FFF)] = byte
			if addr <= 0x97ff then
				self.gpu.updateTile(addr,byte)
			end
		else
			print(string.format("unhandled mmu write at address 0x%02x value: 0x%02x",addr,byte))
			error()
		end
	end
	function self.getSignedByte(addr,signExtend)
		--account for 2's compliment
		local byte = self.getByte(addr)
		if bit.band(byte,0x80) > 0 then
			byte = -(bit.band(bit.bnot(byte),0xFF)+1)
		end
		--sign extend

		return byte
	end

	self.reset()

	return self
end

return mmu
