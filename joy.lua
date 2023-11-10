local function joy()
	local self = {}
	
	function self.reset()
		self.bank = 0
		self.buttons = {}
		--0 means buttons is pressed
		self.buttons.A = 1
		self.buttons.B = 1
		self.buttons.Start = 1
		self.buttons.Select = 1
		self.buttons.Left = 1
		self.buttons.Right = 1
		self.buttons.Up = 1
		self.buttons.Down = 1
	end
	
	function self.wb(b)
		--print("bank selected")
		self.bank = bit.band(b,0x30)
		--print(self.bank)
	end
	
	function self.rb()
		if self.bank == 0x20 then
			local b =  bit.bor(self.bank,0xC0)--match bgb
			b = b +            self.buttons.Right
			b = b + bit.lshift(self.buttons.Left,1)
			b = b + bit.lshift(self.buttons.Up,2)
			b = b + bit.lshift(self.buttons.Down,3)
			return b
		elseif self.bank == 0x10 then
			local b =  bit.bor(self.bank,0xC0)
			b = b +            self.buttons.A
			b = b + bit.lshift(self.buttons.B,1)
			b = b + bit.lshift(self.buttons.Select,2)
			b = b + bit.lshift(self.buttons.Start,3)
			return b
		else
			return 0x0F
		end
	end
	self.reset()
	return self
end

return joy
