local function mmu(file)
	local self = {}
	
	local bios = {}
	local serialstr = ""
	function self.reset()
		self.workingRam = {}--C000-DFFF/E000-FDFF
		self.zeroPage = {}--FF80-FFFF
		self.romBank0 = {}--0000-3FFF
		self.romBank1 = {}--4000-7FFF
		self.mbcType = 0
		self.ipend = false
		
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

		if not file then error("no rom to load") end
		local romFile = io.open(file,"rb")
		if not romFile then error("could not open rom") end
		local str = romFile:read("*a")
		--local str,size = love.filesystem.read(file)
		--if not str then
		--	error("could not open rom")
		--end
		self.rom = {}
		for i = 1,#str do
			--if i-1 == 0x4244 then print(string.byte(str:sub(i,i))) end
			self.rom[i-1] = string.byte(str:sub(i,i))
		end
		
		
		for i = 0x0000,0x3FFF do
			self.romBank0[i] = self.rom[i]
		end
		if self.mbcType == 0 then
			for i = 0x4000,0x7FFF do
				self.romBank1[i] = self.rom[i]
			end
		end
		self.inBootRom = 0
		self.intFlags = 0
	end

	function self.getByte(addr)
		--print(string.format("get byte addr: 0x%x(%d)",addr,addr))
		local function pr(num)
			--print(string.format("returned value: 0x%x(%d)",num,num))
		end
		if addr >= 0x00 and addr < 0x100 then
			--accessing bios
			--print("get byte ",addr,bios[addr])
			--print("from bios")
			--pr(bios[addr])
			if self.inBootRom == 0 then
				return bios[addr]
			else
				return self.romBank0[addr]
			end
		elseif addr >= 0x0000 and addr <= 0x3FFF then
			--print("get byte ",addr,rom[addr-0x100])
			--print("from rom")
			pr(self.romBank0[addr])
			return self.romBank0[addr]
		elseif addr >= 0x4000 and addr <= 0x7FFF then
			if self.mbcType == 0 then 
				return self.romBank1[addr]
			end
		elseif addr >=0x8000 and addr <= 0x9FFF then--gpu memory
			return self.gpu.vram[bit.band(addr,0x1FFF)]
		elseif addr >= 0xC000 and addr <= 0xDFFF then
			--print("from ram")
			pr(self.workingRam[addr-0xC000])
			return self.workingRam[addr-0xC000]
		elseif addr >= 0xE000 and addr <= 0xFDFF then--shadow
			--print("from ram copy")
			pr(self.workingRam[addr-0xE000])
			return self.workingRam[addr-0xE000]
		elseif addr >= 0xFF00 and addr <= 0xFF7F then--device flags
			if addr == 0xFF00 then--controler
				return self.joy.rb()
			elseif addr >= 0xFF04 and addr <= 0xFF07 then
				return self.timer.rb(addr)
			elseif addr == 0xFF0F then
				return self.intFlags
			elseif addr == 0xFF40 then--LCD control
				local val = 0
				val = val + (self.gpu.switchbg and 1 or 0)
				val = val + (self.gpu.bgmap and 8 or 0)
				val = val + (self.gpu.bgtile and 16 or 0)
				val = val + (self.gpu.switchlcd and 128 or 0)
				return val
			elseif addr == 0xFF42 then
				return self.gpu.scrollY
			elseif addr == 0xFF43 then
				return self.gpu.scrollX
			elseif addr == 0xFF44 then
				--return 0x90
				return self.gpu.line
			end
		elseif addr >= 0xFF80 and addr <= 0xFFFF then
			--print("from zero page")
			--pr(self.workingRam[addr-0xE000])
			return self.zeroPage[addr-0xFF80]
		end
		return 0
	end
	function self.setByte(byte,addr)
		--print(string.format("set byte addr: 0x%x(%d) value: 0x%x(%d)",addr,addr,byte,byte))
		if addr >= 0xC000 and addr <= 0xDFFF then
			--print("to ram")
			if addr == 0xDD02 then
				--error (self.cpu.PC)
			end
			self.workingRam[addr-0xC000] = byte
		elseif addr >= 0xE000 and addr <= 0xFDFF then--shadow
			--print("to ram copy")
			self.workingRam[addr-0xE000] = byte
		elseif addr >= 0xFE00 and addr <= 0xFE9F then--gpu OAM map
			self.gpu.updateOAM(addr,byte)
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
			elseif addr >= 0xFF04 and addr <= 0xFF07 then
				self.timer.wb(byte,addr)
			elseif addr == 0xFF0F then
				--print(byte)
				self.intFlags = byte
				if bit.band(self.getByte(0xFFFF),self.getByte(0xFF0F)) > 0 then
					self.ipend = true
				end
			elseif addr == 0xFF40 then--LCD
				self.gpu.switchbg  = bit.band(byte,bit.lshift(1,0)) > 0
				self.gpu.bgmap     = bit.band(byte,bit.lshift(1,3)) > 0
				self.gpu.bgtile    = bit.band(byte,bit.lshift(1,4)) > 0
				self.gpu.winEnable = bit.band(byte,bit.lshift(1,5)) > 0
				self.gpu.switchlcd = bit.band(byte,bit.lshift(1,7)) > 0
			elseif addr == 0xFF42 then
				self.gpu.scrollY = byte
			elseif addr == 0xFF43 then
				self.gpu.scrollX = byte
			elseif addr == 0xFF46 then--OAM DMA write https://gbdev.io/pandocs/OAM_DMA_Transfer.html#oam-dma-transfer
				--todo DMA bus conflicts: cpu can only read from HRAM
				for i = 0,159 do
					local b = self.getByte(bit.lshift(byte,8)+i)
					self.setByte(b,0xFE00+i)
				end
			elseif addr == 0xFF47 then--bg pallete
				--print("palette",byte)
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
				print("palette 0",byte)
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
				printTable(self.gpu.obp0)
			elseif addr == 0xFF49 then--ob1 pallete
				print("palette 1",byte)
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
			elseif addr == 0xFF50 then--boot rom disable/enable
				self.inBootRom = byte
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
