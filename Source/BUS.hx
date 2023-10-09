package;

import openfl.Vector;
import openfl.utils.Function;
import flash.display.Bitmap;
	
	class BUS {
        
	/** public variant
	---------------------------*/
	//clear#
		public var cpu:CPU;
		public var ppu:PPU;
		public var apu:APU;
		public var joypad:Joypad;

		public var mapper0:Mapper0;
		public var mapper1:Mapper1;
		public var mapper2:Mapper2;
		public var mapper3:Mapper3;
	//clear#

		public var vtMapper_W:Array<Function>;	// Mapper write function set	- Mapper写入函数集
		public var vtMapper_R:Array<Function>;	// Mapper reset function set	- Mapper重置函数集
		
		public var nMapper:Int = 0;						// Curreent Mapper Number		- 当前Mapper号
		public var vtRom:Array<Int>;				// ROM of Vector type			- Vector类型的ROM
		public var curPAL:Vector<UInt>;			// Current Palette				- 当前调色板

		public var nPRomNum:Int = 0;					// Program Rom Number			- 程序ROM数目
		public var nVRomNum:Int = 0;					// Video Rom Number,someone call 'Character Rom(CHR)'	- 图形ROM数目
		public var bMirror_V:Bool;				// Vertical Mirror Flag			- 垂直镜像标志
		public var bMirror_F:Bool;				// Four Screen Mirror Flag		- 四屏镜像标志
		public var bMirror_S:Bool;				// Single Screen Mirror Flag	- 单屏镜像标志
		public var bBattery:Bool;				// Battery Flag[not uesd]		- 电池标志
		public var bTrainer:Bool;				// Trainer Flag					- 引导程序标志

	/** construction
	---------------------------*/
		public function new(){
			cpu = new CPU();			cpu.bus = this;
			ppu = new PPU();			ppu.bus = this;
			apu = new APU();			apu.bus = this;
			joypad = new Joypad();		joypad.bus = this;
	
			mapper0 = new Mapper0();	mapper0.bus = this;
			mapper1 = new Mapper1();	mapper1.bus = this;
			mapper2 = new Mapper2();	mapper2.bus = this;
			mapper3 = new Mapper3();	mapper3.bus = this;

 			vtMapper_W = new Array<Function>();//(0x200);
			vtMapper_W[0] = mapper0.write;
			vtMapper_W[1] = mapper1.write;
			vtMapper_W[2] = mapper2.write;	
			vtMapper_W[3] = mapper3.write;	
			
			vtMapper_R  =  [for(c in 0...0x200) null];//(0x200);
			vtMapper_R[0] = mapper0.reset;
			vtMapper_R[1] = mapper1.reset;
			vtMapper_R[2] = mapper2.reset;
			vtMapper_R[3] = mapper3.reset;
			
			nMapper = 0;
			vtRom = new Array<Int>();
			
			nPRomNum = 0;
			nVRomNum = 0;
			bMirror_V = false;
			bMirror_F = false;
			bMirror_S = false;
			bBattery = false;
			bTrainer = false;
		}
		/*
		//
		// nes memory mapping
		//
		// CPU memory map(own 64KB memory addresses,actually only have 2KB physical memory)
		public const U_ROM:Int				= 0xC000;		// Upper Program ROM
		public const L_ROM:Int				= 0x8000;		// Lower Program ROM
		public const SRAM:Int				= 0x6000;		// Save RAM(within cartridge)
		public const EXP_ROM:Int			= 0x4020;		// Expansion ROM
		public const CPU_IO_REG:Int			= 0x4000;		// I/O register of CPU
		public const PPU_IO_REG:Int			= 0x2000;		// I/O register of PPU
		public const RAM_MIR_2:Int			= 0x1800;		// RAM Mirror 2
		public const RAM_MIR_1:Int			= 0x1000;		// RAM Mirror 1
		public const RAM_MIR_0:Int			= 0x0800;		// RAM Mirror 0	
		public const RAM:Int				= 0x0000;		// RAM
		// bytes[0x0200-0x7FFF]
		public const TEMP:Int				= 0x0200;		// temporary data	- 1536 bytes
		// bytes[0x0100-0X01FF]
		public const STACK:Int				= 0x0100;		// stack 			- 256 bytes			
		// bytes[0x0000-0x00FF]
		public const ZP:Int					= 0x0000;		// zero page		- 256 bytes(1 page)
		// ----------------------------------------------------------------------------------------------
		public const U_ROM_END:Int			= 0xFFFF;
		public const L_ROM_END:Int			= 0xBFFF;
		public const SRAM_END:Int			= 0x7FFF;
		public const EXP_ROM_END:Int		= 0x5FFF;
		public const CPU_IO_REG_END:Int		= 0x401F;
		public const PPU_IO_REG_END:Int		= 0x2007;
		public const RAM_MIR_2_END:Int		= 0x1FFF;
		public const RAM_MIR_1_END:Int		= 0x17FF;
		public const RAM_MIR_0_END:Int		= 0x0FFF;
		public const RAM_END:Int			= 0x07FF;
		// ----------------------------------------------------------------------------------------------
		public const U_ROM_SIZE:Int			= 0x4000;		// 16KB
		public const L_ROM_SIZE:Int			= 0x4000;		// 16KB
		public const SRAM_SIZE:Int			= 0x1FE0;		// 8160 bytes
		public const EXP_ROM_SIZE:Int		= 0x1FE0;		// 8160 bytes
		public const CPU_IO_REG_SIZE:Int	= 0x0020;		// 32 bytes
		public const PPU_IO_REG_SIZE:Int	= 0x0008;		// 8 bytes
		public const RAM_MIR_2_SIZE:Int		= 0x0800;		// 2K
		public const RAM_MIR_1_SIZE:Int		= 0x0800;		// 2K
		public const RAM_MIR_0_SIZE:Int		= 0x0800;		// 2K
		public const RAM_SIZE:Int			= 0x0800;		// 2K
		
		// PPU memroy map(own 64KB memory addresses,actually only have 2048+32=2080 bytes physical memory)
		public const SPRITE_PAT:Int			= 0x3F10;		// sprite palette
		public const IMAGE_PAT:Int			= 0x3F00;		// image palette
		public const AT_3:Int				= 0x2FC0;		// Attribute Table 3(Mirror or External RAM[cartridge])
		public const NT_3:Int				= 0x2C00;		// Name Table 3
		public const AT_2:Int				= 0x2BC0;		// Attribute Table 2(Mirror or External RAM[cartridge])
		public const NT_2:Int				= 0x2800;		// Name Table 2
		public const AT_1:Int				= 0x27C0;		// Attribute Table 1
		public const NT_1:Int				= 0x2400;		// Name Table 1
		public const AT_0:Int				= 0x23C0;		// Attribute Table 0
		public const NT_0:Int				= 0x2000;		// Name Table 0
		public const PT_1:Int				= 0x1000;		// Pattern Table 1(VROM)
		public const PT_0:Int				= 0x0000;		// Pattern Table 0(VROM)
		// ----------------------------------------------------------------------------------------------
		public const SPRITE_PAT_END:Int		= 0x3F1F;
		public const IMAGE_PAT_END:Int		= 0x3F0F;
		public const AT_3_END:Int			= 0x2FFF;
		public const NT_3_END:Int			= 0x2FBF;
		public const AT_2_END:Int			= 0x2BFF;
		public const NT_2_END:Int			= 0x2BBF;
		public const AT_1_END:Int			= 0x27FF;
		public const NT_1_END:Int			= 0x27BF;
		public const AT_0_END:Int			= 0x23FF;
		public const NT_0_END:Int			= 0x23BF;
		public const PT_1_END:Int			= 0x1FFF;
		public const PT_0_END:Int			= 0x0FFF;
		// ----------------------------------------------------------------------------------------------
		public const SPRITE_PAT_SIZE:Int	= 0x0010;		// 16 bytes
		public const IMAGE_PAT_SIZE:Int		= 0x0010;		// 16 bytes
		public const AT_3_SIZE:Int			= 0x0040;		// 64 bytes
		public const NT_3_SIZE:Int			= 0x03C0;		// 960 bytes
		public const AT_2_SIZE:Int			= 0x0040;		// 64 bytes
		public const NT_2_SIZE:Int			= 0x03C0;		// 960 bytes
		public const AT_1_SIZE:Int			= 0x0040;		// 64 bytes
		public const NT_1_SIZE:Int			= 0x03C0;		// 960 bytes
		public const AT_0_SIZE:Int			= 0x0040;		// 64 bytes
		public const NT_0_SIZE:Int			= 0x03C0;		// 960 bytes
		public const PT_1_SIZE:Int			= 0x1000;		// 4KB
		public const PT_0_SIZE:Int			= 0x1000;		// 4KB
		public const PT_SIZE:Int			= PT_0_SIZE + PT_1_SIZE;	// 8KB
		*/
	}