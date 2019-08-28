local Slab = require("Slab.Slab")
local json = require("cjson")

function string.split (str,sep)
	if type(str)=="number" or type(str)=="boolean" then
		str = tostring(str) -- Convert the bad object to a string.
	elseif type(str)=="table" then
		error("Cannot split a table.") -- You cannot simply tostring a table. Besides, I doubt anyone would like to do this anyways.
	end
	local return_array = {} -- The return value.
	sep = sep or "%s" -- Lua space value is %s
	for Lstr_01 in string.gmatch(str, "([^"..sep.."]+)") do
		return_array[#return_array+1] = Lstr_01
	end
	return return_array
end

function loveload(args)
	
	local f = io.open("dmgops.json","r")
	local d = f:read("*a")
	f:close()
	jdataP = json.decode(d).CBPrefixed
	jdataU = json.decode(d).Unprefixed
	
	Slab.Initialize(args)
	
	--gbCPU.executeInstruction()
	--gbCPU.executeInstruction()
	--love.keyboard.setKeyRepeat(true)


	--local cpu = require("cpu")
	local gen = require("geninst")
	debg = false
	if arg[#arg] == "-debug" then 
		require("mobdebug").start() 
		debg = true
	end

	local out,out2 = gen("opcode-desc.txt")
	--print("DONE")
	--print(out)
	--[[
	file = io.open("cpu.lua","r")
	dat = file:read("*a")
	--print(out)
	dat = dat:gsub("--%$instructions%$",out)
	dat = dat:gsub("--%$instructionsCB%$",out2)
	file:close()
	file = io.open("cpu2.lua","w")
	file:write(dat)
	file:close()]]--
	local cpu = require("cpu2")
	
	gbCPU = cpu()
	love.graphics.setBackgroundColor(0.4, 0.88, 1.0)
	
	consolas = love.graphics.newFont("consola.ttf",12)
	--print(consolas)
	--love.graphics.setFont(consolas)
	Slab.PushFont(consolas)
	cpuwin = true
	memwin = true
	dbgwin = true
	brkwin = true
	memoff = 0
	follow = false
	cstep = 1337
end

function loveupdate(dt)
	love.window.setTitle(love.timer.getFPS().." FPS")
	Slab.Update(dt)
	
	if brkwin then
		Slab.BeginWindow("brk",{Title="Break points",X=875})
			Slab.Text("WIP")
		Slab.EndWindow()
	end
	
	if dbgwin then
		Slab.BeginWindow("debug",{Title="Dissassembly",X = 700})
		
			Slab.Text("Next Instruction:")
			
			local name = ""
			local pr = print
			print = function() end
			local inst = gbCPU.mem.getByte(gbCPU.PC)+1
			local hex = "0x"..string.format("%02x",inst-1)
			--print("0x"..string.format("%x",inst-1))
			local function flg(f)
				local str = ""
				for l,k in pairs(f) do
					str = str..l..": "..k.." "
				end
				return str
			end
			local flgs = ""
			local clk = ""
			if inst-1 == 0xcb then
				inst2 = gbCPU.mem.getByte(gbCPU.PC+1)+1
				name = jdataP[inst2].Name 
				flgs = flg(jdataP[inst2].Flags)
				hex = hex.."..0x"..string.format("%02x",inst2-1)
				if jdataP[inst2].TCyclesNoBranch == jdataP[inst2].TCyclesBranch then
					clk = jdataP[inst2].TCyclesNoBranch
				else
					clk = jdataP[inst2].TCyclesNoBranch.."/"..jdataP[inst2].TCyclesBranch
				end
			else
				name = jdataU[inst].Name
				flgs = flg(jdataU[inst].Flags)
				if jdataU[inst].TCyclesNoBranch == jdataU[inst].TCyclesBranch then
					clk = jdataU[inst].TCyclesNoBranch
				else
					clk = jdataU[inst].TCyclesNoBranch.."/"..jdataU[inst].TCyclesBranch
				end
			end
			--print = pr
			
			--find and grab immediate to help with readability
			s = name:find(" ")
			local sinst = ""
			if s then
				sinst = name:sub(1,s)
				arg = name:sub(s+1):split(",")
				--print(arg[1],arg[2])
				local off = 1
				for r = 1,#arg do
					a = string.lower(arg[r])
					--print(a)
					if a == "a" then
						sinst = sinst..gbCPU.A
					elseif a == "b" then
						sinst = sinst..gbCPU.B
					elseif a == "c" then
						sinst = sinst..gbCPU.C
					elseif a == "d" then
						sinst = sinst..gbCPU.D
					elseif a == "e" then
						sinst = sinst..gbCPU.E
					elseif a == "h" then
						sinst = sinst..gbCPU.H
					elseif a == "l" then
						sinst = sinst..gbCPU.L
					elseif a == "pc" then
						sinst = sinst..gbCPU.PC
					elseif a == "sp" then
						sinst = sinst..gbCPU.SP
					elseif a == "u8" then
						sinst = sinst..gbCPU.mem[gbCPU.PC+off]
						off = off + 1
					elseif a == "u16" then
						sinst = sinst..gbCPU.mem.getByte(gbCPU.PC+off) + bit.lshift(gbCPU.mem.getByte(gbCPU.PC+off+1),8)
						off = off + 2
					else
						sinst = sinst..arg[r]
					end
					if r ~= #arg then
						sinst = sinst..","
					end
				end
			end
			print = pr
			Slab.Text(name)
			Slab.Text(sinst)
			Slab.Text(flgs)
			Slab.Text("cycles: "..clk)
			Slab.Text("inst: "..hex)
			
		Slab.EndWindow()
	end
	
	if memwin then
		Slab.BeginWindow('mem', {Title = "Memory",X = 250})
			Slab.Text("Offset")
			Slab.SameLine()
			if follow then memoff = math.floor(gbCPU.PC/16)*16 end
			if Slab.Input("offs",{ReturnOnText = false,W=80,Text = tostring(memoff),ReadOnly = follow}) then
				memoff = math.floor(Slab.GetInputNumber()/16)*16
			end
			Slab.SameLine()
			if Slab.CheckBox(follow, "Follow PC",{Tooltip = "Makes sure PC is always in view"}) then
				follow = not follow
			end
			Slab.Separator()
			for i = 1,16 do--lines
				Slab.Text(string.format("0x%04x |",memoff+(i-1)*16),{Color = {1,1,1}})
				Slab.SameLine()
				local line = ""
				for j = 1,16 do--columns
					--love.graphics.print(string.format("0x%x,0x%x,0x%x,0x%x",gbCPU.mem.zeroPage[j],gbCPU.mem.zeroPage[j+1],gbCPU.mem.zeroPage[j+2],gbCPU.mem.zeroPage[j+3]),300,i*15+10)
					--print(memoff+(i-1)*16+(j-1))
					local pr = print
					print = function() end
					local offset = memoff+((i-1)*16)+(j-1)
					local num = gbCPU.mem.getByte(offset)
					print = pr
					--num = 0
					--print(num)
					local dfpc = math.abs(gbCPU.PC-(memoff+(i-1)*16))
					if gbCPU.PC >= memoff and dfpc < 16 then
						if offset == gbCPU.PC then
							Slab.Text(string.format("%02x",num),{Color = {0.2,0.8,0.2}})
							Slab.SameLine({Pad=3})
						else
							Slab.Text(string.format("%02x",num))
							Slab.SameLine({Pad=3})
						end
					else
						line = line..string.format("%02x ",num)
					end
				end
				Slab.Text(line)
			end
			
		Slab.EndWindow()
	end
	
	if cpuwin then
		Slab.BeginWindow('cpu', {Title = "Cpu Debug"})
			Slab.Text(string.format("A 0x%x(%d)",gbCPU.A,gbCPU.A) )
			Slab.SameLine()
			if Slab.Input("A",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.A)}) then
				gbCPU.A = Slab.GetInputNumber()
			end
			Slab.Text(string.format("B 0x%x(%d)",gbCPU.B,gbCPU.B) )
			Slab.SameLine()
			if Slab.Input("B",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.B)}) then
				gbCPU.B = Slab.GetInputNumber()
			end
			Slab.Text(string.format("C 0x%x(%d)",gbCPU.C,gbCPU.C) )
			Slab.SameLine()
			if Slab.Input("C",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.C)}) then
				gbCPU.C = Slab.GetInputNumber()
			end
			Slab.Text(string.format("D 0x%x(%d)",gbCPU.D,gbCPU.D) )
			Slab.SameLine()
			if Slab.Input("D",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.D)}) then
				gbCPU.D = Slab.GetInputNumber()
			end
			Slab.Text(string.format("E 0x%x(%d)",gbCPU.E,gbCPU.E) )
			Slab.SameLine()
			if Slab.Input("E",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.E)}) then
				gbCPU.E = Slab.GetInputNumber()
			end
			Slab.Text(string.format("H 0x%x(%d)",gbCPU.H,gbCPU.H) )
			Slab.SameLine()
			if Slab.Input("H",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.H)}) then
				gbCPU.H = Slab.GetInputNumber()
			end
			Slab.Text(string.format("L 0x%x(%d)",gbCPU.L,gbCPU.L) )
			Slab.SameLine()
			if Slab.Input("L",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.L)}) then
				gbCPU.L = Slab.GetInputNumber()
			end
			Slab.Text("F "..gbCPU.F)
			Slab.SameLine()
			if Slab.Input("F",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.F)}) then
				gbCPU.F = Slab.GetInputNumber()
			end
			
			
			--Slab.Text("Z ".. (bit.band(gbCPU.F,0x80)>0 and 1 or 0) .." N ".. (bit.band(gbCPU.F,0x40)>0 and 1 or 0) .." H ".. (bit.band(gbCPU.F,0x20)>0 and 1 or 0) .." C ".. (bit.band(gbCPU.F,0x10)>0 and 1 or 0) )
			local z = (bit.band(gbCPU.F,0x80)>0 and true or false)
			if Slab.CheckBox(z, "Z",{Tooltip = "Zero Flag"}) then
				if not z then gbCPU.F = bor(gbCPU.F,0x80) else gbCPU.F = band(gbCPU.F,0x7F) end
			end
			Slab.SameLine()
			local n = (bit.band(gbCPU.F,0x40)>0 and true or false)
			if Slab.CheckBox(n, "N",{Tooltip = "Subtract Flag"}) then
				if not n then gbCPU.F = bor(gbCPU.F,0x40) else gbCPU.F = band(gbCPU.F,0xBF) end
			end
			Slab.SameLine()
			local h = (bit.band(gbCPU.F,0x20)>0 and true or false)
			if Slab.CheckBox(h, "H",{Tooltip = "Half Carry Flag"}) then
				if not h then gbCPU.F = bor(gbCPU.F,0x20) else gbCPU.F = band(gbCPU.F,0xDF) end
			end
			Slab.SameLine()
			local c = (bit.band(gbCPU.F,0x10)>0 and true or false)
			if Slab.CheckBox(c, "N",{Tooltip = "Subtract Flag"}) then
				if not c then gbCPU.F = bor(gbCPU.F,0x10) else gbCPU.F = band(gbCPU.F,0xEF) end
			end
			
			Slab.Text(string.format("SP 0x%x(%d)",gbCPU.SP,gbCPU.SP))
			Slab.SameLine()
			if Slab.Input("SP",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.SP)}) then
				gbCPU.SP = Slab.GetInputNumber()
			end
			Slab.Text("PC "..gbCPU.PC..string.format(" 0x%x",gbCPU.PC))
			Slab.SameLine()
			if Slab.Input("PC",{ReturnOnText = false,W = 50,Text = tostring(gbCPU.PC)}) then
				gbCPU.PC = Slab.GetInputNumber()
			end
			Slab.Text("cycles "..gbCPU.cycles)
			if Slab.Button("Step",{W = 40,H = 18}) then
				gbCPU.executeInstruction(true)
			end
			Slab.SameLine()
			if Slab.Button("+100",{W = 40,H = 18}) then
				for i = 1,100 do
					gbCPU.executeInstruction()
				end
				print(100)
			end
			Slab.SameLine()
			if Slab.Button("+1000",{W = 40,H = 18}) then
				for i = 1,1000 do
					gbCPU.executeInstruction()
				end
				print(1000)
			end
			if Slab.Button("custom",{W = 60,H = 18}) then
				for i = 1,cstep do                                                          
					gbCPU.executeInstruction()
				end
				print("stepped "..cstep.." times")
			end
			Slab.SameLine()
			if Slab.Input("custom",{ReturnOnText = false, W = 80, Text = tostring(cstep)}) then
				cstep = Slab.GetInputNumber()
			end
		Slab.EndWindow()
	end
	
	if Slab.BeginMainMenuBar() then
		if Slab.BeginMenu("File") then
			

			if Slab.MenuItem("Quit") then
				love.event.quit()
			end

			Slab.EndMenu()
		end
		if Slab.BeginMenu("tools") then
			if Slab.MenuItemChecked("Cpu Debug", cpuwin) then
				cpuwin = not cpuwin
			end
			if Slab.MenuItemChecked("Memory View", memwin) then
				memwin = not memwin
			end
			if Slab.MenuItemChecked("Dissassembly", dbgwin) then
				dbgwin = not dbgwin
			end
			if Slab.MenuItemChecked("BreakPoints", brkwin) then
				brkwin = not brkwin
			end
			Slab.EndMenu()
		end

		Slab.EndMainMenuBar()
	end
end

function lovedraw()
	--[[
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
	]]
	Slab.Draw()
end

local curBreakPoint = -1

--inputs--


function love.keypressed(k)
	return--[[
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
		local breakpoints = {0x0c,0x34,0x40,0xE0,0x100}
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
	end]]
end

print(debg)
if debg then
	function love.update(a) err,msg = pcall(loveupdate,a) end
	if not err then print("error ",msg) ; love.timer.sleep(1) end
	function love.draw(a) err,msg = pcall(lovedraw,a) end
	if not err then print("error ",msg) ; love.timer.sleep(1) end
	function love.load(a) err,msg = pcall(loveload,a) end
	if not err then print("error ",msg) ; love.timer.sleep(1) end
else
	function love.update(a) loveupdate(a) end
	function love.draw(a) lovedraw(a) end
	function love.load(a) loveload(a) end
end
