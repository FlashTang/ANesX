package;

class Mapper1 extends Node implements Mapper {
	private var nShiftReg:Int = 0;
	private var nReg0:Int = 0;
	private var nReg1:Int = 0;
	private var nReg2:Int = 0;
	private var nReg3:Int = 0;

	private var nTemp:Int = 0;
	private var nRomMode:Int = 0;
	private var b8kVRom:Bool;
	private var nVRomSize:Int = 0;

	function int(x:Any):Int {
		return Std.int(x);
	}

	// 构造函数
	public function new() {
		nShiftReg = 0;
		nReg0 = -1;
		nReg1 = -1;
		nReg2 = -1;
		nReg3 = -1;

		nTemp = 0;
		nRomMode = 0;
		b8kVRom = false;
		nVRomSize = 0;
	}

	// 复位
	public function reset():Void {
	 
		var offset:Int = 0;
		// load first PRG-ROM of 16K	- 载入第一个16K的PRG-ROM
		offset = 0x10;

		for (i in 0...0x4000) {
			bus.cpu.vtMem[int(0x8000 + i)] = bus.vtRom[int(offset + i)];
		}
		// load last PRG-ROM of 16K		- 载入最后一个16K的PRG-ROM
		offset = 0x10 + int(int(bus.nPRomNum - 1) * 0x4000);

		for (i in 0...0x4000) {
			bus.cpu.vtMem[int(0xC000 + i)] = bus.vtRom[int(offset + i)];
		}
	}

	// 写入
	public function write(addr:Int, data:Int):Void {
		 
		var offset:Int = 0;
		// reset by shift
		if (nShiftReg == 5) {
			nShiftReg = nTemp = 0;
		}
		// reset by bit
		if ((data & 0x80) != 0) {
			nShiftReg = nTemp = 0;
			nRomMode = 3;
			return;
		}
		// shift data
		nTemp |= (data & 0x1) << nShiftReg;
		nShiftReg += 1;
		if (nShiftReg < 5) {
			return;
		}
		// register 0(configuration)	- 配置寄存器
		if (addr < 0xA000) {
			bus.bMirror_V = (nTemp & 0x1) == 0;//!(nTemp & 0x1);
			bus.bMirror_S = (nTemp & 0x2) == 0;//!(nTemp & 0x2);
			nRomMode = (nTemp & 0xC) >> 2;
			b8kVRom = (nTemp & 0x10) == 0;//!(nTemp & 0x10);
		}
		// register 1(swtich lower VROM of 4K or 8K) - VROM低部4K或8K切换
		else if (addr < 0xC000) {
			nTemp &= 0x1F;
			if (nReg1 == nTemp) {
				return;
			}
			nReg1 = nTemp;
			if (b8kVRom) {
				offset = 0x10 + int(int(bus.nPRomNum * 0x4000) + int(int(nReg1 % int(bus.nVRomNum)) * 0x2000));
				nVRomSize = 0x2000;
			} else {
				offset = 0x10 + int(int(bus.nPRomNum * 0x4000) + int(int(nReg1 % int(bus.nVRomNum * 2)) * 0x1000));
				nVRomSize = 0x1000;
			}

			for (i in 0...nVRomSize) {
				bus.ppu.vtVRam[i] = bus.vtRom[int(offset + i)];
			}
		}
		// register 2(swtich upper VROM of 4K)		- VROM高部4K切换
		else if (addr < 0xE000) {
			nTemp &= 0x1F;
			if (nReg2 == nTemp) {
				return;
			}
			nReg2 = nTemp;
			if (b8kVRom) {
				return;
			}
			offset = 0x10 + int(int(bus.nPRomNum * 0x4000) + int(int(nReg2 % int(bus.nVRomNum * 2)) * 0x1000));

			for (i in 0...0x1000) {
				bus.ppu.vtVRam[int(0x1000 + i)] = bus.vtRom[int(offset + i)];
			}
		}
		// register 3(swtich PRG-ROM bank)					- 切换RPG-ROM
		else {
			if (nReg3 == nTemp) {
				return;
			}
			nReg3 = nTemp;
			if (nRomMode == 0 || nRomMode == 1) { // switch 32K PRG-ROM			- 切换32K的PRG-ROM
				offset = 0x10 + int((nReg3 >> 1 & 0x7) % int(bus.nPRomNum / 2) * 0x8000);

				for (i in 0...0x8000) {
					bus.cpu.vtMem[int(0x8000 + i)] = bus.vtRom[int(offset + i)];
				}
			} else if (nRomMode == 2) { // switch upper PRG-ROM of 16K	- 切换高部16K的PRG-ROM
				offset = 0x10 + int(int(nReg3 % bus.nPRomNum) * 0x4000);

				for (i in 0...0x4000) {
					bus.cpu.vtMem[int(0xC000 + i)] = bus.vtRom[int(offset + i)];
				}
				// must be need:load first PRG-ROM of 16K(载入第一个16K的PRG-ROM)
				// offset = 0x10;
				// for(i = 0;i < 0x4000; i+=1){
				//	bus.cpu.vtMem[int(0x8000 + i)] = bus.vtRom[int(offset + i)];
				// }
			} else if (nRomMode == 3) { // switch lower PRG-ROM of 16K	- 切换低部16K的PRG-ROM
				offset = 0x10 + int(int(nReg3 % bus.nPRomNum) * 0x4000);

				for (i in 0...0x4000) {
					bus.cpu.vtMem[int(0x8000 + i)] = bus.vtRom[int(offset + i)];
				}
				// must be need:load last PRG-ROM of 16K(载入最后一个16K的PRG-ROM)
				// offset = 0x10 + int(int(bus.nPRomNum - 1) * 0x4000);
				// for(i = 0;i < 0x4000; i+=1){
				//	bus.cpu.vtMem[int(0xC000 + i)] = bus.vtRom[int(offset + i)];
				// }
			}
		}
	}
}
