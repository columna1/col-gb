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
	for i, v in pairs(tabl) do
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

local function CPU(testing, state, filename)
	local f = io.open("dmgops.json", "r")
	local d = f:read("*a")
	f:close()
	jdataP = json.decode(d).CBPrefixed
	jdataU = json.decode(d).Unprefixed
	--printTable(jdata.Unprefixed)

	local self = {}
	local mem = {}
	if filename then
		mem = mmu(filename)
	else
		mem = mmu("roms/mbctest.gb") --idk
	end
	local cycles = 0
	if testing then
		mem = mmu("", true, state.ram)
	end
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

		if testing then
			self.A = state.a
			self.B = state.b
			self.C = state.c
			self.D = state.d
			self.E = state.e
			self.H = state.h
			self.L = state.l
			self.F = state.f
			self.SP = state.sp
			self.PC = state.pc
			self.IME = state.ime
			self.instructionsExecuted = state.ie
		end
	end

	self.instsran = {}
	function self.executeInstruction()
		--local pr = print
		--if not p then
		--print = function() end
		--end
		--print("-------fetch inst--------")
		local pcb4 = self.PC
		if not self.HALT then
			local inst = mem.getByte(self.PC) + 1
			--print()
			--print("executing")
			--print("0x"..string.format("%x",inst-1))
			--print(inst-1)
			self.PC = self.PC + 1
			if inst - 1 == 0xcb then
				inst2 = mem.getByte(self.PC) + 1
				self.instsran[inst2 - 1] = true
				--print(jdataP[inst2].Name)
				--print("-------------------------")
				--print("\t0x"..string.format("%x",inst2-1))
				self.PC = self.PC + 1
				if instructionsCB[inst2] then
					instructionsCB[inst2]()
					if self.A == nil then print("nil ext", inst2) end
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
			if self.A == nil then
				print(self.A, self.PC, pcb4, inst, inst2); error("reg A is nil")
			end
		else
			cycles = cycles + 16
			if bit.band(self.mem.getByte(0xFFFF), self.mem.getByte(0xFF0F)) > 0 then
				self.HALT = false
			end
			--print("halt INC "..self.cycles)
		end
		if self.IME then
			if self.mem.ipend then --see if there is an interupt to process
				--self.mem.ipend = false
				local IE = self.mem.getByte(0xFFFF)
				local IF = self.mem.getByte(0xFF0F)
				if bit.band(bit.band(IE, 1), bit.band(IF, 1)) > 0 then --vblank
					--print("vblank interupt called")
					self.IME = false
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F), 0xFE), 0xFF0F)
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					self.SP = self.SP - 2
					self.mem.setByte(bit.band(self.PC, 0xFF), self.SP)
					self.mem.setByte(bit.band(bit.rshift(self.PC, 8), 0xFF), self.SP + 1);
					self.PC = 0x40; cycles = cycles + 16 --[199 0xc7]
					self.HALT = false
					cycles = cycles + 4
				elseif bit.band(bit.band(IE, 2), bit.band(IF, 2)) > 0 then --LCD STAT
					if breaking then
						running = false
						print("STAT interrupt at gpu line " .. self.gpu.line, self.gpu.LYC,
							string.format("0x%02x    0x%02x", self.gpu.LYC, self.mem.getByte(0xFF41)))
					end
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F), 0xFD), 0xFF0F)
					self.IME = false
					self.SP = self.SP - 2;
					self.mem.setByte(bit.band(self.PC, 0xFF), self.SP);
					self.mem.setByte(bit.band(bit.rshift(self.PC, 8), 0xFF), self.SP + 1);
					self.PC = 0x48; cycles = cycles + 16 --[199 0xc7]
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					cycles = cycles + 4
					self.HALT = false
				elseif bit.band(bit.band(IE, 4), bit.band(IF, 4)) > 0 then --Timer
					self.IME = false
					self.mem.setByte(bit.band(mem.getByte(0xFF0F), 0xFB), 0xFF0F)
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					self.SP = self.SP - 2; self.mem.setByte(bit.band(self.PC, 0xFF), self.SP); self.mem.setByte(
						bit.band(bit.rshift(self.PC, 8), 0xFF), self.SP + 1); self.PC = 0x50; cycles = cycles +
						16 --[199 0xc7]
					self.HALT = false
					--print("timer interupt called")
					cycles = cycles + 4
				elseif bit.band(bit.band(IE, 8), bit.band(IF, 8)) > 0 then --Serial
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F), 0xF7), 0xFF0F)
					self.IME = false
					self.SP = self.SP - 2; self.mem.setByte(bit.band(self.PC, 0xFF), self.SP); self.mem.setByte(
						bit.band(bit.rshift(self.PC, 8), 0xFF), self.SP + 1); self.PC = 0x58; cycles = cycles +
						16 --[199 0xc7]
					if self.mem.getByte(0xFF0F) == 0 then self.mem.ipend = false end
					cycles = cycles + 4
					--print("handling serial interupt")
					self.HALT = false
				elseif bit.band(bit.band(IE, 16), bit.band(IF, 16)) > 0 then --Joypad
					self.mem.setByte(bit.band(self.mem.getByte(0xFF0F), 0xEF), 0xFF0F)
					self.IME = false
					self.SP = self.SP - 2; self.mem.setByte(bit.band(self.PC, 0xFF), self.SP); self.mem.setByte(
						bit.band(bit.rshift(self.PC, 8), 0xFF), self.SP + 1); self.PC = 0x60; cycles = cycles +
						16 --[199 0xc7]
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

		local cyclesDT = cycles - self.cycles
		self.cycles = cycles
		self.instructionsExecuted = self.instructionsExecuted + 1
		self.gpu.updateLine(cyclesDT)
		self.timer.update(cyclesDT)
	end

	function self.runInstruction(inst)
		print("Ruinning 0x" .. string.format("%x", inst))
		if instructions[inst + 1] then
			instructions[inst + 1]()
		else
			--error("unimplemented instruction: "..inst.." 0x"..string.format("%x",inst).."")
			print("no instruction")
		end
	end

	self.reset()
	return self
end

return CPU
