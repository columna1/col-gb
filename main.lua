--local cpu = require("cpu")
local gen = require("geninst")
if arg[#arg] == "-debug" then require("mobdebug").start() end

local out,out2 = gen("opcode-desc.txt")
--print("DONE")
--print(out)
file = io.open("cpu.lua","r")
dat = file:read("*a")
--print(out)
dat = dat:gsub("--%$instructions%$",out)
dat = dat:gsub("--%$instructionsCB%$",out2)
file:close()
file = io.open("cpu2.lua","w")
file:write(dat)
file:close()
local cpu = require("cpu2")

local gbCPU = cpu()
function love.load()
	
	--gbCPU.executeInstruction()
	--gbCPU.executeInstruction()
	love.keyboard.setKeyRepeat(true)
end

function love.draw()
	love.graphics.print(string.format("A 0x%x(%d)",gbCPU.A,gbCPU.A) ,0,0)
	love.graphics.print(string.format("B 0x%x(%d)",gbCPU.B,gbCPU.B) ,0,15)
	love.graphics.print(string.format("C 0x%x(%d)",gbCPU.C,gbCPU.C) ,0,30)
	love.graphics.print(string.format("D 0x%x(%d)",gbCPU.D,gbCPU.D) ,0,45)
	love.graphics.print(string.format("E 0x%x(%d)",gbCPU.E,gbCPU.E) ,0,60)
	love.graphics.print(string.format("H 0x%x(%d)",gbCPU.H,gbCPU.H) ,0,75)
	love.graphics.print(string.format("L 0x%x(%d)",gbCPU.L,gbCPU.L) ,0,90)
	love.graphics.print("F "..gbCPU.F,0,105)
	love.graphics.print("Z ".. (bit.band(gbCPU.F,0x80)>0 and 1 or 0) .." N ".. (bit.band(gbCPU.F,0x40)>0 and 1 or 0) .." H ".. (bit.band(gbCPU.F,0x20)>0 and 1 or 0) .." C ".. (bit.band(gbCPU.F,0x10)>0 and 1 or 0)  ,0,120)
	love.graphics.print(string.format("SP 0x%x(%d)",gbCPU.SP,gbCPU.SP),0,135)
	love.graphics.print("PC "..gbCPU.PC..string.format(" 0x%x",gbCPU.PC),0,150)
	love.graphics.print("cycles "..gbCPU.cycles,0,165)
	for i = 0,127/4 do
		local j = math.floor(i)*4
		love.graphics.print(string.format("0x%x,0x%x,0x%x,0x%x",gbCPU.mem.zeroPage[j],gbCPU.mem.zeroPage[j+1],gbCPU.mem.zeroPage[j+2],gbCPU.mem.zeroPage[j+3]),300,i*15+10)
	end
end

local curBreakPoint = -1

function love.keypressed(k)
	--print(k)
	if k == "space" then
		--print("executing instruction")
		if love.keyboard.isDown("lshift") then
			print("50")
			for i = 1,50 do
				gbCPU.executeInstruction()
			end
		else
			gbCPU.executeInstruction(true)
		end
	end
	if k == "return" then
		if love.keyboard.isDown("lshift") then
			print("1000")
			for i = 1,1000 do
				gbCPU.executeInstruction()
			end
		elseif love.keyboard.isDown("lctrl") then
			print("500")
			for i = 1,500 do
				gbCPU.executeInstruction()
			end
		else
			print("100")
			for i = 1,100 do
				gbCPU.executeInstruction()
			end
		end
	end
	if k == "b" then--til breakpoint
		local breakpoints = {0x34,0x40,0xE0,0x100}
		while true  do
			local found = false
			for i = 1,#breakpoints do
				if gbCPU.PC == breakpoints[i] and i ~= curBreakPoint then
					found = true
					curBreakPoint = i
					break
				end
			end
			if not found then
				gbCPU.executeInstruction()
				curBreakPoint = -1
			else
				break
			end
		end
	end
	if k == "c" then--til breakpoint
		local breakpoints = {0x34,0x100}
		while true  do
			local found = false
			for i = 1,#breakpoints do
				if gbCPU.PC == breakpoints[i] and i ~= curBreakPoint then
					found = true
					curBreakPoint = i
					break
				end
			end
			if not found then
				gbCPU.executeInstruction(true)
				curBreakPoint = -1
			else
				break
			end
		end
	end
	if k == "t" then
		--print("executing instruction")
		gbCPU.A = 16
		gbCPU.B = 1
		gbCPU.runInstruction(0x90)
	end
end
