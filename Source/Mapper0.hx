package;

class Mapper0 extends Node implements Mapper {
    function int(x:Any):Int {
        return Std.int(x);
    }
	// 构造函数
	public function new() {}

	// 复位
	public function reset():Void {
	 
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

		// load VROM of 8K				- 载入8K VROM
		offset = 0x10 + bus.nPRomNum * 0x4000;
		if (bus.nVRomNum != 0) {
			for (i in 0...0x2000) {
				bus.ppu.vtVRam[i] = bus.vtRom[int(offset + i)];
			}
		}
	}

	// 写入
	public function write(addr:Int, src:Int):Void {}
}
