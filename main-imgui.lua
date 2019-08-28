require("imgui")


function love.load()
	
	--gbCPU.executeInstruction()
	--gbCPU.executeInstruction()
	--love.keyboard.setKeyRepeat(true)
	showTestWindow = false
	showAnotherWindow = false
	floatValue = 0;
	sliderFloat = { 0.1, 0.5 }
	clearColor = { 0.2, 0.2, 0.2 }
	comboSelection = 1
	textValue = "text"


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

	gbCPU = cpu()
end

function love.update()
	imgui.NewFrame()
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
	
	
	
	
	-- Menu
    if imgui.BeginMainMenuBar() then
        if imgui.BeginMenu("File") then
            imgui.MenuItem("Test")
            imgui.EndMenu()
        end
        imgui.EndMainMenuBar()
    end

    -- Debug window
    --imgui.Text("Hello, world!");
	local test = ""
    imgui.Text(string.format("A 0x%x(%d)",gbCPU.A,gbCPU.A))
	imgui.SameLine()
	imgui.InputText("",test,3)
	imgui.SameLine()
	imgui.Text(test.."t")
	imgui.Text(string.format("B 0x%x(%d)",gbCPU.B,gbCPU.B))
	imgui.Text(string.format("C 0x%x(%d)",gbCPU.C,gbCPU.C))
	imgui.Text(string.format("D 0x%x(%d)",gbCPU.D,gbCPU.D))
	imgui.Text(string.format("E 0x%x(%d)",gbCPU.E,gbCPU.E))
	imgui.Text(string.format("H 0x%x(%d)",gbCPU.H,gbCPU.H))
	imgui.Text(string.format("L 0x%x(%d)",gbCPU.L,gbCPU.L))
	imgui.Text("F "..gbCPU.F)
	imgui.Text("Z ".. (bit.band(gbCPU.F,0x80)>0 and 1 or 0) .." N ".. (bit.band(gbCPU.F,0x40)>0 and 1 or 0) .." H ".. (bit.band(gbCPU.F,0x20)>0 and 1 or 0) .." C ".. (bit.band(gbCPU.F,0x10)>0 and 1 or 0))
	imgui.Text(string.format("SP 0x%x(%d)",gbCPU.SP,gbCPU.SP))
	imgui.Text("PC "..gbCPU.PC..string.format(" 0x%x",gbCPU.PC))
	imgui.Text("cycles "..gbCPU.cycles)
    
    -- Sliders
    floatValue = imgui.SliderFloat("SliderFloat", floatValue, 0.0, 1.0);
    sliderFloat[1], sliderFloat[2] = imgui.SliderFloat2("SliderFloat2", sliderFloat[1], sliderFloat[2], 0.0, 1.0);
    
    -- Combo
    comboSelection = imgui.Combo("Combo", comboSelection, { "combo1", "combo2", "combo3", "combo4" }, 4);

    -- Windows
    if imgui.Button("Test Window") then
        showTestWindow = not showTestWindow;
    end
    
    if imgui.Button("Another Window") then
        showAnotherWindow = not showAnotherWindow;
    end
    
    if showAnotherWindow then
        imgui.SetNextWindowPos(50, 50, "ImGuiCond_FirstUseEver")
        showAnotherWindow = imgui.Begin("Memory", true, {});
		imgui.PushStyleVar("ImGuiStyleVar_FramePadding",0,0)
		imgui.PushStyleVar("ImGuiStyleVar_ItemSpacing",0,0)
        imgui.Text("Hello");
        -- Input text
        textValue = imgui.InputTextMultiline("InputText", textValue, 200, 300, 200);
        imgui.End();
    end

    if showTestWindow then
        showTestWindow = imgui.ShowDemoWindow(true)
    end

    love.graphics.clear(clearColor[1], clearColor[2], clearColor[3])
    imgui.Render();
	
end

local curBreakPoint = -1

function love.quit()
	imgui.ShutDown()
end

--inputs--

function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keypressed(k)
	imgui.KeyPressed(k)
	if not imgui.GetWantCaptureKeyboard() then
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
		end
	end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end
