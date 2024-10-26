local Slab = require("Slab.Slab")
--local json = require("cjson")
local json = require("json")
--[[
ideas

RESET BUTTON!

I have a list of instructions, how long they take, and what flags they
affect. Maybe I could use that to improve the code generator and make things
easier for the programmer.

code generator is a mess, come up with better ideas.

possibly create a test based on a different emulator?
aka run an emulator, log everything and compare to find
differences. (jsgb seems pretty hackable)

Windows I want to add:
add memory/device registers.
GPU debug (tile sets, sprites, buffers)
game window
memory value watch window(persistant?)
breakpoints (persistant)
]]

function printTable(tabl, wid)
	if not wid then wid = 1 end
	for i, v in pairs(tabl) do
		--if type(i) == "number" then if i >= 1000 then break end end
		if type(v) == "table" then
			print(string.rep(" ", wid * 3) .. i .. " = {")
			printTable(v, wid + 1)
			print(string.rep(" ", wid * 3) .. "}")
		elseif type(v) == "string" then
			print(string.rep(" ", wid * 3) .. i .. " = \"" .. v .. "\"")
		elseif type(v) == "number" then
			print(string.rep(" ", wid * 3) .. "[" .. i .. "] = " .. v .. ",")
			if v == nil then error("nan") end
		end
	end
end

--rdat = io.open("record.json","r")
--rec = rdat:read("*a")
--rdat:close()
--record = json.decode(rec)
--printTable(record[1])

function string.split(str, sep)
	if type(str) == "number" or type(str) == "boolean" then
		str = tostring(str)      -- Convert the bad object to a string.
	elseif type(str) == "table" then
		error("Cannot split a table.") -- You cannot simply tostring a table. Besides, I doubt anyone would like to do this anyways.
	end
	local return_array = {}      -- The return value.
	sep = sep or "%s"            -- Lua space value is %s
	for Lstr_01 in string.gmatch(str, "([^" .. sep .. "]+)") do
		return_array[#return_array + 1] = Lstr_01
	end
	return return_array
end

local function updateMode1(dt)
	--4194304hz
	--print(dt)
	if running then
		--targetCycles = 4194304*(dt/2)
		targetCycles = math.min(4194304 * dt, 4194304 / 4)
		--print(dt)
		--targetCycles = 4194304*(math.min(dt,0.1)*2)
		if love.keyboard.isDown(".") then targetCycles = targetCycles * 3 end
		startCycles = gbCPU.cycles
		while gbCPU.cycles - startCycles < targetCycles do
			gbCPU.executeInstruction()
			if not running then break end
		end
		local hz = (4.194304 * 1000000)
		local sec = gbCPU.cycles / hz
		if sec > math.ceil(ls) then
			--print("saved",sec)
			local savestr = ""
			for i = 0,gbCPU.mem.ramSize-1 do
				savestr = savestr..string.char(gbCPU.mem.eRam[i])
			end
			--print(#savestr)
			local _,_,o = string.find(gbCPU.mem.fn,"/(.+).gb$")
			--print(s,e,o,t,th)
			love.filesystem.write(o..".save",savestr)
			--print(o..".save",gbCPU.mem.ramSize,#savestr)
			ls = sec
		end
	end

	angle = angle + dt * 3

	love.window.setTitle(gbCPU.mem.fn .. " " .. love.timer.getFPS() .. " FPS")

	function drawTile(t, offx, offy)
		for y = 1, 8 do
			for x = 1, 8 do
				if t then
					local c = t[y - 1][x - 1]
					if c == 0 then
						love.graphics.setColor(1, 1, 1)
					elseif c == 1 then
						love.graphics.setColor(0.6, 0.6, 0.6)
					elseif c == 2 then
						love.graphics.setColor(0.3, 0.3, 0.3)
					elseif c == 3 then
						love.graphics.setColor(0, 0, 0)
					end
					love.graphics.points(x + offx, y + offy)
				end
			end
		end
		--print(offx,offy)
	end

	--print(bit.band(0,0xFF))
	--print(bit.band(-1,0xFF))

	if lcdwin then
		love.graphics.setCanvas(lcdCanvas)
		love.graphics.clear({ 0.5, 0.3, 0.3 })
		for x = 0, 159 do
			for y = 0, 143 do
				c = gbCPU.gpu.scrdata[x][y]
				if c then
					--love.graphics.setColor(gbCPU.gpu.palette[c])
					if not colorPalette[c] then
						printTable(c); print("c")
					end
					love.graphics.setColor(colorPalette[c])
					if breaking then
						if y == gbCPU.gpu.line - 1 then
							love.graphics.setColor(1, 0, 0)
						end
					end
					love.graphics.points(x, y)
				end
			end
		end
		love.graphics.setCanvas()

		--Slab.BeginWindow("lcd", { Title = "LCD", Y = 195, DisableDocks = { "Left", "Right", "Bottom" } }) --,AllowResize = true,AutoSizeWindow = false})
		Slab.BeginWindow("lcd", { Title = gbCPU.mem.title, Y = 195, DisableDocks = { "Left", "Right", "Bottom" } }) --,AllowResize = true,AutoSizeWindow = false})
		Slab.Image("img", { Image = lcdCanvas, Scale = 2 })
		Slab.EndWindow()
	end

	if canwin then                                                                                         --gpu canvas view https://gbdev.io/pandocs/Tile_Maps.html
		Slab.BeginWindow("can", { Title = "GPU canvas", Y = 195, DisableDocks = { "Left", "Right", "Bottom" } }) --,AllowResize = true,AutoSizeWindow = false})
		love.graphics.setCanvas(canvas1)
		love.graphics.clear({ 0.5, 0.3, 0.3 })
		--draw here
		for y = 1, 32 do
			for x = 1, 32 do
				local tilenum = 1
				--addressing mode from LCD control register
				local n = ((y - 1) * 32) + (x - 1)
				--n = n + 128

				if gbCPU.gpu.bgmap then
					n = n + 0x9C00
				else
					n = n + 0x9800
				end
				if not gbCPU.gpu.bgtile then
					--n = n + 0x400
					tilenum = gbCPU.gpu.vram[bit.band(n, 0x1FFF)]
					if bit.band(tilenum, 0x80) > 0 then
						tilenum = -(bit.band(bit.bnot(tilenum), 0xFF) + 1)
					end
					tilenum = 256 + tilenum
				else
					tilenum = gbCPU.gpu.vram[bit.band(n, 0x1FFF)]
				end
				drawTile(gbCPU.gpu.tileSet[tilenum], (x - 1) * 8, (y - 1) * 8)
			end
		end
		love.graphics.setColor(1, 0, 0)
		love.graphics.rectangle("line", 00 + gbCPU.gpu.scrollX, 0 + gbCPU.gpu.scrollY, 160, 144)
		love.graphics.setColor(0, 1, 0)
		love.graphics.rectangle("line", 00 + gbCPU.gpu.winX, 0 + gbCPU.gpu.winY, 160, 144)
		--error()
		love.graphics.setCanvas()
		Slab.Image("img", { Image = canvas1, Scale = 1 })
		Slab.EndWindow()
	end

	if palettewin then
		love.graphics.setCanvas(palcanv)
		---love.graphics.clear({1,1,1})
		for i = 0, 3 do
			love.graphics.setColor(colorPalette[gbCPU.gpu.palette[i]])
			love.graphics.points(i + 1, 1)
		end
		for i = 0, 3 do
			love.graphics.setColor(colorPalette[gbCPU.gpu.obp0[i]])
			love.graphics.points(i + 1, 2)
		end
		for i = 0, 3 do
			love.graphics.setColor(colorPalette[gbCPU.gpu.obp1[i]])
			love.graphics.points(i + 1, 3)
		end
		love.graphics.setCanvas()
		Slab.BeginWindow("palette", { Title = "Palette view", X = 700, Y = 610 }) --,AllowResize = true,AutoSizeWindow = false})
		Slab.Image("img", { Image = palcanv, ScaleX = 30, ScaleY = 30 })
		Slab.EndWindow()
	end

	if countwin then
		Slab.BeginWindow("count", { Title = "Frame count", X = 200, Y = 410 }) --,AllowResize = true,AutoSizeWindow = false})
		Slab.Text("Count: " .. count)
		Slab.Text(gbCPU.gpu.frames)
		Slab.Text(math.floor(gbCPU.gpu.fps + 0.5))
		Slab.EndWindow()
		count = count + 1
	end

	if tilewin then
		Slab.BeginWindow("tiles", { Title = "Tile Viewer", X = 200, Y = 400 }) --,AllowResize = true,AutoSizeWindow = false})
		love.graphics.setCanvas(tiles1)
		for i = 0, 0x180 do                                              --render all the tiles in the fist page
			local tx = i % 16
			local ty = math.floor(i / 16)
			--tx,ty = tx+1,ty+1
			local offx, offy = tx * 8, ty * 8
			--print(tx,ty)
			drawTile(gbCPU.gpu.tileSet[i], offx, offy)
		end
		love.graphics.setCanvas()
		Slab.Image("img", { Image = tiles1, Scale = 1 })
		Slab.EndWindow()
	end

	if timerwin then
		Slab.BeginWindow("timer", { Title = "TIMER status", Y = 400 }) --,AllowResize = true,AutoSizeWindow = false})
		Slab.Text("clock " .. string.format("0x%02x", gbCPU.timer.clock))
		Slab.Text("04, DIV " .. string.format("0x%02x", gbCPU.mem.getByte(0xFF04)))
		Slab.Text("05, TIMA " .. string.format("0x%02x", gbCPU.timer.TIMA))
		Slab.Text("06, TMA " .. string.format("0x%02x", gbCPU.timer.TMA))
		Slab.Text("07, TAC " .. string.format("0x%02x", gbCPU.timer.TAC))
		Slab.EndWindow()
	end

	if gpuwin then
		Slab.BeginWindow("gpu", { Title = "GPU status", Y = 400 }) --,AllowResize = true,AutoSizeWindow = false})
		Slab.Text("ScrollX " .. string.format("0x%02x", gbCPU.gpu.scrollX))
		Slab.SameLine()
		if Slab.Input("scrollx", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.gpu.scrollX) }) then
			gbCPU.gpu.scrollX = Slab.GetInputNumber()
		end
		Slab.Text("ScrollY " .. string.format("0x%02x", gbCPU.gpu.scrollY))
		Slab.SameLine()
		if Slab.Input("scrolly", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.gpu.scrollY) }) then
			gbCPU.gpu.scrollY = Slab.GetInputNumber()
		end
		Slab.Text("GPU Line: " .. tostring(gbCPU.gpu.line))
		Slab.Text("WIN Line: " .. tostring(gbCPU.gpu.wLine))
		Slab.Text("LCDC " .. string.format("0x%02x", gbCPU.gpu.lcdc))
		--[[
		Slab.Text("LCDC.0 " .. tostring(gbCPU.gpu.switchbg))
		Slab.Text("LCDC.1 " .. tostring(gbCPU.gpu.objEnable))
		Slab.Text("LCDC.2 " .. tostring(gbCPU.gpu.objSize))
		Slab.Text("LCDC.3 " .. tostring(gbCPU.gpu.bgmap))
		Slab.Text("LCDC.4 " .. tostring(gbCPU.gpu.bgtile))
		Slab.Text("LCDC.5 " .. tostring(gbCPU.gpu.winEnable))
		Slab.Text("LCDC.6 " .. tostring(gbCPU.gpu.winMap))
		Slab.Text("LCDC.7 " .. tostring(gbCPU.gpu.switchlcd))]]
		Slab.Text("Bg/win:   " .. tostring(gbCPU.gpu.switchbg))
		Slab.Text("Obj en:   " .. tostring(gbCPU.gpu.objEnable))
		Slab.Text("Obj size: " .. tostring(gbCPU.gpu.objSize))
		Slab.Text("bg map:   " .. tostring(gbCPU.gpu.bgmap))
		Slab.Text("bg & win: " .. tostring(gbCPU.gpu.bgtile))
		Slab.Text("win en:   " .. tostring(gbCPU.gpu.winEnable))
		Slab.Text("win map:  " .. tostring(gbCPU.gpu.winMap))
		Slab.Text("ppu en:   " .. tostring(gbCPU.gpu.switchlcd))
		Slab.EndWindow()
	end

	if brkwin then
		Slab.BeginWindow("brk", { Title = "Break points", X = 875 }) --,AllowResize = true,AutoSizeWindow = false})
		Slab.Text("Input addresses seperated by commas or newlines")
		--Slab.Text(string.format("0x%02x",gbCPU.PC))
		local tt = nil
		if not brkf then
			local bf = io.open("breakpoints.txt", "r")
			tt = bf:read("*a")
			bf:close()
			txt = tt:gsub("\n", ",")
			local lst = txt:split(",")
			local n = 0
			breakPointList = {}
			for b = 1, #lst do
				if tonumber(lst[b]) then
					breakPointList[tonumber(lst[b])] = true
					n = n + 1
				end
			end
			breakPointList.num = n
		end
		if Slab.Input("bp", { Text = tt, MultiLine = true, Highlight = { [string.format("0x%02x", gbCPU.PC)] = { 0.2, 0.9, 0.2 }, ["test"] = { 1, 0, 0 } }, H = 200, W = 225, SelectOnFocus = false }) then
			local txt = Slab.GetInputText()
			--save to a file for persistance
			local bf = io.open("breakpoints.txt", "w")
			bf:write(txt)
			bf:close()
			txt = txt:gsub("\n", ",")
			local lst = txt:split(",")
			local n = 0
			breakPointList = {}
			for b = 1, #lst do
				if tonumber(lst[b]) then
					breakPointList[tonumber(lst[b])] = true
					n = n + 1
				end
			end
			breakPointList.num = n
		end
		Slab.SameLine()
		if Slab.Button("Next") then
			local file = io.open("log.txt", "w")
			local f = love.timer.getTime()
			--step until breakpoint
			if breakPointList.num and breakPointList.num > 0 then
				for _ = 1, 300000 do
					--gbCPU.executeInstruction()
					file:write(string.format(
						"A: %02x F: %02x B: %02x C: %02x D: %02x E: %02x H: %02x L: %02x SP: %04x PC: 00:%04x \n",
						gbCPU.A,
						gbCPU.F, gbCPU.B, gbCPU.C, gbCPU.D, gbCPU.E, gbCPU.H, gbCPU.L, gbCPU.SP, gbCPU.PC))
					if checking then stepCheck() else gbCPU.executeInstruction() end
					if breakPointList[gbCPU.PC] == true then
						print("broke")
						break
					end
					--if numExecuted == 406770 then
					--if numExecuted == 406751 then
					--if lastSP ~= gbCPU.SP and gbCPU.SP == 0xDF6A and fnotsame then
					--print("next one "..lastPC)
					--if numExecuted == 2333 then
					--	break
					--end
					--if lastSP ~= gbCPU.SP then
					--	print("push or pull "..gbCPU.PC)
					--end
					--lastPC = gbCPU.PC
					--lastSP = gbCPU.SP
				end
			end
			local e = love.timer.getTime()
			print(math.abs(f - e))
			--local ff = io.open("instran.txt","w")
			--for i,k in pairs(gbCPU.instsran) do
			--	print(string.format("%02x",i))
			--	ff:write(string.format("%02x",i).."\n")
			--end
			--ff:close()
		end
		--Slab.Image("game",{Image = canvas,Scale = 2})

		Slab.EndWindow()
	end
	--print(bit.bnot(5))
	if dbgwin then
		Slab.BeginWindow("debug", { Title = "Dissassembly", X = 700 })

		Slab.Text("Next Instruction:")

		local name = ""
		local pr = print
		print = function() end
		local inst = gbCPU.mem.getByte(gbCPU.PC) + 1
		local hex = "0x" .. string.format("%02x", inst - 1)
		--print("0x"..string.format("%x",inst-1))
		local function flg(f)
			local str = ""
			for l, k in pairs(f) do
				str = str .. l .. ": " .. k .. " "
			end
			return str
		end
		local flgs = ""
		local clk = ""
		if inst - 1 == 0xcb then
			inst2 = gbCPU.mem.getByte(gbCPU.PC + 1) + 1
			name = jdataP[inst2].Name
			flgs = flg(jdataP[inst2].Flags)
			hex = hex .. "..0x" .. string.format("%02x", inst2 - 1)
			if jdataP[inst2].TCyclesNoBranch == jdataP[inst2].TCyclesBranch then
				clk = jdataP[inst2].TCyclesNoBranch
			else
				clk = jdataP[inst2].TCyclesNoBranch .. "/" .. jdataP[inst2].TCyclesBranch
			end
		else
			name = jdataU[inst].Name
			flgs = flg(jdataU[inst].Flags)
			if jdataU[inst].TCyclesNoBranch == jdataU[inst].TCyclesBranch then
				clk = jdataU[inst].TCyclesNoBranch
			else
				clk = jdataU[inst].TCyclesNoBranch .. "/" .. jdataU[inst].TCyclesBranch
			end
		end
		--print = pr

		--find and grab immediate to help with readability
		s = name:find(" ")
		local sinst = ""
		if s then
			sinst = name:sub(1, s)
			arg = name:sub(s + 1):split(",")
			--print(arg[1],arg[2])
			local off = 1
			--sinst = sinst..arg[1]..","
			for r = 1, #arg do
				a = string.lower(arg[r])
				--print(a)
				if a == "a" then
					sinst = sinst .. gbCPU.A
				elseif a == "b" then
					sinst = sinst .. gbCPU.B
				elseif a == "c" then
					sinst = sinst .. gbCPU.C
				elseif a == "d" then
					sinst = sinst .. gbCPU.D
				elseif a == "e" then
					sinst = sinst .. gbCPU.E
				elseif a == "h" then
					sinst = sinst .. gbCPU.H
				elseif a == "l" then
					sinst = sinst .. gbCPU.L
				elseif a == "pc" then
					sinst = sinst .. gbCPU.PC
				elseif a == "sp" then
					sinst = sinst .. gbCPU.SP
				elseif a == "u8" then
					print(gbCPU.PC, off, sinst)
					sinst = sinst .. gbCPU.mem.getByte(gbCPU.PC + off)
					off = off + 1
				elseif a == "u16" then
					sinst = sinst ..
						gbCPU.mem.getByte(gbCPU.PC + off) + bit.lshift(gbCPU.mem.getByte(gbCPU.PC + off + 1),
							8)
					off = off + 2
				else
					sinst = sinst .. arg[r]
				end
				if r ~= #arg then
					sinst = sinst .. ","
				end
			end
		end
		print = pr
		Slab.Text(name)
		Slab.Text(sinst)
		Slab.Text(flgs)
		Slab.Text("cycles: " .. clk)
		Slab.Text("inst: " .. hex)
		Slab.EndWindow()
	end

	if stackwin then
		Slab.BeginWindow('stack', { Title = "Stack", X = 275 })
		local memoffs = gbCPU.SP + 16
		for i = 1, 16 do --lines
			if i == 9 then
				--print(string.format("0x%04x |",memoffs-(i-1)*2))
				Slab.Text(string.upper(string.format("0x%04x |", memoffs - (i - 1) * 2)), { Color = { 0.5, 1, 0.5 } })
				--Slab.Text("nine")
			else
				Slab.Text(string.upper(string.format("0x%04x |", memoffs - (i - 1) * 2)), { Color = { 1, 1, 1 } })
			end
			Slab.SameLine()
			--local line = ""
			local by1 = 0
			local by2 = 0
			if (memoffs - (i - 1) * 2) + 1 <= 0xFFFF then
				by1 = (memoffs - (i - 1) * 2) + 1
				by2 = memoffs - (i - 1) * 2
			end
			--print(memoffs,i,gbCPU.SP,by1,by2)
			if by1 >= 0 and by2 >= 0 then Slab.Text(string.upper(string.format("0x%02x%02x", gbCPU.mem.getByte(by1),gbCPU.mem.getByte(by2)))) end
		end

		Slab.EndWindow()
	end

	if memwin then
		Slab.BeginWindow('mem', { Title = "Memory", X = 275 })
		Slab.Text("Offset")
		Slab.SameLine()
		if follow then memoff = math.min(math.floor(gbCPU.PC / 16) * 16, 0xFF00) end
		if Slab.Input("offs", { ReturnOnText = false, W = 80, Text = tostring(memoff), ReadOnly = follow }) then
			memoff = math.min(math.floor(Slab.GetInputNumber() / 16) * 16, 0xFF00)
		end
		Slab.SameLine()
		if Slab.CheckBox(follow, "Follow PC", { Tooltip = "Makes sure PC is always in view" }) then
			follow = not follow
		end
		Slab.Separator()
		for i = 1, 16 do --lines
			Slab.Text(string.format("0x%04x |", memoff + (i - 1) * 16), { Color = { 1, 1, 1 } })
			Slab.SameLine()
			local line = ""
			for j = 1, 16 do --columns
				--love.graphics.print(string.format("0x%x,0x%x,0x%x,0x%x",gbCPU.mem.zeroPage[j],gbCPU.mem.zeroPage[j+1],gbCPU.mem.zeroPage[j+2],gbCPU.mem.zeroPage[j+3]),300,i*15+10)
				--print(memoff+(i-1)*16+(j-1))
				local pr = print
				print = function() end
				local offset = memoff + ((i - 1) * 16) + (j - 1)
				local num = gbCPU.mem.getByte(offset)
				print = pr
				--num = 0
				--print(num)
				local dfpc = math.abs(gbCPU.PC - (memoff + (i - 1) * 16))
				if gbCPU.PC >= memoff and dfpc < 16 then
					if offset == gbCPU.PC then
						Slab.Text(string.format("%02x", num), { Color = { 0.2, 0.8, 0.2 } })
						Slab.SameLine({ Pad = 3 })
					else
						Slab.Text(string.format("%02x", num))
						Slab.SameLine({ Pad = 3 })
					end
				else
					line = line .. string.format("%02x ", num)
				end
			end
			Slab.Text(line)
		end

		Slab.EndWindow()
	end

	if cpuwin then
		Slab.BeginWindow('cpu', { Title = "Cpu Debug", ResetPosition = true, X = 10, Y = 25 })
		Slab.Text(string.format("A 0x%02x", gbCPU.A))
		Slab.SameLine()
		if Slab.Input("A", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.A) }) then
			gbCPU.A = Slab.GetInputNumber()
		end
		Slab.Text(string.format("B 0x%02x", gbCPU.B))
		Slab.SameLine()
		if Slab.Input("B", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.B) }) then
			gbCPU.B = Slab.GetInputNumber()
		end
		Slab.Text(string.format("C 0x%02x", gbCPU.C))
		Slab.SameLine()
		if Slab.Input("C", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.C) }) then
			gbCPU.C = Slab.GetInputNumber()
		end
		Slab.Text(string.format("D 0x%02x", gbCPU.D))
		Slab.SameLine()
		if Slab.Input("D", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.D) }) then
			gbCPU.D = Slab.GetInputNumber()
		end
		Slab.Text(string.format("E 0x%02x", gbCPU.E))
		Slab.SameLine()
		if Slab.Input("E", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.E) }) then
			gbCPU.E = Slab.GetInputNumber()
		end
		Slab.Text(string.format("H 0x%02x", gbCPU.H))
		Slab.SameLine()
		if Slab.Input("H", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.H) }) then
			gbCPU.H = Slab.GetInputNumber()
		end
		Slab.Text(string.format("L 0x%02x", gbCPU.L))
		Slab.SameLine()
		if Slab.Input("L", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.L) }) then
			gbCPU.L = Slab.GetInputNumber()
		end
		Slab.Text(string.format("F 0x%02x", gbCPU.F))
		Slab.SameLine()
		if Slab.Input("F", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.F) }) then
			gbCPU.F = Slab.GetInputNumber()
		end


		--Slab.Text("Z ".. (bit.band(gbCPU.F,0x80)>0 and 1 or 0) .." N ".. (bit.band(gbCPU.F,0x40)>0 and 1 or 0) .." H ".. (bit.band(gbCPU.F,0x20)>0 and 1 or 0) .." C ".. (bit.band(gbCPU.F,0x10)>0 and 1 or 0) )
		local z = (bit.band(gbCPU.F, 0x80) > 0 and true or false)
		if Slab.CheckBox(z, "Z", { Tooltip = "Zero Flag" }) then
			if not z then gbCPU.F = bor(gbCPU.F, 0x80) else gbCPU.F = band(gbCPU.F, 0x7F) end
		end
		Slab.SameLine()
		local n = (bit.band(gbCPU.F, 0x40) > 0 and true or false)
		if Slab.CheckBox(n, "N", { Tooltip = "Subtract Flag" }) then
			if not n then gbCPU.F = bor(gbCPU.F, 0x40) else gbCPU.F = band(gbCPU.F, 0xBF) end
		end
		Slab.SameLine()
		local h = (bit.band(gbCPU.F, 0x20) > 0 and true or false)
		if Slab.CheckBox(h, "H", { Tooltip = "Half Carry Flag" }) then
			if not h then gbCPU.F = bor(gbCPU.F, 0x20) else gbCPU.F = band(gbCPU.F, 0xDF) end
		end
		Slab.SameLine()
		local c = (bit.band(gbCPU.F, 0x10) > 0 and true or false)
		if Slab.CheckBox(c, "C", { Tooltip = "Carry Flag" }) then
			if not c then gbCPU.F = bor(gbCPU.F, 0x10) else gbCPU.F = band(gbCPU.F, 0xEF) end
		end

		Slab.Text(string.format("SP 0x%04x", gbCPU.SP))
		Slab.SameLine()
		if Slab.Input("SP", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.SP) }) then
			gbCPU.SP = Slab.GetInputNumber()
		end
		Slab.Text("PC " .. string.format("0x%04x", gbCPU.PC))
		Slab.SameLine()
		if Slab.Input("PC", { ReturnOnText = false, W = 50, Text = tostring(gbCPU.PC) }) then
			gbCPU.PC = Slab.GetInputNumber()
		end
		if Slab.CheckBox(gbCPU.IME, "IME", { Tooltip = "Interupt enable" }) then
			gbCPU.IME = not gbCPU.IME
		end
		Slab.SameLine()
		if Slab.CheckBox(gbCPU.HALT, "HALT", { Tooltip = "CPU HALT" }) then
			gbCPU.HALT = not gbCPU.HALT
		end
		local hz = (4.194304 * 1000000)
		Slab.Text("Cpu cycles " .. gbCPU.cycles)
		Slab.Text("(" .. string.format("%.4f", gbCPU.cycles / hz) .. ")seconds")

		Slab.Text("Run inst")
		Slab.SameLine()
		if Slab.Button("Run", { W = 40, H = 12 }) then
			gbCPU.runInstruction(instToBeRun)
		end
		if Slab.Input("Inst", { ReturnOnText = false, Text = instToBeRun }) then
			instToBeRun = Slab.GetInputNumber()
		end


		if Slab.Button("Step", { W = 40, H = 18 }) then
			gbCPU.executeInstruction(true)
		end

		Slab.SameLine()
		if Slab.Button("+100", { W = 40, H = 18 }) then
			for _ = 1, 100 do
				gbCPU.executeInstruction()
			end
			print(100)
		end
		Slab.SameLine()
		if Slab.Button("+1000", { W = 40, H = 18 }) then
			for _ = 1, 1000 do
				gbCPU.executeInstruction()
			end
			print(1000)
		end
		if Slab.Button("Custom", { W = 60, H = 18 }) then
			for _ = 1, cstep do
				gbCPU.executeInstruction()
			end
			print("stepped " .. cstep .. " times")
		end
		Slab.SameLine()
		if Slab.Input("custom", { ReturnOnText = false, W = 80, Text = tostring(cstep) }) then
			cstep = Slab.GetInputNumber()
		end
		Slab.Text("Instructions: " .. gbCPU.instructionsExecuted)
		if Slab.Button("Reset", { W = 60, H = 18 }) then
			gbCPU.reset()
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
			if Slab.MenuItemChecked("Stack View", stackwin) then
				stackwin = not stackwin
			end
			if Slab.MenuItemChecked("Dissassembly", dbgwin) then
				dbgwin = not dbgwin
			end
			if Slab.MenuItemChecked("BreakPoints", brkwin) then
				brkwin = not brkwin
			end
			if Slab.MenuItemChecked("Gpu status", gpuwin) then
				gpuwin = not gpuwin
			end
			if Slab.MenuItemChecked("Timer status", timerwin) then
				timerwin = not timerwin
			end
			if Slab.MenuItemChecked("Tilemap view", tilewin) then
				tilewin = not tilewin
			end
			if Slab.MenuItemChecked("GPU Canvas view", canwin) then
				canwin = not canwin
			end
			if Slab.MenuItemChecked("Palette view", palettewin) then
				palettewin = not palettewin
			end
			if Slab.MenuItemChecked("LCD view", lcdwin) then
				lcdwin = not lcdwin
			end
			if Slab.MenuItemChecked("Count view", countwin) then
				countwin = not countwin
			end
			Slab.EndMenu()
		end
		if Slab.BeginMenu("Shortcuts") then
			if Slab.MenuItem("JustLCD") then
				cpuwin = false
				memwin = false
				stackwin = false
				dbgwin = false
				brkwin = false
				gpuwin = false
				timerwin = false
				tilewin = false
				canwin = false
				lcdwin = true
				countwin = false
				palettewin = false
			end
			if Slab.MenuItem("All tools") then
				cpuwin = true
				memwin = true
				stackwin = true
				dbgwin = true
				brkwin = true
				gpuwin = true
				timerwin = true
				tilewin = true
				canwin = true
				lcdwin = true
				countwin = true
				palettewin = true
			end

			Slab.EndMenu()
		end

		Slab.EndMainMenuBar()
	end
	if bigboy then
		for _ = 1, 100 do
			gbCPU.executeInstruction()
			printLinkPort()
		end
	end

	--[[
	if frameInputs[gbCPU.gpu.frames+1] then
		local inp = frameInputs[gbCPU.gpu.frames+1]
		if inp[1] then gbCPU.joy.buttons.Up = 0 ; print("up") else gbCPU.joy.buttons.Up = 1 end
		if inp[2] then gbCPU.joy.buttons.Down = 0 else gbCPU.joy.buttons.Down = 1 end
		if inp[3] then gbCPU.joy.buttons.Left = 0 else gbCPU.joy.buttons.Left = 1 end
		if inp[4] then gbCPU.joy.buttons.Right = 0 else gbCPU.joy.buttons.Right = 1 end
		if inp[5] then gbCPU.joy.buttons.Start = 0 ; print("start") else gbCPU.joy.buttons.Start = 1 end
		if inp[6] then gbCPU.joy.buttons.Select = 0 else gbCPU.joy.buttons.Select = 1 end
		if inp[7] then gbCPU.joy.buttons.B = 0 else gbCPU.joy.buttons.B = 1 end
		if inp[8] then gbCPU.joy.buttons.A = 0 else gbCPU.joy.buttons.A = 1 end
	end
	]] --


	if love.keyboard.isDown("up") then gbCPU.joy.buttons.Up = 0 else gbCPU.joy.buttons.Up = 1 end
	if love.keyboard.isDown("down") then gbCPU.joy.buttons.Down = 0 else gbCPU.joy.buttons.Down = 1 end
	if love.keyboard.isDown("left") then gbCPU.joy.buttons.Left = 0 else gbCPU.joy.buttons.Left = 1 end
	if love.keyboard.isDown("right") then gbCPU.joy.buttons.Right = 0 else gbCPU.joy.buttons.Right = 1 end
	if love.keyboard.isDown("return") then gbCPU.joy.buttons.Start = 0 else gbCPU.joy.buttons.Start = 1 end
	if love.keyboard.isDown("pagedown") then gbCPU.joy.buttons.Select = 0 else gbCPU.joy.buttons.Select = 1 end
	if love.keyboard.isDown("a") then gbCPU.joy.buttons.A = 0 else gbCPU.joy.buttons.A = 1 end
	if love.keyboard.isDown("b") then gbCPU.joy.buttons.B = 0 else gbCPU.joy.buttons.B = 1 end

	--[[
	if love.keyboard.isDown("space") then gbCPU.joy.buttons.Up = 0 else gbCPU.joy.buttons.Up = 1 end
	if love.keyboard.isDown("down") then gbCPU.joy.buttons.Down = 0 else gbCPU.joy.buttons.Down = 1 end
	if love.keyboard.isDown("left") then gbCPU.joy.buttons.Left = 0 else gbCPU.joy.buttons.Left = 1 end
	if love.keyboard.isDown("right") then gbCPU.joy.buttons.Right = 0 else gbCPU.joy.buttons.Right = 1 end
	if love.keyboard.isDown("return") then gbCPU.joy.buttons.Start = 0 else gbCPU.joy.buttons.Start = 1 end
	if love.keyboard.isDown("c") then gbCPU.joy.buttons.Select = 0 else gbCPU.joy.buttons.Select = 1 end
	if love.keyboard.isDown("up") then gbCPU.joy.buttons.A = 0 else gbCPU.joy.buttons.A = 1 end
	if love.keyboard.isDown("b") then gbCPU.joy.buttons.B = 0 else gbCPU.joy.buttons.B = 1 end
	]]
end

local function setupMode1(fn)
	--local f = io.open("dmgops.json","r")
	--local d = f:read("*a")
	--f:close()
	ls = 0

	local unitTest = false

	local d, _ = love.filesystem.read("dmgops.json")
	jdataP = json.decode(d).CBPrefixed
	jdataU = json.decode(d).Unprefixed


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

	local out, out2 = gen("opcode-desc.txt")
	--print("DONE")
	--print(out)

	file = io.open("cpu.lua", "r")
	dat = file:read("*a")
	--print(out)
	dat = dat:gsub("--%$instructions%$", out)
	dat = dat:gsub("--%$instructionsCB%$", out2)
	file:close()
	file = io.open("cpu2.lua", "w")
	file:write(dat)
	file:close()
	local cpu = require("cpu2")


	local function runTest(fn)
		local d, e = love.filesystem.read(fn)
		if d then
			local testData = json.decode(d)
			--printTable(testData)
			for i = 1, 99 do --todo run json tests
				--printTable(testData[i])
				print(string.format("running test %s test number %d", testData[i].name, i))
				--print("initalizing cpu")
				local testcpu = cpu(true, testData[i].initial)
				--print("initalized cpu")
				--print(testcpu.A)
				local function testAddr(exp, addr, af, bf)
					if not af then af = "" end
					if not bf then bf = "" end
					assert(testcpu.mem.getByte(addr) == exp,
						string.format("%sMemory value didn't match%s. Expected %d at address %d but got %d",
							bf, af, exp, addr, testcpu.mem.getByte(addr)))
				end

				--we aren't cycle accurate
				--[[for c = 1,#testData[i].cycles do
					testAddr(testData[i].cycles[c][2],testData[i].cycles[c][1]," at cycle "..c)
					testcpu.executeInstruction()
					print("pc",testcpu.PC)
				end
				print("testing cycles")
				while testcpu.cycles/4 <= #testData[i].cycles do
					local c = testcpu.cycles/4
					assert(c == math.floor(testcpu.cycles/4),"cycle mismatch? ")
					if testData[i].cycles[c] then
						print(c,#testData[i].cycles)
						testAddr(testData[i].cycles[c][2],testData[i].cycles[c][1]," at cycle "..c)
					end
					if c >= #testData[i].cycles then
						break
					end
					testcpu.executeInstruction()
					print("pc",testcpu.PC)
				end]]
				testcpu.executeInstruction()
				--check for final state
				local function test(name, got, exp)
					assert(got == exp,
						string.format("Final state reg %s did not match. Expected %d, got %d", name, exp, got))
				end
				test("A", testcpu.A, testData[i].final.a)
				test("B", testcpu.B, testData[i].final.b)
				test("C", testcpu.C, testData[i].final.c)
				test("D", testcpu.D, testData[i].final.d)
				test("E", testcpu.E, testData[i].final.e)
				test("F", testcpu.F, testData[i].final.f)
				test("H", testcpu.H, testData[i].final.h)
				test("L", testcpu.L, testData[i].final.l)
				test("PC", testcpu.PC, testData[i].final.pc)
				test("SP", testcpu.SP, testData[i].final.sp)
				for a = 1, #testData[i].final.ram do
					testAddr(testData[i].final.ram[a][2], testData[i].final.ram[a][1], "", "Final ")
				end
			end
		end
	end
	if unitTest then
		for tn = 0x00, 0xff do
			if tn == 0xcb then
				for tb = 0x00, 0xFF do
					runTest(string.format("sm83/v1/cb %02x.json", tb))
				end
			else
				runTest(string.format("sm83/v1/%02x.json", tn))
			end
		end
		error("tests finished")
	end




	gbCPU = cpu(nil, nil, fn)

	local _,_,o = string.find(gbCPU.mem.fn,"/(.+).gb$")
	if love.filesystem.getInfo(o..".save") then
		print("loading save")
		local sav,siz = love.filesystem.read(o..".save")
		print(#sav,size)
		for i = 1,siz do
			gbCPU.mem.eRam[i-1] = string.byte(sav:sub(i,i))
		end
	end



	love.graphics.setBackgroundColor(0.4, 0.88, 1.0)

	--print(consolas)
	--love.graphics.setFont(consolas)
	cpuwin = true
	memwin = true
	stackwin = true
	dbgwin = true
	brkwin = true
	gpuwin = true
	timerwin = true
	tilewin = true
	canwin = true
	lcdwin = true
	countwin = true
	palettewin = true

	memoff = 0
	follow = false
	cstep = 1337
	breakPointList = {}

	running = true


	canvas = love.graphics.newCanvas(160, 144)
	canvas:setFilter("linear", "nearest")
	love.graphics.setCanvas(canvas)
	love.graphics.clear({ 0, 0.5, 0.2 })
	love.graphics.circle("fill", 50, 50, 10)
	love.graphics.setCanvas()
	angle = 0

	tiles1 = love.graphics.newCanvas(8 * 16, 8 * 24)
	canvas1 = love.graphics.newCanvas(32 * 8, 32 * 8)
	lcdCanvas = love.graphics.newCanvas(160, 144)
	lcdCanvas:setFilter("linear", "nearest")
	count = 0


	palcanv = love.graphics.newCanvas(4, 3)
	palcanv:setFilter("linear", "nearest")
	love.graphics.setCanvas(palcanv)
	love.graphics.clear({ 1, 1, 1 })
	love.graphics.setCanvas()

	epicLog = io.open("Blargg2.txt", "r")

	instToBeRun = ""

	colorPalette = {
		{ 1,   1,   1 },
		{ 0.6, 0.6, 0.6 },
		{ 0.3, 0.3, 0.3 },
		{ 0,   0,   0 }
	}

	--#081820
	--#346856
	--#88c070
	--#e0f8d0

	--[[ bgb palette
	colorPalette = {
		{0xe0,0xf8,0xd0},
		{0x88,0xc0,0x70},
		{0x34,0x68,0x56},
		{0x08,0x18,0x20}
	}
	for t = 1,4 do
		for i = 1,3 do
			colorPalette[t][i] = colorPalette[t][i]/255
		end
	end]]
end

local function setupMode0()
	angle = 0
	love.graphics.setBackgroundColor(0.4, 0.88, 1.0)
	files = love.filesystem.getDirectoryItems("")
	printTable(files)
	print(love.filesystem.getWorkingDirectory())
	Cwd = ""
	Selected = nil
	Changed = false
	Entered = false
	local fd = love.filesystem.read("selection.txt")
	if fd then
		local state = fd:split(",")
		Cwd = state[1]
		Selected = tonumber(state[2])
	end
end

local function updateMode0(dt)
	if Slab.BeginMainMenuBar() then
		if Slab.BeginMenu("File") then
			if Slab.MenuItem("Quit") then
				love.event.quit()
			end

			Slab.EndMenu()
		end

		Slab.EndMainMenuBar()
	end

	Slab.BeginWindow("File Chooser", { Title = "Pick rom file", AutoSizeWindow = false ,W = 600,H = 600})
	local w, h = Slab.GetWindowSize()
	--Slab.BeginListBox('File chooser', { W = w - 10, H = h - 10 })
	Slab.BeginListBox('File chooser', { StretchW = true, StretchH = true, Clear = Changed })
	Changed = false
	local files = love.filesystem.getDirectoryItems(Cwd)
	if #Cwd > 0 then table.insert(files, 1, ".") end
	for i = 1, #files do
		Slab.BeginListBoxItem('listBoxItem' .. i, { Selected = Selected == i })
		local txt = files[i]
		--print(love.filesystem.getInfo(files[i]).type)
		--print(Cwd .. "/" .. files[i])
		if files[i] ~= "." then
			if love.filesystem.getInfo(Cwd .. "/" .. files[i]).type == "directory" then txt = txt .. "/" end
		end
		Slab.Text(txt)
		if Slab.IsListBoxItemClicked() then
			Selected = i
		end
		if Slab.IsListBoxItemClicked(nil, true) or Entered then
			if files[Selected] == "." then
				local o = Cwd
				Cwd = string.gsub(Cwd, "/[^/]*$", "")
				if o == Cwd then Cwd = "" end --top level
				Slab.EndListBoxItem()
				Selected = nil
				Changed = true
				break
			end
			--enter directory or start gamepad
			if love.filesystem.getInfo(Cwd .. "/" .. files[Selected]).type == "directory" then
				if #Cwd > 0 then
					Cwd = Cwd .. "/" .. files[Selected]
				else
					Cwd = files[Selected]
				end
				Selected = nil
				Changed = true
				Slab.EndListBoxItem()
				break
			end
			print(files[Selected])
			if files[Selected]:sub(-3) == ".gb" then
				mode = 1
				setupMode1(Cwd .. "/" .. files[Selected])
				love.filesystem.write("selection.txt", Cwd .. "," .. Selected)
				Slab.EndListBoxItem()
				break
			end
		end
		Slab.EndListBoxItem()
	end
	Slab.EndListBox()
	Slab.EndWindow()
end

local function kpmode1(k)
	--print(k)
	--if k == "b" then
	--	gbCPU.mem.setByte(0x85,0xFF40)
	--end
	--[[
	if k == "a" then
		if startwatch ==0 then
			startwatch = love.timer.getTime()
		else
			print("time",love.timer.getTime()-startwatch)
			startwatch = 0
		end
	end]]
	if k == "q" then
		mode = 0
		setupMode0()
	end
	--if k == "e" then
	--	 gbCPU.mem.setByte(0xc3,0xff40)
	--end

	if k == "space" then
		--breaking = not breaking
	end
	if k == "`" then
		--bigboy = not bigboy
		--checking = not checking
		running = not running
		--print(checking)
		--print("running: "..tostring(bigboy))
		--print("1000000")
		--for i = 1,100000 do
		--	gbCPU.executeInstruction()
		--	numExecuted = numExecuted + 1
		--[[
			zc = record[numExecuted][1]
			--print(gbCPU.A,zc.a)
			if gbCPU.A ~= zc.a then error("A not equal at "..i) end
			if gbCPU.B ~= zc.b then error("B not equal at "..i) end
			if gbCPU.C ~= zc.c then error("C not equal at "..i) end
			if gbCPU.D ~= zc.d then error("D not equal at "..i) end
			if gbCPU.E ~= zc.e then error("E not equal at "..i) end
			if gbCPU.H ~= zc.h then error("H not equal at "..i) end
			if gbCPU.L ~= zc.l then error("L not equal at "..i) end
			--if gbCPU.F ~= zc.f then error("F not equal at "..i) end
			if gbCPU.SP ~= zc.sp then error("SP not equal at "..i) end
			if gbCPU.PC ~= zc.pc then error("PC not equal at "..i) end
			]] --
		--end
	end
	if k == "return" then
		if checking then stepCheck() end
	end
	--[[
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

local function kpmode0(k)
	if k == "return" then
		Entered = true
	elseif k == "up" then
		Selected = math.max(Selected - 1, 1)
	elseif k == "down" then
		Selected = math.min(Selected + 1, #love.filesystem.getDirectoryItems(Cwd) + 1)
	end
end

function loveload(args)
	mode = 0
	consolas = love.graphics.newFont("consola.ttf", 12)
	Slab.Initialize(args)
	Slab.PushFont(consolas)
	Slab.DisableDocks { "Left", "Right", "Bottom" }
	--setupMode1()
	setupMode0()
	--0 = start 1 = run
end

function loveupdate(dt)
	Slab.Update(dt)
	if mode == 0 then
		updateMode0(dt)
	elseif mode == 1 then
		updateMode1(dt)
	end
end

function lovedraw()
	Slab.Draw()
end

local curBreakPoint = -1



fnotsame = true
lastPC = 0
function stepCheck()
	numExecuted = numExecuted + 1
	gbCPU.executeInstruction()
	--print(numExecuted)
	line = epicLog:read("*l")
	--parse line
	--A: 01 F: B0 B: 00 C: 13 D: 00 E: D8 H: 01 L: 4D SP: FFFE PC: 00:0100 (00 C3 13 02)
	local a, f, b, c, d, e, h, l, sp, pc = line:match(
		"A: (%x+) F: (%x+) B: (%x+) C: (%x+) D: (%x+) E: (%x+) H: (%x+) L: (%x+) SP: (%x+) PC: 00:(%x+) ")
	a, f, b, c, d, e, h, l, sp, pc = tonumber(a, 16), tonumber(f, 16), tonumber(b, 16), tonumber(c, 16), tonumber(d, 16),
		tonumber(e, 16), tonumber(h, 16), tonumber(l, 16), tonumber(sp, 16), tonumber(pc, 16)
	--if numExecuted > 35290000 then--748000 then --and numExecuted < 621023 then --406751
	--print(numExecuted)
	print(line .. numExecuted)
	print(a, f, b, c, d, e, h, l, sp, pc)
	print(gbCPU.A, gbCPU.F, gbCPU.B, gbCPU.C, gbCPU.D, gbCPU.E, gbCPU.H, gbCPU.L, gbCPU.SP, gbCPU.PC)
	--end
	if gbCPU.PC ~= pc then
		print(gbCPU.PC, string.format("%x", lastPC), numExecuted); error("PC not equal at " .. pc)
	end
	if gbCPU.A ~= a then
		print(gbCPU.A, string.format("%x", lastPC), numExecuted); error("A not equal at " .. pc)
	end
	if gbCPU.B ~= b then
		print(gbCPU.B, string.format("%x", lastPC), numExecuted); error("B not equal at " .. pc)
	end
	if gbCPU.C ~= c then
		print(gbCPU.C, string.format("%x", lastPC), numExecuted); error("C not equal at " .. pc)
	end
	if gbCPU.D ~= d then
		print(gbCPU.D, string.format("%x", lastPC), numExecuted); error("D not equal at " .. pc)
	end
	if gbCPU.E ~= e then
		print(gbCPU.E, string.format("%x", lastPC), numExecuted); error("E not equal at " .. pc)
	end
	if gbCPU.H ~= h then
		print(gbCPU.H, string.format("%x", lastPC), numExecuted); error("H not equal at " .. pc)
	end
	if gbCPU.L ~= l then
		print(gbCPU.L, string.format("%x", lastPC), numExecuted); error("L not equal at " .. pc)
	end
	if gbCPU.F ~= f then
		print(gbCPU.L, string.format("%x", lastPC), numExecuted); error("F not equal at " .. pc); fnotsame = true
	else
		fnotsame = false
	end
	if gbCPU.SP ~= sp then
		print(gbCPU.SP, string.format("%x", lastPC), numExecuted); error("SP not equal at " .. pc)
	end
	lastPC = gbCPU.PC
	--gbCPU.executeInstruction()
end

numExecuted = 0
bigboy = false

startwatch = 0

checking = false
breaking = false
function love.keypressed(k)
	if mode == 0 then
		kpmode0(k)
	elseif mode == 1 then
		kpmode1(k)
	end
end

print(debg)
if debg then
	function love.update(a) err, msg = pcall(loveupdate, a) end

	if not err then
		print("error ", msg); love.timer.sleep(1)
	end
	function love.draw(a) err, msg = pcall(lovedraw, a) end

	if not err then
		print("error ", msg); love.timer.sleep(1)
	end
	function love.load(a) err, msg = pcall(loveload, a) end

	if not err then
		print("error ", msg); love.timer.sleep(1)
	end
else
	function love.update(a) loveupdate(a) end

	function love.draw(a) lovedraw(a) end

	function love.load(a) loveload(a) end
end
