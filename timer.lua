local function timer()
	local self = {}

	function self.reset()
		self.clock = 0
		self.lastBit = 0
		self.rc = false
		self.irq = 0
		self.TAC = 0
		self.TMA = 0
		self.TIMA = 0
	end

	--todo If a TMA write is executed on the same cycle as the content of TMA is transferred to TIMA due to a timer overflow, the old value is transferred to TIMA.

	function self.inc()
		self.rc = false
		if self.irq > 0 then
			self.irq = self.irq - 1
			if self.irq == 0 then
				self.mmu.setByte(bit.bor(self.mmu.getByte(0xFF0F),4),0xFF0F)
				self.TIMA = self.TMA
				self.rc = true
			end
		end
		self.updateClock(bit.band(self.clock+1,0xFFFF))
	end

	function self.updateClock(c)
		self.clock = c
		local thisBit = 0
		local s = bit.band(self.TAC,3)
		if s == 0 then thisBit = bit.band(bit.rshift(self.clock,9),1) end
		if s == 3 then thisBit = bit.band(bit.rshift(self.clock,7),1) end
		if s == 2 then thisBit = bit.band(bit.rshift(self.clock,5),1) end
		if s == 1 then thisBit = bit.band(bit.rshift(self.clock,3),1) end
		thisBit = bit.band(thisBit,bit.rshift(bit.band(self.TAC,4),2))
		self.detectEdge(self.lastBit,thisBit)
		self.lastBit = thisBit
	end

	function self.update(dt)
		for i = 1,dt do
			self.inc()
		end
	end

	function self.wb(b,a)
		if a == 0xFF04 then
			self.updateClock(0)
		end
		if a == 0xFF05 then
			if not self.rc then self.TIMA=b end
			if self.irq == 1 then self.irq = 0 end
		end
		if a == 0xFF06 then
			if self.rc then self.TIMA = b end
			self.TMA = b
		end
		if a == 0xFF07 then
			local lastBit = self.lastBit
			self.lastBit = bit.band(self.lastBit,bit.rshift(bit.band(b,4),2))
			self.detectEdge(lastBit,self.lastBit)
			self.TAC = b
		end
	end

	function self.detectEdge(b,a)
		if (b == 1) and (a == 0) then
			self.TIMA = bit.band(self.TIMA+1,0xFF)
			if self.TIMA == 0 then
				self.irq = 1
			end
		end
	end

	function self.rb(b)
		--print("read",b)
		if b == 0xFF04 then
			return bit.band(bit.rshift(self.clock,8),0xFF)
		end
		if b == 0xFF05 then
			return self.TIMA
		end
		if b == 0xFF06 then
			return self.TMA
		end
		if b == 0xFF07 then
			return bit.bor(self.TAC,0xF8)
		end
	end
	self.reset()
	return self
end

return timer
