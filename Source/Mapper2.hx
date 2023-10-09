package;

class Mapper2 extends Node implements Mapper {
	function int(x:Any):Int {
		return Std.int(x);
	}

	private var nReg:Int;

	// 构造函数
	public function new() {
		nReg = -1;
	}

	// 复位
	public function reset():Void {
		var i:Int;
		var offset:Int;
		// load first PRG-ROM of 16K	- 载入第一个16K的PRG-ROM
		offset = 0x10;
		for (i in 0...0x4000) {
			bus.cpu.vtMem[int(0x8000 + i)] = bus.vtRom[int(offset + i)];
		}
		// load last PRG-ROM of 16K		- 载入最后一个16K的PRG-ROM
		offset = 0x10 + (bus.nPRomNum - 1) * 0x4000;
		for (i in 0...0x4000) {
			bus.cpu.vtMem[int(0xC000 + i)] = bus.vtRom[int(offset + i)];
		}
	}

	// 写入
	public function write(addr:Int, src:Int):Void {
		if (nReg == src) {
			return;
		}
		nReg = src;
	
		var offset:Int = 0;
		// switch lower PRG-ROM of 16K	- 切换低部的16K PRG-ROM
		offset = 0x10 + int(int(src % bus.nPRomNum) * 0x4000);
		for (i in 0...0x4000) {
			bus.cpu.vtMem[int(0x8000 + i)] = bus.vtRom[int(offset + i)];
		}
	}
}
