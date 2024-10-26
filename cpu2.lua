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
	self.mem.cpu = self
	self.gpu.mmu = mem
	self.timer.mmu = mem
	self.mem.timer = timer
	self.mem.gpu = gpu
	self.mem.joy = joy

	bor = bit.bor
band = bit.band
xor = bit.bxor
lshift = bit.lshift
rshift = bit.rshift

instructions =  {
function() cycles = cycles + 4 end,--no-op [0]
function() self.C = mem.getByte(self.PC) ; self.B = mem.getByte(self.PC+1); cycles = cycles + 12; self.PC = self.PC+ 2 end,--[1 0x1]
function() mem.setByte(self.A,(self.C+lshift(self.B,8))); cycles = cycles + 8 end,--[2 0x2]
function()  local temp = (lshift(self.B,8)+self.C) ;temp = temp+1; temp = bit.band(temp,0xFFFF) ; self.B = rshift(band(temp,0xFF00),8) ; self.C = band(temp,0xFF); cycles = cycles + 8 end,--[3 0x3]
function() self.F = (band(band(self.B,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.B = self.B +  1; self.B = bit.band(self.B,0xFF) ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[4 0x4]
function() self.F = (band(band(self.B,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.B = self.B- 1  ;self.B = bit.band(self.B,0xFF) ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bor(self.F,0x40); cycles = cycles + 4 end,--[5 0x5]
function() self.B = mem.getByte(self.PC) ; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[6 0x6]
function()  local temp = band(self.A, 128)  >0  and 1 or 0  ;self.A = lshift(self.A, 1)  ; self.F = ((band(self.A, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.A = self.A + temp ; self.A = bit.band(self.A,0xFF) ; self.F = band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[7 0x7]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) ;mem.setByte(band(self.SP,0xFF),temp) ;mem.setByte(rshift(band(self.SP,0xFF00),8),temp+1); cycles = cycles + 20; self.PC = self.PC+ 2 end,--[8 0x8]
function()  local temp = (lshift(self.H,8)+self.L)+(lshift(self.B,8)+self.C) ; self.F = (band((lshift(self.H,8)+self.L),0xFFF )+band((lshift(self.B,8)+self.C),0xFFF ) > 0xFFF ) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band((lshift(self.H,8)+self.L),0xFFFF)+band((lshift(self.B,8)+self.C),0xFFFF) > 0xFFFF) and bor(self.F,0x10) or band(self.F,0xEF) ; temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[9 0x9]
function() self.A = mem.getByte((self.C+lshift(self.B,8))); cycles = cycles + 8 end,--[10 0xa]
function()  local temp = (lshift(self.B,8)+self.C) ;temp = temp-1  ;temp = bit.band(temp,0xFFFF) ; self.B = rshift(band(temp,0xFF00),8) ; self.C = band(temp,0xFF); cycles = cycles + 8 end,--[11 0xb]
function() self.F = (band(band(self.C,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.C = self.C +  1; self.C = bit.band(self.C,0xFF) ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[12 0xc]
function() self.F = (band(band(self.C,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.C = self.C- 1  ;self.C = bit.band(self.C,0xFF) ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bor(self.F,0x40); cycles = cycles + 4 end,--[13 0xd]
function() self.C = mem.getByte(self.PC) ; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[14 0xe]
function() temp = band(self.A, 1)  ;self.A = rshift(self.A, 1)  ;if temp >  0 then self.A = self.A + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[15 0xf]
function()  self.HALT = true; cycles = cycles + 4 end,--[16 0x10]
function() self.E = mem.getByte(self.PC) ; self.D = mem.getByte(self.PC+1); cycles = cycles + 12; self.PC = self.PC+ 2 end,--[17 0x11]
function() mem.setByte(self.A,(self.E+lshift(self.D,8))); cycles = cycles + 8 end,--[18 0x12]
function()  local temp = (lshift(self.D,8)+self.E) ;temp = temp+1; temp = bit.band(temp,0xFFFF) ; self.D = rshift(band(temp,0xFF00),8) ; self.E = band(temp,0xFF); cycles = cycles + 8 end,--[19 0x13]
function() self.F = (band(band(self.D,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.D = self.D +  1; self.D = bit.band(self.D,0xFF) ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[20 0x14]
function() self.F = (band(band(self.D,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.D = self.D- 1  ;self.D = bit.band(self.D,0xFF) ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bor(self.F,0x40); cycles = cycles + 4 end,--[21 0x15]
function() self.D = mem.getByte(self.PC); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[22 0x16]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.A = lshift(self.A, 1)  ; self.F = ((band(self.A, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.A = bor(self.A,temp) ; self.A = bit.band(self.A,0xFF) ; self.F = band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[23 0x17]
function() self.PC = self.PC + mem.getSignedByte(self.PC) ; self.PC = bit.band(self.PC,0xFFFF); cycles = cycles + 12; self.PC = self.PC+ 1 end,--[24 0x18]
function()  local temp = (lshift(self.H,8)+self.L)+(lshift(self.D,8)+self.E) ; self.F = (band((lshift(self.H,8)+self.L),0xFFF )+band((lshift(self.D,8)+self.E),0xFFF ) > 0xFFF ) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band((lshift(self.H,8)+self.L),0xFFFF)+band((lshift(self.D,8)+self.E),0xFFFF) > 0xFFFF) and bor(self.F,0x10) or band(self.F,0xEF) ; temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[25 0x19]
function() self.A = mem.getByte((self.E+lshift(self.D,8))); cycles = cycles + 8 end,--[26 0x1a]
function()  local temp = (lshift(self.D,8)+self.E) ;temp = temp-1  ;temp = bit.band(temp,0xFFFF) ; self.D = rshift(band(temp,0xFF00),8) ; self.E = band(temp,0xFF); cycles = cycles + 8 end,--[27 0x1b]
function() self.F = (band(band(self.E,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.E = self.E +  1; self.E = bit.band(self.E,0xFF) ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[28 0x1c]
function() self.F = (band(band(self.E,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.E = self.E- 1  ;self.E = bit.band(self.E,0xFF) ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bor(self.F,0x40); cycles = cycles + 4 end,--[29 0x1d]
function() self.E = mem.getByte(self.PC) ; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[30 0x1e]
function() temp = band(self.A, 1)  ;self.A = rshift(self.A, 1)  ;tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.A = self.A + temp ; self.F = band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[31 0x1f]
function() if (band(self.F,0x80) == 0) then self.PC = self.PC + mem.getSignedByte(self.PC)  ; cycles = cycles +  4 end; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[32 0x20]
function() self.L = mem.getByte(self.PC) ; self.H = mem.getByte(self.PC+1); cycles = cycles + 12; self.PC = self.PC+ 2 end,--[33 0x21]
function()  local temp = (lshift(self.H,8)+self.L) ; mem.setByte(self.A,temp) ; temp = temp+1  ;temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF) ; cycles = cycles + 8 end,--[34 0x22]
function()  local temp = (lshift(self.H,8)+self.L) ;temp = temp+1; temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF); cycles = cycles + 8 end,--[35 0x23]
function() self.F = (band(band(self.H,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.H = self.H +  1; self.H = bit.band(self.H,0xFF) ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[36 0x24]
function() self.F = (band(band(self.H,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.H = self.H- 1  ;self.H = bit.band(self.H,0xFF) ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bor(self.F,0x40); cycles = cycles + 4 end,--[37 0x25]
function() self.H = mem.getByte(self.PC) ; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[38 0x26]
function()  if (band(self.F,0x40)>0 and 1 or 0) ==  0 then if ( (band(self.F,0x10)>0 and 1 or 0) >  0) or ( self.A > 153  ) then self.A = self.A + 96  ;self.A = bit.band(self.A,0xFF) ; self.F = bit.bor(self.F,0x10) end if ( (band(self.F,0x20)>0 and 1 or 0) >  0) or ( band(self.A, 15)  >9  ) then self.A = self.A +  6; self.A = bit.band(self.A,0xFF) end else if (band(self.F,0x10)>0 and 1 or 0) >  0 then self.A = self.A - 96  ;self.A = bit.band(self.A,0xFF) end if (band(self.F,0x20)>0 and 1 or 0) >  0 then self.A = self.A -  6; self.A = bit.band(self.A,0xFF) end end self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF); cycles = cycles + 4 end,--[39 0x27]
function() if (band(self.F,0x80) > 0) then  self.PC = self.PC + mem.getSignedByte(self.PC)  ; cycles = cycles +  4 end; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[40 0x28]
function()  local temp = (lshift(self.H,8)+self.L)+(lshift(self.H,8)+self.L) ; self.F = (band((lshift(self.H,8)+self.L),0xFFF )+band((lshift(self.H,8)+self.L),0xFFF ) > 0xFFF ) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band((lshift(self.H,8)+self.L),0xFFFF)+band((lshift(self.H,8)+self.L),0xFFFF) > 0xFFFF) and bor(self.F,0x10) or band(self.F,0xEF) ; temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[41 0x29]
function()  local temp = (lshift(self.H,8)+self.L) ; self.A = mem.getByte(temp) ; temp = temp+1  ;temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF); cycles = cycles + 8 end,--[42 0x2a]
function()  local temp = (lshift(self.H,8)+self.L) ;temp = temp-1  ;temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF); cycles = cycles + 8 end,--[43 0x2b]
function() self.F = (band(band(self.L,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.L = self.L +  1; self.L = bit.band(self.L,0xFF) ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[44 0x2c]
function() self.F = (band(band(self.L,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.L = self.L- 1  ;self.L = bit.band(self.L,0xFF) ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bor(self.F,0x40); cycles = cycles + 4 end,--[45 0x2d]
function() self.L = mem.getByte(self.PC) ; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[46 0x2e]
function() self.A = bit.band(bit.bnot(self.A),0xFF) ; self.F = bit.bor(self.F,0x40) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 4 end,--[47 0x2f]
function() if (band(self.F,0x10) == 0) then self.PC = self.PC + mem.getSignedByte(self.PC)  ; cycles = cycles +  4 end; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[48 0x30]
function() self.SP = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)); cycles = cycles + 12; self.PC = self.PC+ 2 end,--[49 0x31]
function()  local temp = (lshift(self.H,8)+self.L) ; mem.setByte(self.A,temp) ; temp = temp-1  ;temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF) ; cycles = cycles + 8 end,--[50 0x32]
function()  local temp = self.SP ;temp = temp+1; temp = bit.band(temp,0xFFFF) ; self.SP = temp; cycles = cycles + 8 end,--[51 0x33]
function()  local temp = mem.getByte((lshift(self.H,8)+self.L)) ; self.F = (band(band(temp,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;temp = temp+1; temp = bit.band(temp,0xFF) ; mem.setByte(temp,(lshift(self.H,8)+self.L)) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 12 end,--[52 0x34]
function()  local temp = mem.getByte((lshift(self.H,8)+self.L)) ; self.F = (band(band(temp,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;temp = temp-1  ;temp = bit.band(temp,0xFF) ; mem.setByte(temp,(lshift(self.H,8)+self.L)) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 12 end,--[53 0x35]
function() mem.setByte(mem.getByte(self.PC),(lshift(self.H,8)+self.L)); cycles = cycles + 12; self.PC = self.PC+ 1 end,--[54 0x36]
function() self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = bit.bor(self.F,0x10); cycles = cycles + 4 end,--[55 0x37]
function() if (band(self.F,0x10) > 0) then  self.PC = self.PC + mem.getSignedByte(self.PC)  ; cycles = cycles +  4 end; cycles = cycles + 8; self.PC = self.PC+ 1 end,--[56 0x38]
function()  local temp = (lshift(self.H,8)+self.L)+self.SP ; self.F = (band((lshift(self.H,8)+self.L),0xFFF )+band(self.SP,0xFFF ) > 0xFFF ) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band((lshift(self.H,8)+self.L),0xFFFF)+band(self.SP,0xFFFF) > 0xFFFF) and bor(self.F,0x10) or band(self.F,0xEF) ; temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[57 0x39]
function()  local temp = (lshift(self.H,8)+self.L) ; self.A = mem.getByte(temp) ; temp = temp-1  ;temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF); cycles = cycles + 8 end,--[58 0x3a]
function()  local temp = self.SP ;temp = temp-1  ;temp = bit.band(temp,0xFFFF) ; self.SP = temp; cycles = cycles + 8 end,--[59 0x3b]
function() self.F = (band(band(self.A,0xF )+band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.A = self.A +  1; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF); cycles = cycles + 4 end,--[60 0x3c]
function() self.F = (band(band(self.A,0xF )-band( 1,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF)  ;self.A = self.A- 1  ;self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bor(self.F,0x40); cycles = cycles + 4 end,--[61 0x3d]
function() self.A = mem.getByte(self.PC); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[62 0x3e]
function() self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; if (band(self.F,0x10)>0 and 1 or 0) >  0 then self.F = band(self.F,0xEF) else self.F = bit.bor(self.F,0x10) end; cycles = cycles + 4 end,--[63 0x3f]
function() self.B = self.B; cycles = cycles + 4 end,--[64 0x40]
function() self.B = self.C; cycles = cycles + 4 end,--[65 0x41]
function() self.B = self.D; cycles = cycles + 4 end,--[66 0x42]
function() self.B = self.E; cycles = cycles + 4 end,--[67 0x43]
function() self.B = self.H; cycles = cycles + 4 end,--[68 0x44]
function() self.B = self.L; cycles = cycles + 4 end,--[69 0x45]
function() self.B = mem.getByte((lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[70 0x46]
function() self.B = self.A; cycles = cycles + 4 end,--[71 0x47]
function() self.C = self.B; cycles = cycles + 4 end,--[72 0x48]
function() self.C = self.C; cycles = cycles + 4 end,--[73 0x49]
function() self.C = self.D; cycles = cycles + 4 end,--[74 0x4a]
function() self.C = self.E; cycles = cycles + 4 end,--[75 0x4b]
function() self.C = self.H; cycles = cycles + 4 end,--[76 0x4c]
function() self.C = self.L; cycles = cycles + 4 end,--[77 0x4d]
function() self.C = mem.getByte((lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[78 0x4e]
function() self.C = self.A; cycles = cycles + 4 end,--[79 0x4f]
function() self.D = self.B; cycles = cycles + 4 end,--[80 0x50]
function() self.D = self.C; cycles = cycles + 4 end,--[81 0x51]
function() self.D = self.D; cycles = cycles + 4 end,--[82 0x52]
function() self.D = self.E; cycles = cycles + 4 end,--[83 0x53]
function() self.D = self.H; cycles = cycles + 4 end,--[84 0x54]
function() self.D = self.L; cycles = cycles + 4 end,--[85 0x55]
function() self.D = mem.getByte((lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[86 0x56]
function() self.D = self.A; cycles = cycles + 4 end,--[87 0x57]
function() self.E = self.B; cycles = cycles + 4 end,--[88 0x58]
function() self.E = self.C; cycles = cycles + 4 end,--[89 0x59]
function() self.E = self.D; cycles = cycles + 4 end,--[90 0x5a]
function() self.E = self.E; cycles = cycles + 4 end,--[91 0x5b]
function() self.E = self.H; cycles = cycles + 4 end,--[92 0x5c]
function() self.E = self.L; cycles = cycles + 4 end,--[93 0x5d]
function() self.E = mem.getByte((lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[94 0x5e]
function() self.E = self.A; cycles = cycles + 4 end,--[95 0x5f]
function() self.H = self.B; cycles = cycles + 4 end,--[96 0x60]
function() self.H = self.C; cycles = cycles + 4 end,--[97 0x61]
function() self.H = self.D; cycles = cycles + 4 end,--[98 0x62]
function() self.H = self.E; cycles = cycles + 4 end,--[99 0x63]
function() self.H = self.H; cycles = cycles + 4 end,--[100 0x64]
function() self.H = self.L; cycles = cycles + 4 end,--[101 0x65]
function() self.H = mem.getByte((lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[102 0x66]
function() self.H = self.A; cycles = cycles + 4 end,--[103 0x67]
function() self.L = self.B; cycles = cycles + 4 end,--[104 0x68]
function() self.L = self.C; cycles = cycles + 4 end,--[105 0x69]
function() self.L = self.D; cycles = cycles + 4 end,--[106 0x6a]
function() self.L = self.E; cycles = cycles + 4 end,--[107 0x6b]
function() self.L = self.H; cycles = cycles + 4 end,--[108 0x6c]
function() self.L = self.L; cycles = cycles + 4 end,--[109 0x6d]
function() self.L = mem.getByte((lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[110 0x6e]
function() self.L = self.A; cycles = cycles + 4 end,--[111 0x6f]
function() mem.setByte(self.B,(lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[112 0x70]
function() mem.setByte(self.C,(lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[113 0x71]
function() mem.setByte(self.D,(lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[114 0x72]
function() mem.setByte(self.E,(lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[115 0x73]
function() mem.setByte(self.H,(lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[116 0x74]
function() mem.setByte(self.L,(lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[117 0x75]
function()  self.HALT = true; cycles = cycles + 4 end,--[118 0x76]
function() mem.setByte(self.A,(lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[119 0x77]
function() self.A = self.B ; cycles = cycles + 4 end,--[120 0x78]
function() self.A = self.C ; cycles = cycles + 4 end,--[121 0x79]
function() self.A = self.D ; cycles = cycles + 4 end,--[122 0x7a]
function() self.A = self.E ; cycles = cycles + 4 end,--[123 0x7b]
function() self.A = self.H ; cycles = cycles + 4 end,--[124 0x7c]
function() self.A = self.L ; cycles = cycles + 4 end,--[125 0x7d]
function() self.A = mem.getByte((lshift(self.H,8)+self.L)); cycles = cycles + 8 end,--[126 0x7e]
function() self.A = self.A; cycles = cycles + 4 end,--[127 0x7f]
function()  local temp = self.A+self.B ; self.F = (band(band(self.A,0xF )+band(self.B,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.B,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[128 0x80]
function()  local temp = self.A+self.C ; self.F = (band(band(self.A,0xF )+band(self.C,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.C,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[129 0x81]
function()  local temp = self.A+self.D ; self.F = (band(band(self.A,0xF )+band(self.D,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.D,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[130 0x82]
function()  local temp = self.A+self.E ; self.F = (band(band(self.A,0xF )+band(self.E,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.E,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[131 0x83]
function()  local temp = self.A+self.H ; self.F = (band(band(self.A,0xF )+band(self.H,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.H,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[132 0x84]
function()  local temp = self.A+self.L ; self.F = (band(band(self.A,0xF )+band(self.L,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.L,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[133 0x85]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ;  local temp = self.A+t ; self.F = (band(band(self.A,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 8 end,--[134 0x86]
function()  local temp = self.A+self.A ; self.F = (band(band(self.A,0xF )+band(self.A,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.A,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[135 0x87]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ; self.F = (band(band(self.A,0xF )+band(self.B,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.B,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = self.A + self.B + t ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[136 0x88]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ; self.F = (band(band(self.A,0xF )+band(self.C,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.C,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = self.A + self.C + t ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[137 0x89]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ; self.F = (band(band(self.A,0xF )+band(self.D,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.D,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = self.A + self.D + t ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[138 0x8a]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ; self.F = (band(band(self.A,0xF )+band(self.E,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.E,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = self.A + self.E + t ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[139 0x8b]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ; self.F = (band(band(self.A,0xF )+band(self.H,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.H,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = self.A + self.H + t ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[140 0x8c]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ; self.F = (band(band(self.A,0xF )+band(self.L,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.L,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = self.A + self.L + t ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[141 0x8d]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = mem.getByte((lshift(self.H,8)+self.L)) ; self.F = (band(band(self.A,0xF )+band(temp,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(temp,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.A = temp + self.A + t ; self.F = band(self.F,0xBF) ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 8 end,--[142 0x8e]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ; self.F = (band(band(self.A,0xF )+band(self.A,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(self.A,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = self.A + self.A + t ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 4 end,--[143 0x8f]
function()  local temp = self.A-self.B ; self.F = (band(band(self.A,0xF )-band(self.B,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-self.B < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 4 end,--[144 0x90]
function()  local temp = self.A-self.C ; self.F = (band(band(self.A,0xF )-band(self.C,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-self.C < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 4 end,--[145 0x91]
function()  local temp = self.A-self.D ; self.F = (band(band(self.A,0xF )-band(self.D,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-self.D < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 4 end,--[146 0x92]
function()  local temp = self.A-self.E ; self.F = (band(band(self.A,0xF )-band(self.E,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-self.E < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 4 end,--[147 0x93]
function()  local temp = self.A-self.H ; self.F = (band(band(self.A,0xF )-band(self.H,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-self.H < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 4 end,--[148 0x94]
function()  local temp = self.A-self.L ; self.F = (band(band(self.A,0xF )-band(self.L,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-self.L < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 4 end,--[149 0x95]
function()  local tem = mem.getByte((lshift(self.H,8)+self.L)) ;  local temp = self.A-tem ; self.F = (band(band(self.A,0xF )-band(tem,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-tem < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 8 end,--[150 0x96]
function()  local temp = self.A-self.A ; self.F = (band(band(self.A,0xF )-band(self.A,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-self.A < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 4 end,--[151 0x97]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = self.B ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 4 end,--[152 0x98]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = self.C ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 4 end,--[153 0x99]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = self.D ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 4 end,--[154 0x9a]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = self.E ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 4 end,--[155 0x9b]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = self.H ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 4 end,--[156 0x9c]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = self.L ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 4 end,--[157 0x9d]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = mem.getByte((lshift(self.H,8)+self.L)) ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 8 end,--[158 0x9e]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = self.A ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 4 end,--[159 0x9f]
function() self.A = band(self.A,self.B) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[160 0xa0]
function() self.A = band(self.A,self.C) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[161 0xa1]
function() self.A = band(self.A,self.D) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[162 0xa2]
function() self.A = band(self.A,self.E) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[163 0xa3]
function() self.A = band(self.A,self.H) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[164 0xa4]
function() self.A = band(self.A,self.L) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[165 0xa5]
function() self.A = band(self.A,mem.getByte((lshift(self.H,8)+self.L))) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[166 0xa6]
function() self.A = band(self.A,self.A) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[167 0xa7]
function() self.A = xor(self.A,self.B) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[168 0xa8]
function() self.A = xor(self.A,self.C) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[169 0xa9]
function() self.A = xor(self.A,self.D) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[170 0xaa]
function() self.A = xor(self.A,self.E) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[171 0xab]
function() self.A = xor(self.A,self.H) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[172 0xac]
function() self.A = xor(self.A,self.L) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[173 0xad]
function() self.A = xor(self.A,mem.getByte((lshift(self.H,8)+self.L))) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[174 0xae]
function() self.A = xor(self.A,self.A) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[175 0xaf]
function() self.A = bor(self.A,self.B) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[176 0xb0]
function() self.A = bor(self.A,self.C) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[177 0xb1]
function() self.A = bor(self.A,self.D) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[178 0xb2]
function() self.A = bor(self.A,self.E) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[179 0xb3]
function() self.A = bor(self.A,self.H) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[180 0xb4]
function() self.A = bor(self.A,self.L) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[181 0xb5]
function() self.A = bor(self.A,mem.getByte((lshift(self.H,8)+self.L))) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[182 0xb6]
function() self.A = bor(self.A,self.A) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 4 end,--[183 0xb7]
function()  local temp = self.A - self.B ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(self.B,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 4 end,--[184 0xb8]
function()  local temp = self.A - self.C ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(self.C,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 4 end,--[185 0xb9]
function()  local temp = self.A - self.D ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(self.D,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 4 end,--[186 0xba]
function()  local temp = self.A - self.E ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(self.E,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 4 end,--[187 0xbb]
function()  local temp = self.A - self.H ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(self.H,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 4 end,--[188 0xbc]
function()  local temp = self.A - self.L ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(self.L,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 4 end,--[189 0xbd]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ;  local temp = self.A - t ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 8 end,--[190 0xbe]
function()  local temp = self.A - self.A ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(self.A,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 4 end,--[191 0xbf]
function() if (band(self.F,0x80) == 0) then  local temp = mem.getByte(self.SP) ; self.SP = self.SP +  1; temp = (temp+lshift(mem.getByte(self.SP),8)) ; self.SP = self.SP +  1; self.PC = temp ; cycles = cycles +  12 end; cycles = cycles + 8 end,--[192 0xc0]
function() self.C = mem.getByte(self.SP) ; self.SP=self.SP+1  ;self.B = mem.getByte(self.SP) ; self.SP=self.SP+1; cycles = cycles + 12 end,--[193 0xc1]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x80) == 0) then self.PC = temp cycles = cycles +  4  ;self.PC = self.PC -  2; end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[194 0xc2]
function() self.PC = mem.getByte(self.PC) + lshift(mem.getByte(self.PC+1), 8); cycles = cycles + 16 end,--[195 0xc3]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x80) == 0) then self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC+2,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC+2,8),0xFF),self.SP+1) ; self.PC = temp-2  ;cycles = cycles +  12 end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[196 0xc4]
function() self.SP=self.SP-1  ;mem.setByte(self.B,self.SP) ; self.SP=self.SP-1  ;mem.setByte(self.C,self.SP); cycles = cycles + 16 end,--[197 0xc5]
function()  local t = mem.getByte(self.PC) ;  local temp = self.A+t ; self.F = (band(band(self.A,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.A = bit.band(temp,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[198 0xc6]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 0; cycles = cycles + 16 end,--[199 0xc7]
function() if (band(self.F,0x80) > 0) then  local temp = mem.getByte(self.SP) ; self.SP = self.SP +  1; temp = (temp+lshift(mem.getByte(self.SP),8)) ; self.SP = self.SP +  1; self.PC = temp ; cycles = cycles +  12 end; cycles = cycles + 8 end,--[200 0xc8]
function()  local temp = mem.getByte(self.SP) ; self.SP = self.SP +  1; temp = (temp+lshift(mem.getByte(self.SP),8)) ; self.SP = self.SP +  1; self.PC = temp; cycles = cycles + 16 end,--[201 0xc9]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x80) > 0) then self.PC = temp cycles = cycles +  4  ;self.PC = self.PC -  2; end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[202 0xca]
function() error("unimplemented instruction 203(0xcb) at PC: "..self.PC) end,--[203 0xcb]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x80) > 0) then self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC+2,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC+2,8),0xFF),self.SP+1) ; self.PC = temp-2  ;cycles = cycles +  12 end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[204 0xcc]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC+2,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC+2,8),0xFF),self.SP+1) ; self.PC = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)); cycles = cycles + 24 end,--[205 0xcd]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = mem.getByte(self.PC) ; self.F = (band(band(self.A,0xF )+band(temp,0xF )+band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.A,0xFF)+band(temp,0xFF)+band(t,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.A = temp + self.A + t ; self.F = band(self.F,0xBF) ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[206 0xce]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 8; cycles = cycles + 16 end,--[207 0xcf]
function() if (band(self.F,0x10) == 0) then  local temp = mem.getByte(self.SP) ; self.SP = self.SP +  1; temp = (temp+lshift(mem.getByte(self.SP),8)) ; self.SP = self.SP +  1; self.PC = temp ; cycles = cycles +  12 end; cycles = cycles + 8 end,--[208 0xd0]
function() self.E = mem.getByte(self.SP) ; self.SP=self.SP+1  ;self.D = mem.getByte(self.SP) ; self.SP=self.SP+1; cycles = cycles + 12 end,--[209 0xd1]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x10) == 0) then self.PC = temp cycles = cycles +  4  ;self.PC = self.PC -  2; end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[210 0xd2]
function() error("unimplemented instruction 211(0xd3) at PC: "..self.PC) end,--[211 0xd3]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x10) == 0) then self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC+2,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC+2,8),0xFF),self.SP+1) ; self.PC = temp-2  ;cycles = cycles +  12 end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[212 0xd4]
function() self.SP=self.SP-1  ;mem.setByte(self.D,self.SP) ; self.SP=self.SP-1  ;mem.setByte(self.E,self.SP); cycles = cycles + 16 end,--[213 0xd5]
function()  local tem = mem.getByte(self.PC) ;  local temp = self.A-tem ; self.F = (band(band(self.A,0xF )-band(tem,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (self.A-tem < 0) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = bit.bor(self.F,0x40) ; self.A = bit.band(temp,0xFF); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[214 0xd6]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 16; cycles = cycles + 16 end,--[215 0xd7]
function() if (band(self.F,0x10) > 0) then  local temp = mem.getByte(self.SP) ; self.SP = self.SP +  1; temp = (temp+lshift(mem.getByte(self.SP),8)) ; self.SP = self.SP +  1; self.PC = temp ; cycles = cycles +  12 end; cycles = cycles + 8 end,--[216 0xd8]
function()  local temp = mem.getByte(self.SP) ; self.SP = self.SP +  1; temp = (temp+lshift(mem.getByte(self.SP),8)) ; self.SP = self.SP +  1; self.PC = temp ; self.IME = true; cycles = cycles + 16 end,--[217 0xd9]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x10) > 0) then self.PC = temp cycles = cycles +  4  ;self.PC = self.PC -  2; end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[218 0xda]
function() error("unimplemented instruction 219(0xdb) at PC: "..self.PC) end,--[219 0xdb]
function()  local temp = (mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8)) if (band(self.F,0x10) > 0) then self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC+2,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC+2,8),0xFF),self.SP+1) ; self.PC = temp-2  ;cycles = cycles +  12 end; cycles = cycles + 12; self.PC = self.PC+ 2 end,--[220 0xdc]
function() error("unimplemented instruction 221(0xdd) at PC: "..self.PC) end,--[221 0xdd]
function()  local t = (band(self.F,0x10)>0 and 1 or 0) ;  local temp = mem.getByte(self.PC) ; self.F = (band(band(self.A,0xF )-band(temp,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.A = self.A - temp ; self.A = self.A - t ; if self.A <  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x40); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[222 0xde]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 24; cycles = cycles + 16 end,--[223 0xdf]
function() mem.setByte(self.A, (0xFF00+mem.getByte(self.PC))); cycles = cycles + 12; self.PC = self.PC+ 1 end,--[224 0xe0]
function() self.L = mem.getByte(self.SP) ; self.SP=self.SP+1  ;self.H = mem.getByte(self.SP) ; self.SP=self.SP+1; cycles = cycles + 12 end,--[225 0xe1]
function() mem.setByte(self.A, (0xFF00+self.C)); cycles = cycles + 8 end,--[226 0xe2]
function() error("unimplemented instruction 227(0xe3) at PC: "..self.PC) end,--[227 0xe3]
function() error("unimplemented instruction 228(0xe4) at PC: "..self.PC) end,--[228 0xe4]
function() self.SP=self.SP-1  ;mem.setByte(self.H,self.SP) ; self.SP=self.SP-1  ;mem.setByte(self.L,self.SP); cycles = cycles + 16 end,--[229 0xe5]
function() self.A = band(self.A,mem.getByte(self.PC)) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = bit.bor(self.F,0x20) ; self.F = band(self.F,0xEF) ; self.F = band(self.F,0xBF); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[230 0xe6]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 32; cycles = cycles + 16 end,--[231 0xe7]
function()  local temp = mem.getSignedByte(self.PC) ; self.F = (band(band(temp,0xF )+band(self.SP,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(temp,0xFF)+band(self.SP,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; temp = self.SP + temp ; temp = bit.band(temp,0xFFFF) ; self.SP = temp ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0x7F); cycles = cycles + 16; self.PC = self.PC+ 1 end,--[232 0xe8]
function() self.PC = (lshift(self.H,8)+self.L); cycles = cycles + 4 end,--[233 0xe9]
function() mem.setByte(self.A,(mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8))); cycles = cycles + 16; self.PC = self.PC+ 2 end,--[234 0xea]
function() error("unimplemented instruction 235(0xeb) at PC: "..self.PC) end,--[235 0xeb]
function() error("unimplemented instruction 236(0xec) at PC: "..self.PC) end,--[236 0xec]
function() error("unimplemented instruction 237(0xed) at PC: "..self.PC) end,--[237 0xed]
function() self.A = xor(self.A,mem.getByte(self.PC)) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[238 0xee]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 40; cycles = cycles + 16 end,--[239 0xef]
function() self.A = mem.getByte( (0xFF00+mem.getByte(self.PC))); cycles = cycles + 12; self.PC = self.PC+ 1 end,--[240 0xf0]
function() self.F = band(mem.getByte(self.SP), 240)  ;self.SP=self.SP+1  ;self.A = mem.getByte(self.SP) ; self.SP=self.SP+1; cycles = cycles + 12 end,--[241 0xf1]
function() self.A = mem.getByte( (0xFF00+self.C)); cycles = cycles + 8 end,--[242 0xf2]
function() self.IME = false; cycles = cycles + 4 end,--[243 0xf3]
function() error("unimplemented instruction 244(0xf4) at PC: "..self.PC) end,--[244 0xf4]
function() self.SP=self.SP-1  ;mem.setByte(self.A,self.SP) ; self.SP=self.SP-1  ;mem.setByte(self.F,self.SP); cycles = cycles + 16 end,--[245 0xf5]
function() self.A = bor(self.A,mem.getByte(self.PC)) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF) ; self.F = band(self.F,0xBF); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[246 0xf6]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 48; cycles = cycles + 16 end,--[247 0xf7]
function()  local temp = mem.getSignedByte(self.PC) ; self.F = (band(band(self.SP,0xF )+band(temp,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF) ; self.F = (band(self.SP,0xFF)+band(temp,0xFF) > 0xFF) and bor(self.F,0x10) or band(self.F,0xEF) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0x7F) ; temp = temp + self.SP ; temp = bit.band(temp,0xFFFF) ; self.H = rshift(band(temp,0xFF00),8) ; self.L = band(temp,0xFF); cycles = cycles + 12; self.PC = self.PC+ 1 end,--[248 0xf8]
function() self.SP = (lshift(self.H,8)+self.L); cycles = cycles + 8 end,--[249 0xf9]
function() self.A = mem.getByte((mem.getByte(self.PC)+lshift(mem.getByte(self.PC+1),8))); cycles = cycles + 16; self.PC = self.PC+ 2 end,--[250 0xfa]
function() self.IME = true; cycles = cycles + 4 end,--[251 0xfb]
function() error("unimplemented instruction 252(0xfc) at PC: "..self.PC) end,--[252 0xfc]
function() error("unimplemented instruction 253(0xfd) at PC: "..self.PC) end,--[253 0xfd]
function()  local t = mem.getByte(self.PC) ;  local temp = self.A - t ; self.F = temp<0 and 0x50 or 0x40 ; self.F = (temp == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = (band(band(self.A,0xF )-band(t,0xF ),0x10) == 0x10) and bor(self.F,0x20) or band(self.F,0xDF); cycles = cycles + 8; self.PC = self.PC+ 1 end,--[254 0xfe]
function() self.SP = self.SP-2  ;mem.setByte(bit.band(self.PC,0xFF),self.SP) ; mem.setByte(bit.band(bit.rshift(self.PC,8),0xFF),self.SP+1) ; self.PC = 56; cycles = cycles + 16 end,--[255 0xff]
}

	instructionsCB =  {
function()  local temp = band(self.B, 128)  >0  and 1 or 0  ;self.B = lshift(self.B, 1)  ; self.F = ((band(self.B, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.B = self.B + temp ; self.B = bit.band(self.B,0xFF) ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[0 0x0]
function()  local temp = band(self.C, 128)  >0  and 1 or 0  ;self.C = lshift(self.C, 1)  ; self.F = ((band(self.C, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.C = self.C + temp ; self.C = bit.band(self.C,0xFF) ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[1 0x1]
function()  local temp = band(self.D, 128)  >0  and 1 or 0  ;self.D = lshift(self.D, 1)  ; self.F = ((band(self.D, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.D = self.D + temp ; self.D = bit.band(self.D,0xFF) ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[2 0x2]
function()  local temp = band(self.E, 128)  >0  and 1 or 0  ;self.E = lshift(self.E, 1)  ; self.F = ((band(self.E, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.E = self.E + temp ; self.E = bit.band(self.E,0xFF) ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[3 0x3]
function()  local temp = band(self.H, 128)  >0  and 1 or 0  ;self.H = lshift(self.H, 1)  ; self.F = ((band(self.H, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.H = self.H + temp ; self.H = bit.band(self.H,0xFF) ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[4 0x4]
function()  local temp = band(self.L, 128)  >0  and 1 or 0  ;self.L = lshift(self.L, 1)  ; self.F = ((band(self.L, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.L = self.L + temp ; self.L = bit.band(self.L,0xFF) ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[5 0x5]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ;  local temp = band(t, 128)  >0  and 1 or 0  ;t = lshift(t, 1)  ; self.F = ((band(t, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;t = t + temp ; t = bit.band(t,0xFF) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 16 end,--[6 0x6]
function()  local temp = band(self.A, 128)  >0  and 1 or 0  ;self.A = lshift(self.A, 1)  ; self.F = ((band(self.A, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.A = self.A + temp ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[7 0x7]
function() temp = band(self.B, 1)  ;self.B = rshift(self.B, 1)  ;if temp >  0 then self.B = self.B + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[8 0x8]
function() temp = band(self.C, 1)  ;self.C = rshift(self.C, 1)  ;if temp >  0 then self.C = self.C + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[9 0x9]
function() temp = band(self.D, 1)  ;self.D = rshift(self.D, 1)  ;if temp >  0 then self.D = self.D + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[10 0xa]
function() temp = band(self.E, 1)  ;self.E = rshift(self.E, 1)  ;if temp >  0 then self.E = self.E + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[11 0xb]
function() temp = band(self.H, 1)  ;self.H = rshift(self.H, 1)  ;if temp >  0 then self.H = self.H + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[12 0xc]
function() temp = band(self.L, 1)  ;self.L = rshift(self.L, 1)  ;if temp >  0 then self.L = self.L + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[13 0xd]
function() t = mem.getByte((lshift(self.H,8)+self.L)) ; temp = band(t, 1)  ;t = rshift(t, 1)  ;if temp >  0 then t = t + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 16 end,--[14 0xe]
function() temp = band(self.A, 1)  ;self.A = rshift(self.A, 1)  ;if temp >  0 then self.A = self.A + 128  ;self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[15 0xf]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.B = lshift(self.B, 1)  ; self.F = ((band(self.B, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.B = bor(self.B,temp) ; self.B = bit.band(self.B,0xFF) ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[16 0x10]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.C = lshift(self.C, 1)  ; self.F = ((band(self.C, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.C = bor(self.C,temp) ; self.C = bit.band(self.C,0xFF) ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[17 0x11]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.D = lshift(self.D, 1)  ; self.F = ((band(self.D, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.D = bor(self.D,temp) ; self.D = bit.band(self.D,0xFF) ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[18 0x12]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.E = lshift(self.E, 1)  ; self.F = ((band(self.E, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.E = bor(self.E,temp) ; self.E = bit.band(self.E,0xFF) ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[19 0x13]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.H = lshift(self.H, 1)  ; self.F = ((band(self.H, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.H = bor(self.H,temp) ; self.H = bit.band(self.H,0xFF) ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[20 0x14]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.L = lshift(self.L, 1)  ; self.F = ((band(self.L, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.L = bor(self.L,temp) ; self.L = bit.band(self.L,0xFF) ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[21 0x15]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ;  local temp = (band(self.F,0x10)>0 and 1 or 0) ; t = lshift(t, 1)  ; self.F = ((band(t, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;t = bor(t,temp) ; t = bit.band(t,0xFF) ; mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 16 end,--[22 0x16]
function()  local temp = (band(self.F,0x10)>0 and 1 or 0) ; self.A = lshift(self.A, 1)  ; self.F = ((band(self.A, 256) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.A = bor(self.A,temp) ; self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[23 0x17]
function()  local temp = band(self.B, 1)  ;self.B = rshift(self.B, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.B = self.B + temp ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[24 0x18]
function()  local temp = band(self.C, 1)  ;self.C = rshift(self.C, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.C = self.C + temp ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[25 0x19]
function()  local temp = band(self.D, 1)  ;self.D = rshift(self.D, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.D = self.D + temp ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[26 0x1a]
function()  local temp = band(self.E, 1)  ;self.E = rshift(self.E, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.E = self.E + temp ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[27 0x1b]
function()  local temp = band(self.H, 1)  ;self.H = rshift(self.H, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.H = self.H + temp ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[28 0x1c]
function()  local temp = band(self.L, 1)  ;self.L = rshift(self.L, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.L = self.L + temp ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[29 0x1d]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ; local temp = band(t, 1)  ;t = rshift(t, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;t = t + temp ; mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 16 end,--[30 0x1e]
function()  local temp = band(self.A, 1)  ;self.A = rshift(self.A, 1)  ; local tem = (band(self.F,0x10)>0 and 1 or 0) ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; temp = tem >  0 and 128 or 0  ;self.A = self.A + temp ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[31 0x1f]
function()  self.F = ((band(self.B, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.B = lshift(self.B, 1)  ;self.B = bit.band(self.B,0xFF) ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[32 0x20]
function()  self.F = ((band(self.C, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.C = lshift(self.C, 1)  ;self.C = bit.band(self.C,0xFF) ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[33 0x21]
function()  self.F = ((band(self.D, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.D = lshift(self.D, 1)  ;self.D = bit.band(self.D,0xFF) ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[34 0x22]
function()  self.F = ((band(self.E, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.E = lshift(self.E, 1)  ;self.E = bit.band(self.E,0xFF) ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[35 0x23]
function()  self.F = ((band(self.H, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.H = lshift(self.H, 1)  ;self.H = bit.band(self.H,0xFF) ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[36 0x24]
function()  self.F = ((band(self.L, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.L = lshift(self.L, 1)  ;self.L = bit.band(self.L,0xFF) ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[37 0x25]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ;  self.F = ((band(t, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;t = lshift(t, 1)  ;t = bit.band(t,0xFF) ; mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 16 end,--[38 0x26]
function()  self.F = ((band(self.A, 128) == 0) and band(self.F,0xEF) or bor(self.F,0x10))  ;self.A = lshift(self.A, 1)  ;self.A = bit.band(self.A,0xFF) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[39 0x27]
function()  local t = band(self.B, 128)  ;temp = band(self.B, 1)  ;self.B = rshift(self.B, 1)  ;self.B = self.B + t ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[40 0x28]
function()  local t = band(self.C, 128)  ;temp = band(self.C, 1)  ;self.C = rshift(self.C, 1)  ;self.C = self.C + t ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[41 0x29]
function()  local t = band(self.D, 128)  ;temp = band(self.D, 1)  ;self.D = rshift(self.D, 1)  ;self.D = self.D + t ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[42 0x2a]
function()  local t = band(self.E, 128)  ;temp = band(self.E, 1)  ;self.E = rshift(self.E, 1)  ;self.E = self.E + t ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[43 0x2b]
function()  local t = band(self.H, 128)  ;temp = band(self.H, 1)  ;self.H = rshift(self.H, 1)  ;self.H = self.H + t ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[44 0x2c]
function()  local t = band(self.L, 128)  ;temp = band(self.L, 1)  ;self.L = rshift(self.L, 1)  ;self.L = self.L + t ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[45 0x2d]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ;  local tem = band(t, 128)  ;temp = band(t, 1)  ;t = rshift(t, 1)  ;t = t + tem ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 16 end,--[46 0x2e]
function()  local t = band(self.A, 128)  ;temp = band(self.A, 1)  ;self.A = rshift(self.A, 1)  ;self.A = self.A + t ; if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[47 0x2f]
function() self.B =  bit.rshift(band(self.B,0xF0),4)+bit.lshift(band(self.B,0xF),4) ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[48 0x30]
function() self.C =  bit.rshift(band(self.C,0xF0),4)+bit.lshift(band(self.C,0xF),4) ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[49 0x31]
function() self.D =  bit.rshift(band(self.D,0xF0),4)+bit.lshift(band(self.D,0xF),4) ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[50 0x32]
function() self.E =  bit.rshift(band(self.E,0xF0),4)+bit.lshift(band(self.E,0xF),4) ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[51 0x33]
function() self.H =  bit.rshift(band(self.H,0xF0),4)+bit.lshift(band(self.H,0xF),4) ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[52 0x34]
function() self.L =  bit.rshift(band(self.L,0xF0),4)+bit.lshift(band(self.L,0xF),4) ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[53 0x35]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ; t =  bit.rshift(band(t,0xF0),4)+bit.lshift(band(t,0xF),4) ; mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 16 end,--[54 0x36]
function() self.A =  bit.rshift(band(self.A,0xF0),4)+bit.lshift(band(self.A,0xF),4) ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xBF) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xEF); cycles = cycles + 8 end,--[55 0x37]
function() temp = band(self.B, 1)  ;self.B = rshift(self.B, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.B == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[56 0x38]
function() temp = band(self.C, 1)  ;self.C = rshift(self.C, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.C == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[57 0x39]
function() temp = band(self.D, 1)  ;self.D = rshift(self.D, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.D == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[58 0x3a]
function() temp = band(self.E, 1)  ;self.E = rshift(self.E, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.E == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[59 0x3b]
function() temp = band(self.H, 1)  ;self.H = rshift(self.H, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.H == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[60 0x3c]
function() temp = band(self.L, 1)  ;self.L = rshift(self.L, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.L == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[61 0x3d]
function()  local t = mem.getByte((lshift(self.H,8)+self.L)) ; temp = band(t, 1)  ;t = rshift(t, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; mem.setByte(t,(lshift(self.H,8)+self.L)) ; self.F = (t == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 16 end,--[62 0x3e]
function() temp = band(self.A, 1)  ;self.A = rshift(self.A, 1)  ;if temp >  0 then self.F = bit.bor(self.F,0x10) else self.F = band(self.F,0xEF) end ; self.F = (self.A == 0) and bor(self.F,0x80) or band(self.F,0x7F) ; self.F = band(self.F,0xDF) ; self.F = band(self.F,0xBF); cycles = cycles + 8 end,--[63 0x3f]
function() self.F = (band(self.B, 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[64 0x40]
function() self.F = (band(self.C, 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[65 0x41]
function() self.F = (band(self.D, 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[66 0x42]
function() self.F = (band(self.E, 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[67 0x43]
function() self.F = (band(self.H, 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[68 0x44]
function() self.F = (band(self.L, 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[69 0x45]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[70 0x46]
function() self.F = (band(self.A, 1) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[71 0x47]
function() self.F = (band(self.B, 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[72 0x48]
function() self.F = (band(self.C, 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[73 0x49]
function() self.F = (band(self.D, 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[74 0x4a]
function() self.F = (band(self.E, 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[75 0x4b]
function() self.F = (band(self.H, 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[76 0x4c]
function() self.F = (band(self.L, 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[77 0x4d]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[78 0x4e]
function() self.F = (band(self.A, 2) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[79 0x4f]
function() self.F = (band(self.B, 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[80 0x50]
function() self.F = (band(self.C, 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[81 0x51]
function() self.F = (band(self.D, 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[82 0x52]
function() self.F = (band(self.E, 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[83 0x53]
function() self.F = (band(self.H, 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[84 0x54]
function() self.F = (band(self.L, 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[85 0x55]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[86 0x56]
function() self.F = (band(self.A, 4) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[87 0x57]
function() self.F = (band(self.B, 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[88 0x58]
function() self.F = (band(self.C, 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[89 0x59]
function() self.F = (band(self.D, 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[90 0x5a]
function() self.F = (band(self.E, 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[91 0x5b]
function() self.F = (band(self.H, 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[92 0x5c]
function() self.F = (band(self.L, 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[93 0x5d]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[94 0x5e]
function() self.F = (band(self.A, 8) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[95 0x5f]
function() self.F = (band(self.B, 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[96 0x60]
function() self.F = (band(self.C, 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[97 0x61]
function() self.F = (band(self.D, 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[98 0x62]
function() self.F = (band(self.E, 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[99 0x63]
function() self.F = (band(self.H, 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[100 0x64]
function() self.F = (band(self.L, 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[101 0x65]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[102 0x66]
function() self.F = (band(self.A, 16) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[103 0x67]
function() self.F = (band(self.B, 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[104 0x68]
function() self.F = (band(self.C, 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[105 0x69]
function() self.F = (band(self.D, 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[106 0x6a]
function() self.F = (band(self.E, 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[107 0x6b]
function() self.F = (band(self.H, 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[108 0x6c]
function() self.F = (band(self.L, 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[109 0x6d]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[110 0x6e]
function() self.F = (band(self.A, 32) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[111 0x6f]
function() self.F = (band(self.B, 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[112 0x70]
function() self.F = (band(self.C, 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[113 0x71]
function() self.F = (band(self.D, 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[114 0x72]
function() self.F = (band(self.E, 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[115 0x73]
function() self.F = (band(self.H, 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[116 0x74]
function() self.F = (band(self.L, 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[117 0x75]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[118 0x76]
function() self.F = (band(self.A, 64) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[119 0x77]
function() self.F = (band(self.B, 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[120 0x78]
function() self.F = (band(self.C, 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[121 0x79]
function() self.F = (band(self.D, 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[122 0x7a]
function() self.F = (band(self.E, 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[123 0x7b]
function() self.F = (band(self.H, 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[124 0x7c]
function() self.F = (band(self.L, 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[125 0x7d]
function() self.F = (band(mem.getByte((lshift(self.H,8)+self.L)), 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 12 end,--[126 0x7e]
function() self.F = (band(self.A, 128) == 0) and bor(self.F,0x80) or band(self.F,0x7F)  ;self.F = band(self.F,0xBF) ; self.F = bit.bor(self.F,0x20); cycles = cycles + 8 end,--[127 0x7f]
function() self.B = band(self.B, 254); cycles = cycles + 8 end,--[128 0x80]
function() self.C = band(self.C, 254); cycles = cycles + 8 end,--[129 0x81]
function() self.D = band(self.D, 254); cycles = cycles + 8 end,--[130 0x82]
function() self.E = band(self.E, 254); cycles = cycles + 8 end,--[131 0x83]
function() self.H = band(self.H, 254); cycles = cycles + 8 end,--[132 0x84]
function() self.L = band(self.L, 254); cycles = cycles + 8 end,--[133 0x85]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 254),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[134 0x86]
function() self.A = band(self.A, 254); cycles = cycles + 8 end,--[135 0x87]
function() self.B = band(self.B, 253); cycles = cycles + 8 end,--[136 0x88]
function() self.C = band(self.C, 253); cycles = cycles + 8 end,--[137 0x89]
function() self.D = band(self.D, 253); cycles = cycles + 8 end,--[138 0x8a]
function() self.E = band(self.E, 253); cycles = cycles + 8 end,--[139 0x8b]
function() self.H = band(self.H, 253); cycles = cycles + 8 end,--[140 0x8c]
function() self.L = band(self.L, 253); cycles = cycles + 8 end,--[141 0x8d]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 253),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[142 0x8e]
function() self.A = band(self.A, 253); cycles = cycles + 8 end,--[143 0x8f]
function() self.B = band(self.B, 251); cycles = cycles + 8 end,--[144 0x90]
function() self.C = band(self.C, 251); cycles = cycles + 8 end,--[145 0x91]
function() self.D = band(self.D, 251); cycles = cycles + 8 end,--[146 0x92]
function() self.E = band(self.E, 251); cycles = cycles + 8 end,--[147 0x93]
function() self.H = band(self.H, 251); cycles = cycles + 8 end,--[148 0x94]
function() self.L = band(self.L, 251); cycles = cycles + 8 end,--[149 0x95]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 251),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[150 0x96]
function() self.A = band(self.A, 251); cycles = cycles + 8 end,--[151 0x97]
function() self.B = band(self.B, 247); cycles = cycles + 8 end,--[152 0x98]
function() self.C = band(self.C, 247); cycles = cycles + 8 end,--[153 0x99]
function() self.D = band(self.D, 247); cycles = cycles + 8 end,--[154 0x9a]
function() self.E = band(self.E, 247); cycles = cycles + 8 end,--[155 0x9b]
function() self.H = band(self.H, 247); cycles = cycles + 8 end,--[156 0x9c]
function() self.L = band(self.L, 247); cycles = cycles + 8 end,--[157 0x9d]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 247),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[158 0x9e]
function() self.A = band(self.A, 247); cycles = cycles + 8 end,--[159 0x9f]
function() self.B = band(self.B, 239); cycles = cycles + 8 end,--[160 0xa0]
function() self.C = band(self.C, 239); cycles = cycles + 8 end,--[161 0xa1]
function() self.D = band(self.D, 239); cycles = cycles + 8 end,--[162 0xa2]
function() self.E = band(self.E, 239); cycles = cycles + 8 end,--[163 0xa3]
function() self.H = band(self.H, 239); cycles = cycles + 8 end,--[164 0xa4]
function() self.L = band(self.L, 239); cycles = cycles + 8 end,--[165 0xa5]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 239),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[166 0xa6]
function() self.A = band(self.A, 239); cycles = cycles + 8 end,--[167 0xa7]
function() self.B = band(self.B, 223); cycles = cycles + 8 end,--[168 0xa8]
function() self.C = band(self.C, 223); cycles = cycles + 8 end,--[169 0xa9]
function() self.D = band(self.D, 223); cycles = cycles + 8 end,--[170 0xaa]
function() self.E = band(self.E, 223); cycles = cycles + 8 end,--[171 0xab]
function() self.H = band(self.H, 223); cycles = cycles + 8 end,--[172 0xac]
function() self.L = band(self.L, 223); cycles = cycles + 8 end,--[173 0xad]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 223),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[174 0xae]
function() self.A = band(self.A, 223); cycles = cycles + 8 end,--[175 0xaf]
function() self.B = band(self.B, 191); cycles = cycles + 8 end,--[176 0xb0]
function() self.C = band(self.C, 191); cycles = cycles + 8 end,--[177 0xb1]
function() self.D = band(self.D, 191); cycles = cycles + 8 end,--[178 0xb2]
function() self.E = band(self.E, 191); cycles = cycles + 8 end,--[179 0xb3]
function() self.H = band(self.H, 191); cycles = cycles + 8 end,--[180 0xb4]
function() self.L = band(self.L, 191); cycles = cycles + 8 end,--[181 0xb5]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 191),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[182 0xb6]
function() self.A = band(self.A, 191); cycles = cycles + 8 end,--[183 0xb7]
function() self.B = band(self.B, 127); cycles = cycles + 8 end,--[184 0xb8]
function() self.C = band(self.C, 127); cycles = cycles + 8 end,--[185 0xb9]
function() self.D = band(self.D, 127); cycles = cycles + 8 end,--[186 0xba]
function() self.E = band(self.E, 127); cycles = cycles + 8 end,--[187 0xbb]
function() self.H = band(self.H, 127); cycles = cycles + 8 end,--[188 0xbc]
function() self.L = band(self.L, 127); cycles = cycles + 8 end,--[189 0xbd]
function() mem.setByte(band(mem.getByte((lshift(self.H,8)+self.L)), 127),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[190 0xbe]
function() self.A = band(self.A, 127); cycles = cycles + 8 end,--[191 0xbf]
function() self.B = bor(self.B, 1); cycles = cycles + 8 end,--[192 0xc0]
function() self.C = bor(self.C, 1); cycles = cycles + 8 end,--[193 0xc1]
function() self.D = bor(self.D, 1); cycles = cycles + 8 end,--[194 0xc2]
function() self.E = bor(self.E, 1); cycles = cycles + 8 end,--[195 0xc3]
function() self.H = bor(self.H, 1); cycles = cycles + 8 end,--[196 0xc4]
function() self.L = bor(self.L, 1); cycles = cycles + 8 end,--[197 0xc5]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 1),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[198 0xc6]
function() self.A = bor(self.A, 1); cycles = cycles + 8 end,--[199 0xc7]
function() self.B = bor(self.B, 2); cycles = cycles + 8 end,--[200 0xc8]
function() self.C = bor(self.C, 2); cycles = cycles + 8 end,--[201 0xc9]
function() self.D = bor(self.D, 2); cycles = cycles + 8 end,--[202 0xca]
function() self.E = bor(self.E, 2); cycles = cycles + 8 end,--[203 0xcb]
function() self.H = bor(self.H, 2); cycles = cycles + 8 end,--[204 0xcc]
function() self.L = bor(self.L, 2); cycles = cycles + 8 end,--[205 0xcd]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 2),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[206 0xce]
function() self.A = bor(self.A, 2); cycles = cycles + 8 end,--[207 0xcf]
function() self.B = bor(self.B, 4); cycles = cycles + 8 end,--[208 0xd0]
function() self.C = bor(self.C, 4); cycles = cycles + 8 end,--[209 0xd1]
function() self.D = bor(self.D, 4); cycles = cycles + 8 end,--[210 0xd2]
function() self.E = bor(self.E, 4); cycles = cycles + 8 end,--[211 0xd3]
function() self.H = bor(self.H, 4); cycles = cycles + 8 end,--[212 0xd4]
function() self.L = bor(self.L, 4); cycles = cycles + 8 end,--[213 0xd5]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 4),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[214 0xd6]
function() self.A = bor(self.A, 4); cycles = cycles + 8 end,--[215 0xd7]
function() self.B = bor(self.B, 8); cycles = cycles + 8 end,--[216 0xd8]
function() self.C = bor(self.C, 8); cycles = cycles + 8 end,--[217 0xd9]
function() self.D = bor(self.D, 8); cycles = cycles + 8 end,--[218 0xda]
function() self.E = bor(self.E, 8); cycles = cycles + 8 end,--[219 0xdb]
function() self.H = bor(self.H, 8); cycles = cycles + 8 end,--[220 0xdc]
function() self.L = bor(self.L, 8); cycles = cycles + 8 end,--[221 0xdd]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 8),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[222 0xde]
function() self.A = bor(self.A, 8); cycles = cycles + 8 end,--[223 0xdf]
function() self.B = bor(self.B, 16); cycles = cycles + 8 end,--[224 0xe0]
function() self.C = bor(self.C, 16); cycles = cycles + 8 end,--[225 0xe1]
function() self.D = bor(self.D, 16); cycles = cycles + 8 end,--[226 0xe2]
function() self.E = bor(self.E, 16); cycles = cycles + 8 end,--[227 0xe3]
function() self.H = bor(self.H, 16); cycles = cycles + 8 end,--[228 0xe4]
function() self.L = bor(self.L, 16); cycles = cycles + 8 end,--[229 0xe5]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 16),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[230 0xe6]
function() self.A = bor(self.A, 16); cycles = cycles + 8 end,--[231 0xe7]
function() self.B = bor(self.B, 32); cycles = cycles + 8 end,--[232 0xe8]
function() self.C = bor(self.C, 32); cycles = cycles + 8 end,--[233 0xe9]
function() self.D = bor(self.D, 32); cycles = cycles + 8 end,--[234 0xea]
function() self.E = bor(self.E, 32); cycles = cycles + 8 end,--[235 0xeb]
function() self.H = bor(self.H, 32); cycles = cycles + 8 end,--[236 0xec]
function() self.L = bor(self.L, 32); cycles = cycles + 8 end,--[237 0xed]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 32),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[238 0xee]
function() self.A = bor(self.A, 32); cycles = cycles + 8 end,--[239 0xef]
function() self.B = bor(self.B, 64); cycles = cycles + 8 end,--[240 0xf0]
function() self.C = bor(self.C, 64); cycles = cycles + 8 end,--[241 0xf1]
function() self.D = bor(self.D, 64); cycles = cycles + 8 end,--[242 0xf2]
function() self.E = bor(self.E, 64); cycles = cycles + 8 end,--[243 0xf3]
function() self.H = bor(self.H, 64); cycles = cycles + 8 end,--[244 0xf4]
function() self.L = bor(self.L, 64); cycles = cycles + 8 end,--[245 0xf5]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 64),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[246 0xf6]
function() self.A = bor(self.A, 64); cycles = cycles + 8 end,--[247 0xf7]
function() self.B = bor(self.B, 128); cycles = cycles + 8 end,--[248 0xf8]
function() self.C = bor(self.C, 128); cycles = cycles + 8 end,--[249 0xf9]
function() self.D = bor(self.D, 128); cycles = cycles + 8 end,--[250 0xfa]
function() self.E = bor(self.E, 128); cycles = cycles + 8 end,--[251 0xfb]
function() self.H = bor(self.H, 128); cycles = cycles + 8 end,--[252 0xfc]
function() self.L = bor(self.L, 128); cycles = cycles + 8 end,--[253 0xfd]
function() mem.setByte(bor(mem.getByte((lshift(self.H,8)+self.L)), 128),(lshift(self.H,8)+self.L)); cycles = cycles + 16 end,--[254 0xfe]
function() self.A = bor(self.A, 128); cycles = cycles + 8 end,--[255 0xff]
}

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
