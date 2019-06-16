--local opcode = 0x84
function printOP(opcode,subop)
	sy = subop & 0x38
	sz = subop & 0x07
	sx = subop & 0xC0
	
	sx = sx >> 6
	sy = sy >> 3


	x = opcode & 0xC0
	y = opcode & 0x38
	z = opcode & 0x07
	
	x = x >> 6
	y = y >> 3
	
	p = y >> 1
	q = y % 2
	
	r = {[0] = "B","C","D","E","H","L","(HL)","A"}
	rp = {[0] = "BC","DE","HL","SP"}
	rp2 = {[0] = "BC","DE","HL","AF"}
	cc = {[0] = "NZ","Z","NC","C"}
	alu = {[0] = "ADD A,","ADC A,","SUB","SBC A","AND","XOR","OR","CP"}
	rot = {[0] = "RLC","RRC","RL","RR","SLA","SRA","SWAP","SRL"}
	
	if x == 0 then
		if z == 0 then--relative and assorted ops
			if y == 0 then
				print("NOP")
			elseif y == 1 then
				print("LD(nn),SP")
			elseif y == 2 then
				print("STOP")
			elseif y == 3 then
				print("JR d")
			elseif y >= 4 and y <=7 then
				print("JR "..cc[y-4]..",d")
			end
		elseif z == 1 then--16 bit load immediate/add
			if q == 0 then
				print("LD "..rp[p]..",nn")
			elseif q ==  1 then
				print("ADD HL, "..rp[p])
			end
		elseif z == 2 then--Indirect loading
			if q == 0 then
				if p == 0 then
					print("LD (BC),A")
				elseif p == 1 then
					print("LD (DE),A")
				elseif p == 2 then
					print("LD (HL+),A")
				elseif p == 3 then
					print("LD (HL-),A")
				end
			elseif q == 1 then
				if p == 0 then
					print("LD A,(BC)")
				elseif p == 1 then
					print("LD A,(DE)")
				elseif p == 2 then
					print("LD A,(HL+)")
				elseif p == 3 then
					print("LD A,(HL-)")
				end
			end
		elseif z == 3 then--16-bit INC/DEC
			if q == 0 then
				print("INC "..rp[p])
			elseif q == 1 then
				print("DEC "..rp[p])
			end
		elseif z == 4 then--8-bit INC
			print("INC "..r[y])
		elseif z == 5 then--8-bit DEC
			print("DEC "..r[y])
		elseif z == 6 then--8-bit load immediate
			print("LD "..r[y]..",n")
		elseif z == 7 then--Assorted operations on accumulator/flags
			if y == 0 then
				print("RCLA")
			elseif y == 1 then
				print("RRCA")
			elseif y == 2 then
				print("RLA")
			elseif y == 3 then
				print("RRA")
			elseif y == 4 then
				print("DAA")
			elseif y == 5 then
				print("CPL")
			elseif y == 6 then
				print("SCF")
			elseif y == 7 then
				print("CCF")
			end
		end
	elseif x == 1 then
		if z == 6 and y == 6 then--Exception (replaces LD(HL),(HL))
			print("HALT")
		else--8-bit loading
			print("LD "..r[y]..","..r[z])
		end
	elseif x == 2 then
		print(alu[y].." "..r[z])--Operate on accumulator and rigestir/memory location
	elseif x == 3 then
		if z == 0 then
			if y >= 0 and y <= 3 then
				print("RET "..cc[y])
			elseif y == 4 then
				print("LD (0xFF+nn), A")
			elseif y == 5 then
				print("ADD SP,d")
			elseif y == 6 then
				print("LD A, (0xFF00+n )")
			elseif y == 7 then
				print("LD HL,SP+d")
			end
		elseif z == 1 then
			if q == 0 then
				print("POP "..rp2[p])
			elseif q == 1 then
				if p == 0 then
					print("RET")
				elseif p == 1 then
					print("RETI")
				elseif p == 2 then
					print("JP HL")
				elseif p == 3 then
					print("LD SP,HL")
				end
			end
		elseif z == 2 then
			if y >= 0 and y <= 3 then
				print("JP "..cc[y]..",nn")
			elseif y == 4 then
				print("LD (0xFF+C),A")
			elseif y == 5 then
				print("LD (nn),A")
			elseif y == 6 then
				print("LD A, (0xFF00+C)")
			elseif y == 7 then
				print("LD A,(nn)")
			end
		elseif z == 3 then
			if y == 0 then
				print("JP nn")
			elseif y == 1 then
				print("CB:")
				if sx == 0 then
					print(rot[sy].." "..r[sz])
				elseif sx == 1  then
					print("BIT "..sy..","..r[sz])
				elseif sx == 2  then
					print("RES "..sy..","..r[sz])
				elseif sx == 3  then
					print("SET "..sy..","..r[sz])
				end
			elseif y >= 2 and y <= 5 then
				print("removed")
			elseif y == 6 then
				print("DI")
			elseif y == 7 then
				print("EI")
			end
		elseif z == 4 then
			if y >= 0 and y <= 3 then
				print("CALL "..cc[y]..",nn")
			elseif y >= 4 and y <= 7 then
				print("removed")
			end
		elseif z == 5 then
			if q == 0 then
				print("PUSH "..rp2[p])
			elseif q == 1 then
				if p == 1 then
					print("CALL nn")
				elseif p >=1 and p <= 3 then
					print("removed")
				end
			end
		elseif z == 6 then
			print(alu[y].."n")
		elseif z == 7 then
			print("RST"..y*8)
		end
	end
end


f = io.open("bios.gb","rb")
b = string.byte(f:read(1))
c = 0
while b do
	print(b)
	print(string.format("0x%x",b))
	if b == 0xcb then 
		c = string.byte(f:read(1))
	end
	printOP(b,c)
	io.read()
	b = string.byte(f:read(1))
end
f:close()