package;

import openfl.utils.Function;

class CPU extends Node{
	/** public variant
	---------------------------*/
		public var vtMem:Array<Int>;				// Memory,somrwhere are mapping	- 内存,某些地址为映射地址
		
	/** private variant
	---------------------------*/
		private var A:UInt = 0;							// Accumulator					- 累加器
		private var X:UInt = 0;							// Index Register X				- X寻址寄存器
		private var Y:UInt = 0;							// Index Register Y				- Y寻址寄存器
		private var S:UInt = 0;							// Stack Pointer				- 栈指针
		private var PC:UInt = 0;						// Program Counter				- 指令指针
		private var P:UInt = 0;							// Processor Status Register	- 状态寄存器
		/** ------------------------------------------------------------------------------------------ */
		/* bit7 */private var NF:Bool;			// Negative Flag				- 负数标志
		/* bit6 */private var VF:Bool;			// Overflow Flag				- 溢出标志
		/* bit5 */private var RF:Bool;			// Preserve,alway is 1			-  预留,总是1
		/* bit4 */private var BF:Bool;			// Software Break Flag			- 软中断标志
		/* bit3 */private var DF:Bool;			// Decimal Flag					- 十进制标志
		/* bit2 */private var IF:Bool;			// Hardwrae Interrupt Flag		- 硬中断标志
		/* bit1 */private var ZF:Bool;			// Zero Flag					- 零标志
		/* bit0 */private var CF:Bool;			// Carry Flag					- 进位标志
		/** ------------------------------------------------------------------------------------------ */
		public var executedCC:Int = 0;					// clock cycles of executed		- 已经执行过的时钟频率
		
		private var CC:Array<Int>;				// instruction clock cycle lsit	- 指令时钟频率列表
		private var oc:UInt = 0;						// opcode						- 操作码
		private var ocCC:Int = 0;						// opcode clock cycle			- 操作码的时钟频率
		
		private var l_or:UInt = 0;						// lower oprand					- 低位操作数
		private var u_or:UInt = 0;						// upper oprand					- 高位操作数
		private var l_addr:UInt = 0;					// lower address				- 低址
		private var u_addr:UInt = 0;					// upper address				- 高址
		private var addr:UInt= 0;						// address						- 地址

		private var src:UInt = 0;						// source value					- 源址值
		private var dst:UInt = 0;						// destination value			- 目标值
		private var tmpN:UInt = 0;						// temp int value				- 临时整型值
		private var tmpB:Bool;					// temp boolean value			- 临时布尔型值

		private var lastPC:Int = 0;						// last program counter			- 当前指令指针
	
	/** construction
	---------------------------*/
		public function new(){
			// initialize register
			A = X = Y = P = PC = 0;
			S = 0xFF;
			NF = VF = BF = DF = IF = ZF = CF = false;
			RF = true;
			// initalize variable
			vtMem = [for(c in 0...0x10000) 0];//new Array<Int>();		// 64KB
			CC = new Array<Int>();
			CC = [
			7, 6, 0, 0, 0, 3, 5, 0, 3, 2, 2, 0, 0, 4, 6, 0,
			2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0,
			6, 2, 0, 0, 3, 3, 5, 0, 4, 2, 2, 0, 4, 4, 6, 0,
			2, 2, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0,
			6, 6, 0, 0, 0, 3, 5, 0, 3, 2, 2, 0, 3, 4, 6, 0,
			2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0,
			6, 6, 0, 0, 0, 3, 5, 0, 4, 2, 2, 0, 5, 4, 6, 0,
			2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0,
			0, 6, 0, 0, 3, 3, 3, 0, 2, 0, 2, 0, 4, 4, 4, 0,
			2, 6, 0, 0, 4, 4, 4, 0, 2, 5, 2, 0, 0, 5, 0, 0,
			2, 6, 2, 0, 3, 3, 3, 0, 2, 2, 2, 0, 4, 4, 4, 0,
			2, 5, 0, 0, 4, 4, 4, 0, 2, 4, 2, 0, 4, 4, 4, 0,
			2, 6, 0, 0, 3, 3, 5, 0, 2, 2, 2, 0, 4, 4, 6, 0,
			2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0,
			2, 6, 0, 0, 3, 3, 5, 0, 2, 2, 2, 0, 4, 4, 6, 0,
			2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0];
			oc = l_or = u_or = l_addr = u_addr = addr = executedCC = src = dst = tmpN = lastPC = ocCC = 0;
			tmpB = false;
		}
		
	/** public function
	---------------------------*/
		public function reset():Void{
			PC = vtMem[0xFFFD] << 8 | vtMem[0xFFFC];
		}
		// Non-Maskable Interrupt
		public function NMI():Void{
			vtMem[Utils.int(0x0100 + S)] = PC >> 8;
			S -= 1;S &= 0xFF; // [fixed]
			vtMem[Utils.int(0x0100 + S)] = PC & 0xFF;
			S -= 1;S &= 0xFF; // [fixed]
			BF = false;
			P = Utils.int(NF) << 7 | Utils.int(VF) << 6 | Utils.int(RF) << 5 | Utils.int(BF) << 4 | Utils.int(DF) << 3 | Utils.int(IF) << 2 | Utils.int(ZF) << 1 | Utils.int(CF);
			vtMem[Utils.int(0x0100 + S)] = P;
			S -= 1;S &= 0xFF; // [fixed]
			IF = true;
			PC = vtMem[0xFFFB] << 8 | vtMem[0xFFFA];
		}
		// Interrupt Request
		public function IRQ():Void{
			vtMem[Utils.int(0x0100 + S)] = PC >> 8;
			S -= 1;S &= 0xFF; // [fixed]
			vtMem[Utils.int(0x0100 + S)] = PC & 0xFF;
			S -= 1;S &= 0xFF; // [fixed]
			BF = false;
			P = Utils.int(NF) << 7 | Utils.int(VF) << 6 | Utils.int(RF) << 5 | Utils.int(BF) << 4 | Utils.int(DF) << 3 | Utils.int(IF) << 2 | Utils.int(ZF) << 1 | Utils.int(CF);
			vtMem[Utils.int(0x0100 + S)] = P;
			S -= 1;S &= 0xFF; // [fixed]
			IF = true;
			PC = vtMem[0xFFFF] << 8 | vtMem[0xFFFE];
		}
		
	/** private function
	---------------------------*/
		// read memory(读取内存)
		private function r1(address:Int):Int{
			if(address >= 0x2000 && address < 0x2008){	// Mirrors $2000 - $2007
               // trace("====1");
				return bus.ppu.r2(address);
			}
			else if(address < 0x0800){	
               // trace("====2");				// RAM
				return vtMem[address];
			}
			else if(address == 0x4016){	
               // trace("====3");				// Joypad 1
				return bus.joypad.r3(0);
			}
			else if(address == 0x4017){	
                //trace("====4");				// Joypad 2
				return bus.joypad.r3(1);
			}
			else if(address >= 0x8000){	
               // trace("====5");				// P-ROM
				return vtMem[address];
			}
			else if(address >= 0x4020){	
                //trace("====6");				// S-RAM / E-ROM
				//trace('[S-ROM/E-ROM]-W-',address.toString(16));
                
				return vtMem[address];
			}
			else if(address >= 0x4000){		
               // trace("====6");			// APU
				//trace('[APU]-R-address',address.toString(16));
				return vtMem[address];
			}
			else if(address >= 0x2008){	
                //trace("====7");				// Mirrors $2000 - $2007
				trace('-R- Mirrors 0x2008');
			}
			else if(address >= 0x0800){		
               // trace("====8");			// Mirrors $0000 - $07FF
				trace('-R- Mirrors 0x0800');
			}
			else{
               // trace("====9");
				//trace('unknow read address',address.toString(16));
			}
			return 0;
		}
		// write memory(写入内存)
		private function w1(address:Int,value:Int):Void{
			if(address >= 0x2000 && address < 0x2008){	// PPU
				bus.ppu.w2(address,value);
			}
			else if(address < 0x0800){					// RAM
				vtMem[address] = value;
			}
			else if(address == 0x4016){					// Joypads Reset
				bus.joypad.w3(value);
			}
			else if(address == 0x4014){					// DMA
				var base:Int = 0x0100 * value;
				for(i in 0...256){
					bus.ppu.vtSpRAM[i] = vtMem[Utils.int(base + i)];
				}
				executedCC += 512;
			}
			else if(address >= 0x8000){					// P-ROM
				var mapper_write:Function = bus.vtMapper_W[bus.nMapper];
				mapper_write(address,value);
			}
			else if(address >= 0x4020){					// S-ROM / E-ROM
				vtMem[address] = value;
			}
			else if(address >= 0x4000){					// APU
				vtMem[address] = value;
			}
			else if(address >= 0x2008){					// Mirrors $2000 - $2007
				trace('w1 Mirrors 0x2008');
			}
			else if(address >= 0x0800){					// Mirrors $0000 - $07FF
				trace('w1 Mirrors 0x0800');
			}
			else{
				//trace('unknow write address',address.toString(16));
			}
		}
		// execution instruction(执行指令)
		public function exec(requiredCC:Int):Bool{
			while(true){
				oc = vtMem[PC];
				lastPC = PC;
				PC += 1;
				
				if(oc >= 0xC0){
					// 240-255
					if(oc >= 0xF0){
						if(oc >= 0xFC){
							/**/ if(oc == 0xFF){
							}
							/**
							 * INC 16bit,X
							 */
							else if(oc == 0xFE){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[inc]
								src = r1(addr) + 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;// src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * SBC 16bit,X
							 */
							else if(oc == 0xFD){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[sbc]
								src = r1(addr);
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							else{		/*0xFC*/
							}
						}
						else if(oc >= 0xF8){
							/**/ if(oc == 0xFB){
							}
							else if(oc == 0xFA){
							}
							/**
							 * SBC 16bit,Y
							 */
							else if(oc == 0xF9){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[sbc]
								src = r1(addr);
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * SED
							 */
							else{		/*0xF8*/
								// 2.执行指令[sec]
								DF = true;
							}
						}
						else if(oc >= 0xF4){
							/**/ if(oc == 0xF7){
							}
							/**
							 * INC 8bit,X
							 */
							else if(oc == 0xF6){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[inc]
								src = vtMem[addr] + 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * SBC 8bit,X
							 */
							else if(oc == 0xF5){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[sbc]
								src = vtMem[addr];
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
							}
							else{		/*0xF4*/
							}
						}
						else{
							/**/ if(oc == 0xF3){
							}
							else if(oc == 0xF2){
							}
							/**
							 * SBC (8bit),Y
							 */
							else if(oc == 0xF1){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[sbc]
								src = r1(addr);
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * BEQ #8bit
							 */
							else{		/*0xF0*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[beq]
								if(ZF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 224-239
					else if(oc >= 0xE0){
						if(oc >= 0xEC){
							/**/ if(oc == 0xEF){
							}
							/**
							 * INC 16bit
							 */
							else if(oc == 0xEE){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[inc]
								src = r1(addr) + 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0; //src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * SBC 16bit
							 */
							else if(oc == 0xED){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[sbc]
								src = r1(addr);
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
							}
							/**
							 * CPX 16bit
							 */
							else{		/*0xEC*/
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[cpx]
								dst = X - r1(addr);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//dst == 0;//!dst;
							}
						}
						else if(oc >= 0xE8){
							/**/ if(oc == 0xEB){
							}
							/**
							 * NOP
							 */
							else if(oc == 0xEA){
							}
							/**
							 * SBC #8bit
							 */
							else if(oc == 0xE9){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[sbc]
								src = l_or;
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
							}
							/**
							 * INX
							 */
							else{		/*0xE8*/
								// 2.执行指令[inx]
								X += 1;
								X &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0 ;//X == 0;//!X;
							}
						}
						else if(oc >= 0xE4){
							/**/ if(oc == 0xE7){
							}
							/**
							 * INC 8bit
							 */
							else if(oc == 0xE6){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[inc]
								src = vtMem[addr] + 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * SBC 8bit
							 */
							else if(oc == 0xE5){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[sbc]
								src = vtMem[addr];
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
							}
							/**
							 * CPX 8bit
							 */
							else{		/*0xE4*/
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[cpx]
								dst = X - vtMem[addr];
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//dst == 0;//!dst;
							}
						}
						else{
							/**/ if(oc == 0xE3){
							}
							else if(oc == 0xE2){
							}
							/**
							 * SBC (8bit,X)
							 */
							else if(oc == 0xE1){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[sbc]
								src = r1(addr);
								dst = Utils.int(A - src) - Utils.int(!CF);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & (A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//A == 0;//!A;
							}
							/**
							 * CPX #8bit
							 */
							else{		/*0xE0*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[cpx]
								dst = X - l_or;
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//dst == 0;//!dst;
							}
						}
					}
					// 208-223
					else if(oc >= 0xD0){
						if(oc >= 0xDC){
							/**/ if(oc == 0xDF){
							}
							/**
							 * DEC 16bit,X
							 */
							else if(oc == 0xDE){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[dec]
								src = r1(addr) - 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * CMP 16bit,X
							 */
							else if(oc == 0xDD){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[cmp]
								dst = A - r1(addr);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//dst == 0;//!dst;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							else{		/*0xDC*/
							}
						}
						else if(oc >= 0xD8){
							/**/ if(oc == 0xDB){
							}
							else if(oc == 0xDA){
							}
							/**
							 * CMP 16bit,Y
							 */
							else if(oc == 0xD9){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[cmp]
								dst = A - r1(addr);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//dst == 0;//!dst;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * CLD
							 */
							else{		/*0xD8*/
								// 2.执行指令
								DF = false;
							}
						}
						else if(oc >= 0xD4){
							/**/ if(oc == 0xD7){
							}
							/**
							 * DEC 8bit,X
							 */
							else if(oc == 0xD6){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[dec]
								src = vtMem[addr] - 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * CMP 8bit,X
							 */
							else if(oc == 0xD5){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[cmp]
								dst = A - vtMem[addr];
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//dst == 0;//!dst;
							}
							else{		/*0xD4*/
							}
						}
						else{
							/**/ if(oc == 0xD3){
							}
							else if(oc == 0xD2){
							}
							/**
							 * CMP (8bit),Y
							 */
							else if(oc == 0xD1){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[cmp]
								dst = A - r1(addr);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//dst == 0;//!dst;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * BNE #8bit
							 */
							else{		/*0xD0*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[bne]
								if(!ZF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 192-207
					else{
						if(oc >= 0xCC){
							/**/ if(oc == 0xCF){
							}
							/**
							 * DEC 16bit
							 */
							else if(oc == 0xCE){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[dec]
								src = r1(addr) - 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * CMP 16bit
							 */
							else if(oc == 0xCD){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[cmp]
								dst = A - r1(addr);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//!dst;
							}
							/**
							 * CPY 16bit
							 */
							else{		/*0xCC*/
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[cmy]
								dst = Y - r1(addr);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//!dst;
							}
						}
						else if(oc >= 0xC8){
							/**/ if(oc == 0xCB){
							}
							/**
							 * DEX
							 */
							else if(oc == 0xCA){
								// 2.执行指令[dex]
								X -= 1;
								X &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
							}
							/**
							 * CMP #8bit
							 */
							else if(oc == 0xC9){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[cmp]
								dst = A - l_or;
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//!dst;
							}
							/**
							 * INY
							 */
							else{		/*0xC8*/
								// 2.执行指令[iny]
								Y += 1;
								Y &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
							}
						}
						else if(oc >= 0xC4){
							/**/ if(oc == 0xC7){
							}
							/**
							 * DEC 8bit
							 */
							else if(oc == 0xC6){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[dec]
								src = vtMem[addr] - 1 & 0xFF;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * CMP 8bit
							 */
							else if(oc == 0xC5){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[cmp]
								dst = A - vtMem[addr];
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//!dst;
							}
							/**
							 * CPY 8bit
							 */
							else{		/*0xC4*/
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[cpy]
								dst = Y - vtMem[addr];
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//!dst;
							}
						}
						else{
							/**/ if(oc == 0xC3){
							}
							else if(oc == 0xC2){
							}
							/**
							 * CMP (8bit,X)
							 */
							else if(oc == 0xC1){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[cmp]
								dst = A - r1(addr);
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//!dst;
							}
							/**
							 * CPY #8bit
							 */
							else{		/*0xC0*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[cpy]
								dst = Y - l_or;
								// 3.标志位设置
								CF = dst < 0x100;
								dst &= 0xFF; // [fixed]
								NF = Utils.i2b(dst & 0x80);
								ZF = dst == 0;//!dst;
							}
						}
					}
				}
				else if(oc >= 0x80){
					// 176-191
					if(oc >= 0xB0){
						if(oc >= 0xBC){
							/**/ if(oc == 0xBF){
							}
							/**
							 * LDX 16bit,Y
							 */
							else if(oc == 0xBE){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[ldx]
								X = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * LDA 16bit,X
							 */
							else if(oc == 0xBD){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[lda]
								A = r1(addr);
                                //trace(A,"nnnnnnnn");
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * LDY 16bit,X
							 */
							else{		/*0xBC*/
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[ldy]
								Y = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
						}
						else if(oc >= 0xB8){
							/**/ if(oc == 0xBB){
							}
							/**
							 * TSX
							 */
							else if(oc == 0xBA){
								// 2.执行指令[tsx]
								X = S;
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
							}
							/**
							 * LDA 16bit,Y
							 */
							else if(oc == 0xB9){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[lda]
								A = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * CLV
							 */
							else{		/*0xB8*/
								// 2.执行指令
								VF = false;
							}
						}
						else if(oc >= 0xB4){
							/**/ if(oc == 0xB7){
							}
							/**
							 * LDX 8bit,Y
							 */
							else if(oc == 0xB6){
								// 1.零页Y变址寻址
								addr = vtMem[PC] + Y & 0xFF; PC += 1;
								// 2.执行指令[ldx]
								X = vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
							}
							/**
							 * LDA 8bit,X
							 */
							else if(oc == 0xB5){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[lda]
								A = vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * LDY 8bit,X
							 */
							else{		/*0xB4*/
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[lda]
								Y = vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
							}
						}
						else{
							/**/ if(oc == 0xB3){
							}
							else if(oc == 0xB2){
							}
							/**
							 * LDA (8bit),Y
							 */
							else if(oc == 0xB1){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[lda]
								A = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * BCS #8bit
							 */
							else{		/*0xB0*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[bcs]
								if(CF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 160-175
					else if(oc >= 0xA0){
						if(oc >= 0xAC){
							/**/ if(oc == 0xAF){
							}
							/**
							 * LDX 16bit
							 */
							else if(oc == 0xAE){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[ldx]
								X = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
							}
							/**
							 * LDA 16bit
							 */
							else if(oc == 0xAD){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[lda]
								A = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * LDY 16bit
							 */
							else{		/*0xAC*/
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[ldy]
								Y = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
							}
						}
						else if(oc >= 0xA8){
							/**/ if(oc == 0xAB){
							}
							/**
							 * TAX
							 */
							else if(oc == 0xAA){
								// 2.执行指令[tax]
								X = A;
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
							}
							/**
							 * LDA #8bit
							 */
							else if(oc == 0xA9){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[lda]
								A = l_or;
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * TAY
							 */
							else{		/*0xA8*/
								// 2.执行指令[tay]
								Y = A;
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
							}
						}
						else if(oc >= 0xA4){
							/**/ if(oc == 0xA7){
							}
							/**
							 * LDX 8bit
							 */
							else if(oc == 0xA6){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[ldx]
								X = vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
							}
							/**
							 * LDA 8bit
							 */
							else if(oc == 0xA5){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[lda]
								A = vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * LDY 8bit
							 */
							else{		/*0xA4*/
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[ldy]
								Y = vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
							}
						}
						else{
							/**/ if(oc == 0xA3){
							}
							/**
							 * LDX #8bit
							 */
							else if(oc == 0xA2){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[ldx]
								X = l_or;
								// 3.标志位设置
								NF = Utils.i2b(X & 0x80);
								ZF = X == 0;//!X;
							}
							/**
							 * LDA (8bit,X)
							 */
							else if(oc == 0xA1){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[lda]
								A = r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * LDY #8bit
							 */
							else{		/*0xA0*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[ldy]
								Y = l_or;
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
							}
						}
					}
					// 144-159
					else if(oc >= 0x90){
						if(oc >= 0x9C){
							/**/ if(oc == 0x9F){
							}
							else if(oc == 0x9E){
							}
							/**
							 * STA 16bit,X
							 */
							else if(oc == 0x9D){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[sta]
								src = A;
								w1(addr,src);
							}
							else{		/*0x9C*/
							}
						}
						else if(oc >= 0x98){
							/**/ if(oc == 0x9B){
							}
							/**
							 * TXS
							 */
							else if(oc == 0x9A){
								// 2.执行指令
								S = X;
							}
							/**
							 * STA 16bit,Y
							 */
							else if(oc == 0x99){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[sta]
								src = A;
								w1(addr,src);
							}
							/**
							 * TYA
							 */
							else{		/*0x98*/
								// 2.执行指令[tya]
								A = Y;
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
						}
						else if(oc >= 0x94){
							/**/ if(oc == 0x97){
							}
							/**
							 * STX 8bit,Y
							 */
							else if(oc == 0x96){
								// 1.零页Y变址寻址
								addr = vtMem[PC] + Y & 0xFF; PC += 1;
								// 2.执行指令[stx]
								vtMem[addr] = X;
							}
							/**
							 * STA 8bit,X
							 */
							else if(oc == 0x95){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[sta]
								vtMem[addr] = A;
							}
							/**
							 * STY 8bit,X
							 */
							else{		/*0x94*/
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[sty]
								vtMem[addr] = Y;
							}
						}
						else{
							/**/ if(oc == 0x93){
							}
							else if(oc == 0x92){
							}
							/**
							 * STA (8bit),Y
							 */
							else if(oc == 0x91){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[sta]
								src = A;
								w1(addr,src);
							}
							/**
							 * BCC #8bit
							 */
							else{		/*0x90*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[bcc]
								if(!CF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 128-143
					else{
						if(oc >= 0x8C){
							/**/ if(oc == 0x8F){
							}
							/**
							 * STX 16bit
							 */
							else if(oc == 0x8E){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[stx]
								src = X;
								w1(addr,src);
							}
							/**
							 * STA 16bit
							 */
							else if(oc == 0x8D){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[sta]
								src = A;
								w1(addr,src);
							}
							/**
							 * STY 16bit
							 */
							else{		/*0x8C*/
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[sty]
								src = Y;
								w1(addr,src);
							}
						}
						else if(oc >= 0x88){
							/**/ if(oc == 0x8B){
							}
							/**
							 * TXA
							 */
							else if(oc == 0x8A){
								// 2.执行指令[txa]
								A = X;
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else if(oc == 0x89){
							}
							/**
							 * DEY
							 */
							else{		/*0x88*/
								// 2.执行指令[dey]
								Y -= 1;
								Y &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(Y & 0x80);
								ZF = Y == 0;//!Y;
							}
						}
						else if(oc >= 0x84){
							/**/ if(oc == 0x87){
							}
							/**
							 * STX 8bit
							 */
							else if(oc == 0x86){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[stx]
								src = X;
								vtMem[addr] = src;
							}
							/**
							 * STA 8bit
							 */
							else if(oc == 0x85){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[sta]
								src = A;
								vtMem[addr] = src;
							}
							/**
							 * STY 8bit
							 */
							else{		/*0x84*/
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[sty]
								src = Y;
								vtMem[addr] = src;
							}
						}
						else{
							/**/ if(oc == 0x83){
							}
							else if(oc == 0x82){
							}
							/**
							 * STA (8bit,X)
							 */
							else if(oc == 0x81){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[sta]
								src = A;
								w1(addr,src);
							}
							else{		/*0x80*/
							}
						}
					}
				}
				else if(oc >= 0x40){
					// 112-127
					if(oc >= 0x70){
						if(oc >= 0x7C){
							/**/ if(oc == 0x7F){
							}
							/**
							 * ROR 16bit,X
							 */
							else if(oc == 0x7E){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[ror]
								src = r1(addr);
								tmpB = CF;
								CF = Utils.i2b(src & 0x01);
								src = src >> 1 | Utils.int(tmpB) << 7;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * ADC 16bit,X
							 */
							else if(oc == 0x7D){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[adc]
								src = r1(addr);
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							else{		/*0x7C*/
							}
						}
						else if(oc >= 0x78){
							/**/ if(oc == 0x7B){
							}
							else if(oc == 0x7A){
							}
							/**
							 * ADC 16bit,Y
							 */
							else if(oc == 0x79){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[adc]
								src = r1(addr);
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * SEI
							 */
							else{		/*0x78*/
								// 2.执行指令[sei]
								IF = true;
							}
						}
						else if(oc >= 0x74){
							/**/ if(oc == 0x77){
							}
							/**
							 * ROR 8bit,X
							 */
							else if(oc == 0x76){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[ror]
								src = vtMem[addr];
								tmpB = CF;
								CF = Utils.i2b(src & 0x01);
								src = src >> 1 | Utils.int(tmpB) << 7;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * ADC 8bit,X
							 */
							else if(oc == 0x75){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[adc]
								src = vtMem[addr];
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x74*/
							}
						}
						else{
							/**/ if(oc == 0x73){
							}
							else if(oc == 0x72){
							}
							/**
							 * ADC (8bit),Y
							 */
							else if(oc == 0x71){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[adc]
								src = r1(addr);
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * BVS #8bit
							 */
							else{		/*0x70*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[bvs]
								if(VF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 96-111
					else if(oc >= 0x60){
						if(oc >= 0x6C){
							/**/ if(oc == 0x6F){
							}
							/**
							 * ROR 16bit
							 */
							else if(oc == 0x6E){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[ror]
								src = r1(addr);
								tmpB = CF;
								CF = Utils.i2b(src & 0x01);
								src = src >> 1 | Utils.int(tmpB) << 7;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * ADC 16bit
							 */
							else if(oc == 0x6D){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[adc]
								src = r1(addr);
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * JMP (16bit)
							 */
							else{		/*0x6C*/
								// 1.相对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								l_addr = r1(addr);
								u_addr = r1(addr + 1 & 0xFFFF);
								addr = u_addr << 8 | l_addr;
								// 2.执行指令[jmp]
								PC = addr;
							}
						}
						else if(oc >= 0x68){
							/**/ if(oc == 0x6B){
							}
							/**
							 * ROR
							 */
							else if(oc == 0x6A){
								// 2.执行指令[ror]
								tmpB = CF;
								CF = Utils.i2b(A & 0x01);
								A = A >> 1 | Utils.int(tmpB) << 7;
								A &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * ADC #8bit
							 */
							else if(oc == 0x69){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[adc]
								src = l_or;
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * PLA
							 */
							else{		/*0x68*/
								// 2.执行指令[pla]
								S += 1;S &= 0xFF; // [fixed]
								A = vtMem[Utils.int(0x0100 + S)];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
						}
						else if(oc >= 0x64){
							/**/ if(oc == 0x67){
							}
							/**
							 * ROR 8bit
							 */
							else if(oc == 0x66){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[ror]
								src = vtMem[addr];
								tmpB = CF;
								CF = Utils.i2b(src & 0x01);
								src = src >> 1 | Utils.int(tmpB) << 7;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * ADC 8bit
							 */
							else if(oc == 0x65){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[adc]
								src = vtMem[addr];
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x64*/
							}
						}
						else{
							/**/ if(oc == 0x63){
							}
							else if(oc == 0x62){
							}
							/**
							 * ADC (8bit,X)
							 */
							else if(oc == 0x61){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[adc]
								src = r1(addr);
								dst = Utils.int(A + src) + Utils.int(CF);
								// 3.标志位设置
								CF = dst > 0xFF;
								dst &= 0xFF; // [fixed]
								VF = Utils.i2b(0x80 & ~(A ^ src) & (A ^ dst));
								A = dst;
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * RTS
							 */
							else{		/*0x60*/
								// 1.栈寻址
								S += 1;S &= 0xFF; // [fixed]
								l_addr = vtMem[Utils.int(0x0100 + S)];
								S += 1;S &= 0xFF; // [fixed]
								u_addr = vtMem[Utils.int(0x0100 + S)];
								// 2.执行指令[rts]
								addr = u_addr << 8 | l_addr;
								PC = addr + 1;
							}
						}
					}
					// 80-95
					else if(oc >= 0x50){
						if(oc >= 0x5C){
							/**/ if(oc == 0x5F){
							}
							/**
							 * LSR 16bit,X
							 */
							else if(oc == 0x5E){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[lsr]
								src = r1(addr);
								CF = Utils.i2b(src & 0x01);
								src >>= 1;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * EOR 16bit,X
							 */
							else if(oc == 0x5D){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[eor]
								A ^= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							else{		/*0x5C*/
							}
						}
						else if(oc >= 0x58){
							/**/ if(oc == 0x5B){
							}
							else if(oc == 0x5A){
							}
							/**
							 * EOR 16bit,Y
							 */
							else if(oc == 0x59){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[eor]
								A ^= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * CLI
							 */
							else{		/*0x58*/
								// 2.执行指令
								IF = false;
							}
						}
						else if(oc >= 0x54){
							/**/ if(oc == 0x57){
							}
							/**
							 * LSR 8bit,X
							 */
							else if(oc == 0x56){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[lsr]
								src = vtMem[addr];
								CF = Utils.i2b(src & 0x01);
								src >>= 1;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * EOR 8bit,X
							 */
							else if(oc == 0x55){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[eor]
								A ^= vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x54*/
							}
						}
						else{
							/**/ if(oc == 0x53){
							}
							else if(oc == 0x52){
							}
							/**
							 * EOR (8bit),Y
							 */
							else if(oc == 0x51){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[eor]
								A ^= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * BVC #8bit
							 */
							else{		/*0x50*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[bvc]
								if(!VF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 64-79
					else{
						if(oc >= 0x4C){
							/**/ if(oc == 0x4F){
							}
							/**
							 * LSR 16bit
							 */
							else if(oc == 0x4E){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[lsr]
								src = r1(addr);
								CF = Utils.i2b(src & 0x01);
								src >>= 1;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * EOR 16bit
							 */
							else if(oc == 0x4D){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[eor]
								A ^= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * JMP 16bit
							 */
							else{		/*0x4C*/
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[jmp]
								PC = addr;
							}
						}
						else if(oc >= 0x48){
							/**/ if(oc == 0x4B){
							}
							/**
							 * LSR
							 */
							else if(oc == 0x4A){
								// 2.执行指令[lsr]
								CF = Utils.i2b(A & 0x01);
								A >>= 1;
								A &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * EOR #8bit
							 */
							else if(oc == 0x49){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[eor]
								A ^= l_or;
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * PHA
							 */
							else{		/*0x48*/
								// 2.执行指令[pha]
								addr = 0x0100 + S;
								src = A;
								w1(addr,src);
								S -= 1;S &= 0xFF; // [fixed]
							}
						}
						else if(oc >= 0x44){
							/**/ if(oc == 0x47){
							}
							/**
							 * LSR 8bit
							 */
							else if(oc == 0x46){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[lsr]
								src = vtMem[addr];
								CF = Utils.i2b(src & 0x01);
								src >>= 1;
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * EOR 8bit
							 */
							else if(oc == 0x45){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[eor]
								A ^= vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x44*/
							}
						}
						else{
							/**/ if(oc == 0x43){
							}
							else if(oc == 0x42){
							}
							/**
							 * EOR (8bit,X)
							 */
							else if(oc == 0x41){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[eor]
								A ^= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * RTI
							 */
							else{		/*0x40*/
								// 栈还原
								S += 1;S &= 0xFF; // [fixed]
								P = vtMem[Utils.int(0x0100 + S)];
								NF = Utils.i2b(P & 0x80);
								VF = Utils.i2b(P & 0x40);
								RF = true;
								BF = Utils.i2b(P & 0x10);
								DF = Utils.i2b(P & 0x08);
								IF = Utils.i2b(P & 0x04);
								ZF = Utils.i2b(P & 0x02) ;
								CF = Utils.i2b(P & 0x01);
								// 栈寻址
								S += 1;S &= 0xFF; // [fixed]
								l_addr = vtMem[Utils.int(0x0100 + S)];
								S += 1;S &= 0xFF; // [fixed]
								u_addr = vtMem[Utils.int(0x0100 + S)];
								addr = u_addr << 8 | l_addr;
								PC = addr;
							}
						}
					}
				}
				else{
					// 48-63
					if(oc >= 0x30){
						if(oc >= 0x3C){
							/**/ if(oc == 0x3F){
							}
							/**
							 * ROL 16bit,X
							 */
							else if(oc == 0x3E){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[rol]
								src = r1(addr);
								tmpB = CF;
								CF = Utils.i2b(src & 0x80);
								src = src << 1 | Utils.int(tmpB);
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * AND 16bit,X
							 */
							else if(oc == 0x3D){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[and]
								A &= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							else{		/*0x3C*/
							}
						}
						else if(oc >= 0x38){
							/**/ if(oc == 0x3B){
							}
							else if(oc == 0x3A){
							}
							/**
							 * AND 16bit,Y
							 */
							else if(oc == 0x39){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[and]
								A &= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * SEC
							 */
							else{		/*0x38*/
								// 2.执行指令[sec]
								CF = true;
							}
						}
						else if(oc >= 0x34){
							/**/ if(oc == 0x37){
							}
							/**
							 * ROL 8bit,X
							 */
							else if(oc == 0x36){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[rol]
								src = vtMem[addr];
								tmpB = CF;
								CF = Utils.i2b(src & 0x80);
								src = src << 1 | Utils.int(tmpB);
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * AND 8bit,X
							 */
							else if(oc == 0x35){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[and]
								A &= vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x34*/
							}
						}
						else{
							/**/ if(oc == 0x33){
							}
							else if(oc == 0x32){
							}
							/**
							 * AND (8bit),Y
							 */
							else if(oc == 0x31){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[and]
								A &= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * BMI #8bit
							 */
							else{		/*0x30*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[bmi]
								if(NF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 32-47
					else if(oc >= 0x20){
						if(oc >= 0x2C){
							/**/ if(oc == 0x2F){
							}
							/**
							 * ROL 16bit
							 */
							else if(oc == 0x2E){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[rol]
								src = r1(addr);
								tmpB = CF;
								CF = Utils.i2b(src & 0x80);
								src = src << 1 | Utils.int(tmpB);
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * AND 16bit
							 */
							else if(oc == 0x2D){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[and]
								A &= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * BIT 16bit
							 */
							else{		/*0x2C*/
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[bit]
								src = r1(addr);
								ZF = (src & A) == 0;//!(src & A);
								NF = Utils.i2b(src & 0x80);
								VF = Utils.i2b(src & 0x40);
							}
						}
						else if(oc >= 0x28){
							/**/ if(oc == 0x2B){
							}
							/**
							 * ROL
							 */
							else if(oc == 0x2A){
								// 2.执行指令[rol]
								tmpB = CF;
								CF = Utils.i2b(A & 0x80);
								A = A << 1 | Utils.int(tmpB);
								A &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * AND #8bit
							 */
							else if(oc == 0x29){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[and]
								A &= l_or;
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * PLP
							 */
							else{		/*0x28*/
								// 2.执行指令[plp]
								S += 1;S &= 0xFF; // [fixed]
								P = vtMem[Utils.int(0x0100 + S)];
								NF = Utils.i2b(P & 0x80);
								VF = Utils.i2b(P & 0x40);
								RF = true;
								BF = Utils.i2b(P & 0x10);
								DF = Utils.i2b(P & 0x08);
								IF = Utils.i2b(P & 0x04);
								ZF = Utils.i2b(P & 0x02);
								CF = Utils.i2b(P & 0x01);
							}
						}
						else if(oc >= 0x24){
							/**/ if(oc == 0x27){
							}
							/**
							 * ROL 8bit
							 */
							else if(oc == 0x26){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[rol]
								src = vtMem[addr];
								tmpB = CF;
								CF = Utils.i2b(src & 0x80);
								src = src << 1 | Utils.int(tmpB);
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * AND 8bit
							 */
							else if(oc == 0x25){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[and]
								A &= vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * BIT 8bit
							 */
							else{		/*0x24*/
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[bit]
								src = vtMem[addr];
								ZF = (src & A) == 0;//!(src & A);
								NF = Utils.i2b(src & 0x80);
								VF = Utils.i2b(src & 0x40);
							}
						}
						else{
							/**/ if(oc == 0x23){
							}
							else if(oc == 0x22){
							}
							/**
							 * AND (8bit,X)
							 */
							else if(oc == 0x21){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[and]
								A &= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * JSR 16bit
							 */
							else{		/*0x20*/
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[jsr]
								PC -= 1; // 跳回来一下
								vtMem[Utils.int(0x0100 + S)] = PC >> 8;
								S -= 1;S &= 0xFF; // [fixed]
								vtMem[Utils.int(0x0100 + S)] = PC & 0xFF;
								S -= 1;S &= 0xFF; // [fixed]
								PC = addr;
							}
						}
					}
					// 16-31
					else if(oc >= 0x10){
						if(oc >= 0x1C){
							/**/ if(oc == 0x1F){
							}
							/**
							 * ASL 16bit,X
							 */
							else if(oc == 0x1E){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[asl]
								src = r1(addr);
								CF = Utils.i2b(src & 0x80);
								src <<= 1;
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * ORA 16bit,X
							 */
							else if(oc == 0x1D){
								// 1.绝对X变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + X & 0xFFFF;
								// 2.执行指令[ora]
								A |= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							else{		/*0x1C*/
							}
						}
						else if(oc >= 0x18){
							/**/ if(oc == 0x1B){
							}
							else if(oc == 0x1A){
							}
							/**
							 * ORA 16bit,Y
							 */
							else if(oc == 0x19){
								// 1.绝对Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								tmpN = u_or << 8 | l_or;
								addr = tmpN + Y;
								// 2.执行指令[ora]
								A |= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * CLC
							 */
							else{		/*0x18*/
								// 2.执行指令[cls]
								CF = false;
							}
						}
						else if(oc >= 0x14){
							/**/ if(oc == 0x17){
							}
							/**
							 * ASL 8bit,X
							 */
							else if(oc == 0x16){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[asl]
								src = vtMem[addr];
								CF = Utils.i2b(src & 0x80);
								src <<= 1;
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * ORA 8bit,X
							 */
							else if(oc == 0x15){
								// 1.零页X变址寻址
								addr = vtMem[PC] + X & 0xFF; PC += 1;
								// 2.执行指令[ora]
								A |= vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x14*/
							}
						}
						else{
							/**/ if(oc == 0x13){
							}
							else if(oc == 0x12){
							}
							/**
							 * ORA (8bit),Y
							 */
							else if(oc == 0x11){
								// 1.先零页间址后Y变址寻址
								l_or = vtMem[PC]; PC += 1;
								tmpN = vtMem[l_or + 1 & 0xFF] << 8 | vtMem[l_or];
								addr = tmpN + Y;
								// 2.执行指令[ora]
								A |= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
								// 9.累增时钟周期
								executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
							}
							/**
							 * BPL #8bit
							 */
							else{		/*0x10*/
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[bpl]
								if(!NF){
									tmpN = PC;
									addr = PC + (Utils.int(l_or << 24) >> 24) & 0xFFFF;
									PC = addr;
									// 9.累增时钟周期
									executedCC += 1;
									executedCC += Utils.int((tmpN & 0xFF00) != (addr & 0xFF00));
								}
							}
						}
					}
					// 0-15
					else{
						if(oc >= 0x0C){
							/**/ if(oc == 0x0F){
							}
							/**
							 * ASL 16bit
							 */
							else if(oc == 0x0E){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[asl]
								src = r1(addr);
								CF = Utils.i2b(src & 0x80);
								src <<= 1;
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								w1(addr,src);
							}
							/**
							 * ORA 16bit
							 */
							else if(oc == 0x0D){
								// 1.绝对寻址
								l_or = vtMem[PC]; PC += 1;
								u_or = vtMem[PC]; PC += 1;
								addr = u_or << 8 | l_or;
								// 2.执行指令[ora]
								A |= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x0C*/
							}
						}
						else if(oc >= 0x08){
							/**/ if(oc == 0x0B){
							}
							/**
							 * ASL
							 */
							else if(oc == 0x0A){
								// 2.执行指令[asl]
								CF = Utils.i2b(A & 0x80);
								A <<= 1;
								A &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * ORA #8bit
							 */
							else if(oc == 0x09){
								// 1.立即数寻址
								l_or = vtMem[PC]; PC += 1;
								// 2.执行指令[ora]
								A |= l_or;
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * PHP
							 */
							else{		/*0x08*/
								// 2.执行指令[php]
								P = Utils.int(NF) << 7 | Utils.int(VF) << 6 | Utils.int(RF) << 5 | Utils.int(BF) << 4 | Utils.int(DF) << 3 | Utils.int(IF) << 2 | Utils.int(ZF) << 1 | Utils.int(CF);
								vtMem[Utils.int(0x0100 + S)] = P;
								S -= 1;S &= 0xFF; // [fixed]
							}
						}
						else if(oc >= 0x04){
							/**/ if(oc == 0x07){
							}
							/**
							 * ASL 8bit
							 */
							else if(oc == 0x06){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[asl]
								src = vtMem[addr];
								CF = Utils.i2b(src & 0x80);
								src <<= 1;
								src &= 0xFF; // [fixed]
								// 3.标志位设置
								NF = Utils.i2b(src & 0x80);
								ZF = src == 0;//!src;
								// 4.保存数据
								vtMem[addr] = src;
							}
							/**
							 * ORA 8bit
							 */
							else if(oc == 0x05){
								// 1.零页寻址
								addr = vtMem[PC]; PC += 1;
								// 2.执行指令[ora]
								A |= vtMem[addr];
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							else{		/*0x04*/
							}
						}
						else{
							/**/ if(oc == 0x03){
							}
							else if(oc == 0x02){
							}
							/**
							 * ORA (8bit,X)
							 */
							else if(oc == 0x01){
								// 1.先零页X变址后间址寻址
								l_or = vtMem[PC]; PC += 1;
								addr = vtMem[Utils.int(l_or + X) + 1 & 0xFF] << 8 | vtMem[l_or + X & 0xFF];
								// 2.执行指令[ora]
								A |= r1(addr);
								// 3.标志位设置
								NF = Utils.i2b(A & 0x80);
								ZF = A == 0;//!A;
							}
							/**
							 * BRK(软中断)
							 */
							else{		/*0x00*/
								// 步骤1 - stack <- PC + 2
								PC += 1;
								vtMem[Utils.int(0x0100 + S)] = PC >> 8;
								S -= 1;S &= 0xFF; // [fixed]
								vtMem[Utils.int(0x0100 + S)] = PC & 0xFF;
								S -= 1;S &= 0xFF; // [fixed]
								// 步骤2
								BF = true;
								// 步骤3 - stack <- P
								P = Utils.int(NF) << 7 | Utils.int(VF) << 6 | Utils.int(RF) << 5 | Utils.int(BF) << 4 | Utils.int(DF) << 3 | Utils.int(IF) << 2 | Utils.int(ZF) << 1 | Utils.int(CF);
								vtMem[Utils.int(0x0100 + S)] = P;
								S -= 1;S &= 0xFF; // [fixed]
								// 步骤4
								IF = true;
								// 步骤5
								PC = vtMem[0xFFFF] << 8 | vtMem[0xFFFE];
								// 步骤6
								// IF = false;
							}
						}
					}
				}
				// get clock cycles of current instruction(获取当前指令的时钟频率)
				ocCC = CC[oc];
				if(ocCC == 0){
					//trace('无效指令(invalid instruction):',oc.toString(16),lastPC.toString(16));
					executedCC += 2;
					return false;
				}
				// sum clock cycles of executed(累积已执行的指令时钟频率)
				executedCC += ocCC;
				// execute interrupt(执行中断)
				if(bus.ppu.nENC != 0){
					bus.ppu.nENC -= ocCC;
					if(bus.ppu.nENC <=0){
						NMI();
						bus.ppu.nENC = 0;
					}
				}
				// if execute finish(执行到目标时钟频率)
				if(executedCC >= requiredCC){
					return true;
				}
			}
			return true;
		}
	}