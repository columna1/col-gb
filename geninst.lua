local function gen(file)
	local state = ""
	if not file then error("to file to gen inst from") end
	local f = io.open(file,"r")
	if not f then error("could not open inst file") end
	
	local output = ""
	local output2 = ""
	local funcs = {}
	local regs = {}
	local ops = {}
	local ops2 = {}
	
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
	
	for line in f:lines() do
		--check for state change
		--print(line)
		if line:sub(#line) == "." then
			--state change
			state = line:sub(1,#line-1)
			--print("found state "..state)
			goto CONTINUE
		end
		if state == "init" then
			output = output..line.."\n"
		elseif state == "init" then
			output2 = output2..line.."\n"
		elseif state == "func" then
			local funcLine = {}
			--format is:
			--alias cycles,PC++: function(%)
			if #line <2 then goto CONTINUE end
			--parse
			local sep = {" ",","}
			local ind = 1
			local token = ""
			local lineState = 0
			local vState = 0
			local lout = ""
			local vCount = 0
			local pstate = true
			local numbers = {}
			for i = 1,#line do
				local symb = line:sub(i,i)
				if lineState == 0 then
					local issep = false
					for s = 1,#sep do
						if sep[s] == symb then
							issep = true 
						end
					end
					if symb == ":" then
						lineState = 1
						issep = true
					end
					if issep then
						--print(token)
						table.insert(funcLine,token)
						token = ""
					else
						token = token..symb
					end
				elseif lineState == 1 then
					--the rest of the line is to be taken litterally except for variable holders eg %1
					if pstate then
						if tonumber(symb) then
							if lout:sub(#lout-1) == "%s" then lout = lout:sub(1,#lout-1) end
							if numbers[tonumber(symb)] then
								vCount = vCount - 1
							end
							numbers[tonumber(symb)] = true
						end
						pstate = false
					end
					if symb == "%" then
						vCount = vCount + 1
						symb = "%s"
						pstate = true
					end
					lout = lout..symb
				end
			end
			--print(lout,vCount)
			table.insert(funcLine,lout)
			table.insert(funcLine,vCount)
			table.insert(funcs,funcLine)
		elseif state == "reg" then
			if #line < 2 then goto CONTINUE end
			local lineState = 0
			local token = ""
			local secondToken = ""
			for i = 1,#line do
				local symb = line:sub(i,i)
				if lineState == 0 then
					local issep = false
					if symb == ":" then
						issep = true 
						lineState = 1
					end
					if not issep then
						token = token..symb
					end
				elseif lineState == 1 then
					secondToken = secondToken..symb
				end
			end
			table.insert(regs,{token,secondToken})
		elseif state == "op" then
			local linetab = {}
			if #line < 2 then goto CONTINUE end
			if line:sub(1,1) == "#" then goto CONTINUE end
			local ss,ee = line:find("|")
			if not ss then
				error("incorect format")
			end
			local s,e = line:find(":")
			if not s then
				error("incorect format")
			end
			local num = 0
			if s then
				linetab.cycles = tonumber(line:sub(1,ss-1))
				num = tonumber(line:sub(ee+1,s-1))
				local tok = ""
				local l = ""
				for i = s+1,#line do
					--if it isn't alpha char then add it litterally, otherwise seperate get it's token and replace that part with the correct info
					local symb = line:sub(i,i)
					if symb:find("%a") then
						if #l > 0 then table.insert(linetab,l) end
						l = ""
						tok = tok..symb
					elseif #tok > 0 then
						--insert into table
						table.insert(linetab,{tok})
						l = l..symb
						tok = ""
					elseif symb == " " then
						if #l > 1 then
							table.insert(linetab,l)
							l = ""
						end
						table.insert(linetab," ")
					else--number or symbol
						l = l..symb
					end
				end
				if #l > 0 then table.insert(linetab,l) end
				if #tok > 0 then table.insert(linetab,{tok}) end
			end
			if ops[num] then
				print("opcode "..num.." (0x"..string.format("%x",num)..") seems to be implemented more than once")
			end
			ops[num] = linetab
		elseif state == "op cb" then
			local linetab = {}
			if #line < 2 then goto CONTINUE end
			if line:sub(1,1) == "#" then goto CONTINUE end
			local ss,ee = line:find("|")
			if not ss then
				error("incorect format")
			end
			local s,e = line:find(":")
			if not s then
				error("incorect format")
			end
			local num = 0
			if s then
				linetab.cycles = tonumber(line:sub(1,ss-1))
				num = tonumber(line:sub(ee+1,s-1))
				local tok = ""
				local l = ""
				for i = s+1,#line do
					--if it isn't alpha char then add it litterally, otherwise seperate get it's token and replace that part with the correct info
					local symb = line:sub(i,i)
					if symb:find("%a") then
						if #l > 0 then table.insert(linetab,l) end
						l = ""
						tok = tok..symb
					elseif #tok > 0 then
						--insert into table
						table.insert(linetab,{tok})
						l = l..symb
						tok = ""
					elseif symb == " " then
						if #l > 1 then
							table.insert(linetab,l)
							l = ""
						end
						table.insert(linetab," ")
					else--number or symbol
						l = l..symb
					end
				end
				if #l > 0 then table.insert(linetab,l) end
				if #tok > 0 then table.insert(linetab,{tok}) end
			end
			if ops2[num] then
				print("opcode "..num.." (0x"..string.format("%x",num)..") seems to be implemented more than once")
				print("added",num)
			end
			ops2[num] = linetab
		end
		::CONTINUE::
	end
	
	--printTable(funcs)
	--print("aa")
	--printTable(regs)
	--print("tt")
	--printTable(ops)
	print("   0123456789ABCDEF")
	for a = 0,15 do
		s = string.format("%x",a).."x "
		for b = 0,15 do
			--print((a*16)+b)
			if ops[(a*16)+b] or (a*16)+b == 0 then
				s = s.."|"
			else
				s = s.."x"
			end
		end
		print(s)
	end
	
	output = output.."instructions =  {\nfunction() cycles = cycles + 4 end,--no-op [0]\n"
	
	for i = 1,255 do
		if ops[i] then
			local out = ""
			local clocks = ops[i].cycles
			local PC = 0
			while #ops[i] > 0 do
				local cop = table.remove(ops[i],1)
				local found = false
				
				local function sub(token)
					--print("------------SUB------------")
					--print("TOKEN ",token)
					--print("token",token)
					for f = 1,#funcs do
						if funcs[f][1] == token then
							--print("FOUND",token)
							if token == "setFHs" then
								--print()
							end
							local len = 0
							local str = ""
							if #funcs[f] == 4 then
								--clocks = clocks+funcs[f][2]
								if #funcs[f][2] > 0 then
									PC = PC+funcs[f][2]
								end
								len = funcs[f][4]
								str = funcs[f][3]
							end
							if len == 0 then
								--print("zero",str)
							else
								for a = 1,len do
									local s,e = str:find("%%s")
									if s then
										local token = table.remove(ops[i],1)
										--print("t",token)
										if token == " " then token = table.remove(ops[i],1) end
										--print(token,token[1],str,s,e)
										if type(token) == "table" then
											str = str:sub(1,s-1)..sub(token[1])..str:sub(e+1)
										else
											str = str:sub(1,s-1)..token..str:sub(e+1)
										end
									end
								end
								local tr = {}
								local function contains(tab,val) for ii = 1,#tab do if tab[ii] == val then return true end end return false end
								for a = 1,len do
									local s,e = str:find("%%%d")
									if s then
										local num = tonumber(str:sub(s+1,e))
										if not contains(tr,num) then table.insert(tr,num) end
										local token = ops[i][num]
										--print("t",token)
										if token == " " then table.remove(ops[i],num) ; token = ops[i][num] end
										--print(token,token[1],str,s,e)
										if type(token) == "table" then
											--str = str:sub(1,s-1)..sub(token[1])..str:sub(e+1)
											str = str:gsub("%%"..num,sub(token[1]))
										else
											str = str:gsub("%%"..num,token)
										end
									end
								end
								
								for ii = 1,#tr do
									table.remove(ops[i],1)
								end
							end
							
							found=true
							return str
						end
					end
					for f = 1,#regs do
						if regs[f][1] == token then
							--print("FOUND",token)
							found=true
							return regs[f][2]
						end
					end
					error("could not find token \""..token.."\"")
				end
				
				if type(cop) == "table" then
					--print("cop")
					--printTable(cop)
					--print("cop",cop[1])
					out = out..sub(cop[1])
				else
					out = out..cop
					found = true
				end
			end
			if clocks > 0 then out = out.."; cycles = cycles + "..clocks end
			if PC > 0 then out = out.."; self.PC = self.PC+ "..PC end
			--print(out)
			output = output.."function() "..out.." end,--["..i .." 0x"..string.format("%x",i).."]\n"
		else
			output = output.."function() error(\"unimplemented instruction "..i.."(0x"..string.format("%x",i)..")".."\") end,--["..i .." 0x"..string.format("%x",i).."]\n"
		end
	end
	output = output.."}"
	
	output2 = output2.."instructionsCB =  {\nfunction() cycles = cycles + 4 end,--no-op [0]\n"
	
	for i = 1,255 do
		if ops2[i] then
			local out = ""
			local clocks = ops2[i].cycles
			local PC = 0
			while #ops2[i] > 0 do
				local cop = table.remove(ops2[i],1)
				--print(cop[1])
				local found = false
				
				local function sub(token)
					--print("------------SUB------------")
					--print("TOKEN ",token)
					for f = 1,#funcs do
						if funcs[f][1] == token then
							--print("FOUND",token)
							
							local len = 0
							local str = ""
							if #funcs[f] == 4 then
								--clocks = clocks+funcs[f][2]
								if #funcs[f][2] > 0 then
									PC = PC+funcs[f][2]
								end
								len = funcs[f][4]
								str = funcs[f][3]
							end
							if len == 0 then
								--print("zero",str)
							else
								for a = 1,len do
									local s,e = str:find("%%s")
									if s then
										local token = table.remove(ops2[i],1)
										--print("t",token)
										if token == " " then token = table.remove(ops2[i],1) end
										--print(token,token[1],str,s,e)
										if type(token) == "table" then
											str = str:sub(1,s-1)..sub(token[1])..str:sub(e+1)
										else
											str = str:sub(1,s-1)..token..str:sub(e+1)
										end
									end
								end
								local tr = {}
								local function contains(tab,val) for ii = 1,#tab do if tab[ii] == val then return true end end return false end
								for a = 1,len do
									local s,e = str:find("%%%d")
									if s then
										local num = tonumber(str:sub(s+1,e))
										if not contains(tr,num) then table.insert(tr,num) end
										local token = ops2[i][num]
										--print("t",token)
										if token == " " then table.remove(ops2[i],num) ; token = ops2[i][num] end
										--print(token,token[1],str,s,e)
										str = str:sub(1,s-1)..sub(token[1])..str:sub(e+1)
									end
								end
								
								for ii = 1,#tr do
									table.remove(ops2[i],1)
								end
							end
							
							found=true
							return str
						end
					end
					for f = 1,#regs do
						if regs[f][1] == token then
							--print("FOUND",token)
							found=true
							return regs[f][2]
						end
					end
					error("could not find token \""..token.."\"")
				end
				
				if type(cop) == "table" then
					--print("cop")
					--printTable(cop)
					--print("cop",cop[1])
					out = out..sub(cop[1])
				else
					out = out..cop
					found = true
				end
			end
			if clocks > 0 then out = out.."; cycles = cycles + "..clocks end
			if PC > 0 then out = out.."; self.PC = self.PC+ "..PC end
			--print(out)
			output2 = output2.."function() "..out.." end,--["..i .." 0x"..string.format("%x",i).."]\n"
		else
			output2 = output2.."function() error(\"unimplemented 0xCB instruction "..i.."(0x"..string.format("%x",i)..")".."\") end,--["..i .." 0x"..string.format("%x",i).."]\n"
		end
	end
	output2 = output2.."}"
	
	--error()
	return output,output2
end

return gen