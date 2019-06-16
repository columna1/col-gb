local mmu = require("mmu")
local json = require("cjson")

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
	
	local self = {
		--registers
		A = 0,
		B = 0,
		C = 0,
		D = 0,
		E = 0,
		H = 0,
		L = 0,
		F = 0,
		SP = 0,
		PC = 0,
		cycles = 0,
		mem = {}
	}
	cycles = 0
	local mem = mmu("Tetris.gb")
	self.mem = mem
	--local instructions = {}
	--$instructions$
	
	--$instructionsCB$
	
	function self.executeInstruction(p)
		local pr = print
		if not p then
			print = function() end
		end
		print("-------fetch inst--------")
		local inst = mem.getByte(self.PC)+1
		print("0x"..string.format("%x",inst-1))
		self.PC = self.PC + 1
		if inst-1 == 0xcb then
			inst2 = mem.getByte(self.PC)+1
			print(jdataP[inst2].Name)
			print("-------------------------")
			print("\t0x"..string.format("%x",inst2-1))
			self.PC = self.PC + 1
			if instructionsCB[inst2] then
				instructionsCB[inst2]()
			else
				--error("unimplemented instruction: "..inst.." 0x"..string.format("%x",inst).."")
				print("no instruction")
			end	
		else
			print(jdataU[inst].Name)
			print("-------------------------")
			if instructions[inst] then
				instructions[inst]()
			else
				--error("unimplemented instruction: "..inst.." 0x"..string.format("%x",inst).."")
				print("no instruction")
			end
		end
		print = pr
		self.cycles = cycles
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
	
	--[[instructions = {
		[0 ] = function() cycles = cycles + 4 end,--no-op
		[33] = function() cycles = cycles + 12 ; self.H = mem.getByte(self.PC); self.L = mem.getByte(self.PC+1) ; self.PC = self.PC + 2 end,
		[49] = function() cycles = cycles + 4 ; self.SP = mem.getByte(self.PC)+bit.lshift(mem.getByte(self.PC+1),8) ; self.PC = self.PC + 2 end,
		[175] = function() cycles = cycles + 4 ; self.A = bit.bxor(self.A,self.A) end
	}]]
	
	return self
end

return CPU