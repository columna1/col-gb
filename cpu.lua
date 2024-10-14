local mmu = require("mmu")
local gpu = require("gpu")
local json = require("json")
local joy = require("joy")
local timer = require("timer")
--local json = require("cjson")

--[[
possible small optimization,
flag register is just a few booleans
combine them when accessed, this would save
on binary operations every instruction
]]

function printTable(tabl, wid)
	if not wid then wid = 1 end
	for i,v in pairs(tabl) do
		if type(v) == "table" then
			print(string.rep(" ", wid * 3) .. i .. " = {")
			printTable(v, wid + 1)
			print(string.rep(" ", wid * 3) .. "}")
		elseif type(v) == "string" then
			print(string.rep(" ", wid * 3) .. i .. " = \"" .. v .. "\"")
		elseif type(v) == "number" then
			print(string.rep(" ", wid * 3) .. i .. " = " .. v)
		end
	end
end

local function CPU()
	local f = io.open("dmgops.json","r")
	local d = f:read("*a")
	f:close()
	jdataP = json.decode(d).CBPrefixed
	jdataU = json.decode(d).Unprefixed
	--printTable(jdata.Unprefixed)

	local self = {}
	--local mem = mmu("tobu.gb")
	--local mem = mmu("Tetris.gb")
	--local mem = mmu("Chessmaster.gb")
	--local mem = mmu("Tetris (patched).gb")
	--local mem = mmu("Tetris (patched) (patched).gb")
	--local mem = mmu("2048-gb/2048.gb")
	--local mem = mmu("Dr. Mario (World).gb")
	local mem = mmu("Super Mario Land (World).gb")
	--local mem = mmu("Asteroids (USA, Europe).gb")
	--local mem = mmu("Pokemon - Blue Version (USA, Europe) (SGB Enhanced).gb")
	--local mem = mmu("hanoi.gb")
	--local mem = mmu("dmg-acid2.gb")
	--local mem = mmu("Ranma 1-2 (Japan).gb")
	--local mem = mmu("Space Invaders (Japan).gb")
	local cycles = 0
	--local mem = mmu("blarg-cpu-inst/individual/01-special.gb")
	--local mem = mmu("blarg-cpu-inst/individual/02-interrupts.gb")
	--local mem = mmu("blarg-cpu-inst/individual/03-op sp,hl.gb")
	--local mem = mmu("blarg-cpu-inst/individual/04-op r,imm.gb")
	--local mem = mmu("blarg-cpu-inst/individual/05-op rp.gb")
	--local mem = mmu("blarg-cpu-inst/individual/06-ld r,r.gb")
	--local mem = mmu("blarg-cpu-inst/individual/07-jr,jp,call,ret,rst.gb")
	--local mem = mmu("blarg-cpu-inst/individual/08-misc instrs.gb")
	--local mem = mmu("blarg-cpu-inst/individual/09-op r,r.gb")
	--local mem = mmu("blarg-cpu-inst/individual/10-bit ops.gb")
	--local mem = mmu("blarg-cpu-inst/individual/11-op a,(hl).gb")
	--local mem = mmu("blarg-cpu-inst/cpu_instrs.gb")
	--local mem = mmu("gb-test-roms/instr_timing/instr_timing.gb")
	--local mem = mmu("blarg-cpu-inst/interrupt_time.gb")
	--local mem = mmu("mts/acceptance/timer/rapid_toggle.gb")
	--local mem = mmu("mts/acceptance/timer/div_write.gb")
	--local mem = mmu("mts/acceptance/timer/tim00.gb")
	--local mem = mmu("mts/acceptance/timer/tim01.gb")
	--local mem = mmu("mts/acceptance/timer/tim10.gb")
	--local mem = mmu("mts/acceptance/timer/tim11.gb")
	--local mem = mmu("mts/acceptance/timer/tim00_div_trigger.gb")
	--local mem = mmu("mts/acceptance/timer/tim01_div_trigger.gb")
	--local mem = mmu("mts/acceptance/timer/tim10_div_trigger.gb")
	--local mem = mmu("mts/acceptance/timer/tim11_div_trigger.gb")
	--local mem = mmu("mts/acceptance/timer/tima_reload.gb")
	--local mem = mmu("mts/acceptance/timer/tima_write_reloading.gb")
	--local mem = mmu("mts/acceptance/timer/tma_write_reloading.gb")
	--local mem = mmu("mts/acceptance/intr_timing.gb")
	--local mem = mmu("mts/acceptance/ppu/stat_irq_blocking.gb")
	self.mem = mem
	local gpu = gpu()
	local joy = joy()
	local timer = timer()
	self.gpu = gpu
	self.joy = joy
	self.timer = timer
	--self.mem.cpu = self
	self.gpu.mmu = mem
	self.timer.mmu = mem
	self.mem.timer = timer
	self.mem.gpu = gpu
	self.mem.joy = joy
	
	--$instructions$

	--$instructionsCB$

	function self.reset()
		--registers
		self.A = 0
		self.B = 0
		self.C = 0
		self.D = 0
		self.E = 0
		self.H = 0
		self.L = 0
		self.F = 0
		self.SP = 0
		self.PC = 0
		self.cycles = 0
		self.HALT = false
		self.instructionsExecuted = 0
		self.IME = true
		self.mem.reset()
		self.gpu.reset()
		self.timer.reset()

		self.outOfBoot = false
		cycles = 0
	end
	self.instsran = {}
	function self.executeInstruction(p)
		--local pr = print
		--if not p then
			--print = function() end
		--end
		--print("-------fetch inst--------")
		local pcb4 = self.PC
		if not self.HALT then
			local inst = mem.getByte(self.PC)+1
			--print("0x"..string.format("%x",inst-1))
			self.PC = self.PC + 1
			if inst-1 == 0xcb then
				inst2 = mem.getByte(self.PC)+1
				self.instsran[inst2-1] = true
				--print(jdataP[inst2].Name)
				--print("-------------------------")
				--print("\t0x"..string.format("%x",inst2-1))
				self.PC = self.PC + 1
				if instructionsCB[inst2] then
					instructionsCB[inst2]()
					if self.A == nil then print("nil ext",inst2) end
				else
					--error("unimplemented instruction: "..inst.." 0x"..string.format("%x",inst).."")
					--print("no instruction")
				end
			else
				--print(jdataU[inst].Name)
				--print("-------------------------")
				if instructions[inst] then
					--if self.A == nil then print("nil before",inst) end
					--print(self.A)
					instructions[inst]()
					--if self.A == nil then print("nil after",inst,self.H,self.L,(lshift(self.H,8)+self.L),mem.getByte((lshift(self.H,8)+self.L))) end
				else
					--error("unimplemented instruction: "..inst.." 0x"..string.format("%x",inst).."")
					--print("no instruction")
				end
			end
			if self.A == nil then print(self.A,self.PC,pcb4,inst,inst2) ; error("reg A is nil") end
		else
			cycles = cycles + 16
			if bit.band(self.mem.getByte(0xFFFF),self.mem.getByte(0xFF0F)) > 0 then
				self.HALT = false
			end
			--print("halt INC "..self.cycles)
		end
		if self.IME then
			if self.mem.ipend then--see if there is an interupt to process
				--self.mem.ipend = false
				if bit.band(bit.band(self.mem.getByte(0xFFFF),1),bit.band(self.mem.getByte(0xFF0F),1)) > 0 then--vblank
					--print("vblank interupt called")
					self.IME = false
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F),0xFE),0xFF0F)
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					self.SP = self.SP-2
					self.mem.setByte(bit.band(self.PC,0xFF),self.SP)
					self.mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ;
					self.PC = 0x40; cycles = cycles + 16 --[199 0xc7]
					self.HALT = false
					cycles = cycles + 4
				elseif bit.band(bit.band(self.mem.getByte(0xFFFF),2),bit.band(self.mem.getByte(0xFF0F),2)) > 0 then--LCD STAT
					if breaking then
						running = false
						print("STAT interrupt at gpu line "..self.gpu.line,self.gpu.LYC,string.format("0x%02x    0x%02x",self.gpu.LYC,self.mem.getByte(0xFF41)))
					end
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F),0xFD),0xFF0F)
					self.IME = false
					self.SP = self.SP-2  ;
					self.mem.setByte(bit.band(self.PC,0xFF),self.SP) ;
					self.mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ;
					self.PC = 0x48; cycles = cycles + 16 --[199 0xc7]
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					cycles = cycles + 4
					self.HALT = false
				elseif bit.band(bit.band(self.mem.getByte(0xFFFF),4),bit.band(self.mem.getByte(0xFF0F),4)) > 0 then--Timer
					self.IME = false
					self.mem.setByte(bit.band(mem.getByte(0xFF0F),0xFB),0xFF0F)
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					self.SP = self.SP-2  ;self.mem.setByte(bit.band(self.PC,0xFF),self.SP) ; self.mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 0x50; cycles = cycles + 16 --[199 0xc7]
					self.HALT = false
					--print("timer interupt called")
					cycles = cycles + 4
				elseif bit.band(bit.band(self.mem.getByte(0xFFFF),8),bit.band(self.mem.getByte(0xFF0F),8)) > 0 then--Serial
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F),0xF7),0xFF0F)
					self.IME = false
					self.SP = self.SP-2  ; self.mem.setByte(bit.band(self.PC,0xFF),self.SP) ; self.mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 0x58; cycles = cycles + 16 --[199 0xc7]
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					cycles = cycles + 4
					--print("handling serial interupt")
					self.HALT = false
				elseif bit.band(bit.band(self.mem.getByte(0xFFFF),16),bit.band(self.mem.getByte(0xFF0F),16)) > 0 then--Joypad
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F),0xEF),0xFF0F)
					self.IME = false
					self.SP = self.SP-2  ;self.mem.setByte(bit.band(self.PC,0xFF),self.SP) ; self.mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 0x60; cycles = cycles + 16 --[199 0xc7]
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					cycles = cycles + 4
					self.HALT = false
				end
			end
		end
		--print = pr
		if not self.outOfBoot then
			if self.PC == 0x100 then
				self.outOfBoot = true
				self.IME = false
			end
		end

		local cyclesDT = cycles-self.cycles
		self.cycles = cycles
		self.instructionsExecuted = self.instructionsExecuted + 1
		self.gpu.updateLine(cyclesDT)
		self.timer.update(cyclesDT)
	end

	function self.runInstruction(inst)
		print("Ruinning 0x"..string.format("%x",inst))
		if instructions[inst+1] then
			instructions[inst+1]()
		else
			--error("unimplemented instruction: "..inst.." 0x"..string.format("%x",inst).."")
			print("no instruction")
		end
	end
	self.reset()
	return self
end

return CPU
