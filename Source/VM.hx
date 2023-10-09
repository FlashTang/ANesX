package;

import openfl.Vector;
import openfl.utils.Function;
import openfl.utils.Object;
import openfl.display.Bitmap;
import openfl.events.TimerEvent;
import openfl.text.TextField;
import openfl.utils.ByteArray;
import openfl.utils.Timer;
import openfl.Lib.getTimer;

class VM {
	function int(x:Any):Int {
		return Std.int(x);
	}

	function Boolean(x:Int):Bool {
		return x != 0;
	}

	/** private const
		--------------------------- */
	private var FREE:Int = 1;

	private var RUN:Int = 2;
	private var STOP:Int = 3;

	/** private variant
		--------------------------- */
	// clear#
	private var bus:BUS; // bus

	// clear#
	private var fc_fps:Int = 60; // fps
	private var fc_ft:Int = Std.int(1000 / 60); // fps interval

	private var TV:Bitmap; // display object by connect(显示器)
	private var nextScanline:Int = 0;

	private var thread:Timer;
	private var runSecond:Int = 0;
	private var runTime:Int = 0;

	private var vtPalette:Array<Vector<UInt>>; // NES palette set(调色板集)

	private var status:Int;

	/** construction
		--------------------------- */
	public function new() {
		// create thread
		thread = new Timer(100);
		thread.addEventListener(TimerEvent.TIMER, run);
		// create palette set(Nes only support 64 colors,the color show diffrent in diffrent TV mode,then i added two normal palette in here)
		// 创建调色板(Nes仅支持64种颜色,不同显示模式的颜色显示不同,所以我添加在这里添加了两种常见的调色板)
		vtPalette = [for(c in 0...0xff) null]; // (0xFF);
		// #0 palette is defined in NesDoc
		// 0号调色板是NesDoc里定义的
		var arr:Array<UInt> = [
			0xFF757575, 0xFF271B8F, 0xFF0000AB, 0xFF47009F, 0xFF8F0077, 0xFFAB0013, 0xFFA70000, 0xFF7F0B00, 0xFF432F00, 0xFF004700, 0xFF005100, 0xFF003F17,
			0xFF1B3F5F, 0xFF000000, 0xFF000000, 0xFF000000, 0xFFBCBCBC, 0xFF0073EF, 0xFF233BEF, 0xFF8300F3, 0xFFBF00BF, 0xFFE7005B, 0xFFDB2B00, 0xFFCB4F0F,
			0xFF8B7300, 0xFF009700, 0xFF00AB00, 0xFF00933B, 0xFF00838B, 0xFF000000, 0xFF000000, 0xFF000000, 0xFFFFFFFF, 0xFF3FBFFF, 0xFF5F97FF, 0xFFA78BFD,
			0xFFF77BFF, 0xFFFF77B7, 0xFFFF7763, 0xFFFF9B3B, 0xFFF3BF3F, 0xFF83D313, 0xFF4FDF4B, 0xFF58F898, 0xFF00EBDB, 0xFF000000, 0xFF000000, 0xFF000000,
			0xFFFFFFFF, 0xFFABE7FF, 0xFFC7D7FF, 0xFFD7CBFF, 0xFFFFC7FF, 0xFFFFC7DB, 0xFFFFBFB3, 0xFFFFDBAB, 0xFFFFE7A3, 0xFFE3FFA3, 0xFFABF3BF, 0xFFB3FFCF,
			0xFF9FFFF3, 0xFF000000, 0xFF000000, 0xFF000000
		];
		vtPalette[0] = new Vector(arr.length);
        for(c in 0...arr.length){
            vtPalette[0][c] = arr[c];
        }
		// #1 palette is used in many nes emulator
		// 1号调色板被使用在很多模拟器里
        arr = [
			0xFF7F7F7F, 0xFF2000B0, 0xFF2800B8, 0xFF6010A0, 0xFF982078, 0xFFB01030, 0xFFA03000, 0xFF784000, 0xFF485800, 0xFF386800, 0xFF386C00, 0xFF306040,
			0xFF305080, 0xFF000000, 0xFF000000, 0xFF000000, 0xFFBCBCBC, 0xFF4060F8, 0xFF4040FF, 0xFF9040F0, 0xFFD840C0, 0xFFD84060, 0xFFE05000, 0xFFC07000,
			0xFF888800, 0xFF50A000, 0xFF48A810, 0xFF48A068, 0xFF4090C0, 0xFF000000, 0xFF000000, 0xFF000000, 0xFFFFFFFF, 0xFF60A0FF, 0xFF5080FF, 0xFFA070FF,
			0xFFF060FF, 0xFFFF60B0, 0xFFFF7830, 0xFFFFA000, 0xFFE8D020, 0xFF98E800, 0xFF70F040, 0xFF70E090, 0xFF60D0E0, 0xFF606060, 0xFF000000, 0xFF000000,
			0xFFFFFFFF, 0xFF90D0FF, 0xFFA0B8FF, 0xFFC0B0FF, 0xFFE0B0FF, 0xFFFFB8E8, 0xFFFFC8B8, 0xFFFFD8A0, 0xFFFFF090, 0xFFC8F080, 0xFFA0F0A0, 0xFFA0FFC8,
			0xFFA0FFF0, 0xFFA0A0A0, 0xFF000000, 0xFF000000
		];
		vtPalette[1] = new Vector(arr.length);
		for(c in 0...arr.length){
            vtPalette[1][c] = arr[c];
        }
		// set status
		status = FREE;
	}

	/** public function
		--------------------------- */
	// 连接一个添加到舞台的显示位图对像(connect a display bitmap of added to stage)
	public function connectTV(obj:Bitmap):Void {
		this.TV = obj;
	}

	// 插卡
	public function insertCartridge(iNes:ByteArray):Bool {
		// bytes[0-3]
		trace("插入"); // NES file flag(NES文件标志)
		if (iNes[0] != 0x4E || iNes[1] != 0x45 || iNes[2] != 0x53 || iNes[3] != 0x1A) {
			trace('无效Nes文件(invalid Nes file)');
			return false;
		}
		// byte4
		bus.nPRomNum = iNes[4]; // Program ROM number,every one 16KB	- PROM数量,每个16KB
		// byte5
		bus.nVRomNum = iNes[5]; // Vedio ROM number,every one 8K		- VROM数量,每个8K
		// byte6
		/* bit0 */ bus.bMirror_V = Boolean(iNes[6] & 0x01); // Mirror Flag,0:horizontal;1:Vertical	- 镜像标志,0:横向;1:纵向
		/* bit1 */ bus.bBattery = Boolean(iNes[6] & 0x02); // Save RAM($6000-$7FFF)
		/* bit2 */ bus.bTrainer = Boolean(iNes[6] & 0x04); // Trainer Flag							- 引导标志
		/* bit3 */ bus.bMirror_F = Boolean(iNes[6] & 0x08); // Four Screen Dlag						- 四屏标志
		/* bit[4-7] */ bus.nMapper = (iNes[6] & 0xF0) >> 4; // Lower 4 bits of Mapper				- Mapper的低4位

		// byte7
		/* bit[0-3] */
		/* bit[4-7] */ bus.nMapper |= (iNes[7] & 0xF0); // Upper 4 bits of Mapper				- Mapper的高4位

		// byte[8-F]
		// Preserve,must be 0(预留,必须是0)

		// convert ByteArray to Vector for improve I/0 speed
		// 转换ByteArray为Vector是为了提高I/O速度
		for (k in 0...iNes.length) {
			// if(bus.vtRom == null){
			//     bus.vtRom = [];
			// }
			// while(bus.vtRom.length < k + 1){
			//     bus.vtRom.push(0);
			// }
			bus.vtRom[k] = iNes[k];
		}

		// cope Mapper(处理Mapper)
		var mapper_reset:Function = bus.vtMapper_R[bus.nMapper];

		if (mapper_reset == null) {
			trace('尚未支持的Mapper类型(unsupport mapper type):', bus.nMapper);
			return false;
		}
		// reset status(复位状态)
		mapper_reset();
		bus.cpu.reset();
		// start run(开始执行)
		thread.start();
		// set status
		status = RUN;
		return true;
	}

	// 复位
	public function reset():Void {
		thread.stop();

		nextScanline = 0;
		runSecond = 0;
		runTime = 0;

		// clear#
		bus = null;
		bus = new BUS();
		// clear#	BUS_BUS();

		if (bus.curPAL == null || bus.curPAL.length == 0) {
            //trace(vtPalette[0],"[][][][][][][");
			bus.curPAL = vtPalette[0];
		}
	}

	// 暂停
	public function suspend():Void {
		if (status == RUN) {
			thread.stop();
			// set status
			status = STOP;
		}
	}

	// 恢复
	public function resume():Void {
		if (status == STOP) {
			thread.start();
			// set status
			status = RUN;
		}
	}

	// 设置调色板
	public function setPalette(index:Int):Void {
		bus.curPAL = vtPalette[index];
	}

	// 触发手柄
	// 手柄按钮		 - 右   左   上   下   选择  开始  B键  A键
	// joypad button - R  L  U  D  SE  ST   B  A
	// joypad bit	 - 7  6  5  4   3   2   1  0
	public function touchJoypad(joypad1:UInt, joypad2:UInt):Void {
		bus.joypad.dev0 &= 0xFFFFFF00;
		bus.joypad.dev0 |= joypad1 & 0xFF;
		bus.joypad.dev1 &= 0xFFFFFF00;
		bus.joypad.dev1 |= joypad2 & 0xFF;
	}

	/** private function
		--------------------------- */
	// 运行
	var aaa = 0;

	private function run(e:TimerEvent):Void {
		var vm_ft:Int = getTimer();

		// output image
		TV.bitmapData.unlock();

		if (bus.ppu.vtIMG[0] != 0) {
			if (aaa++ % 20 == 0) {
                //此处bus.ppu.vtIMG数据和原版不对
				//trace(bus.ppu.vtIMG);
			}
			// thread.stop();
		}

		
		TV.bitmapData.setVector(TV.bitmapData.rect, bus.ppu.vtIMG);
		
		TV.bitmapData.lock();

		// remark:NTSC mode
		// PPU cycle is 21.48MHz divide by 4
		// one PPU clock cycle = three CPU clock cycle
		// one scanline:1364 PPU cc = 1364 / (3*4) = 114 CPU cc,HDraw get 85.3 CPU cc,HBlank get 28.3 CPU cc
		// 注:NTSC制式
		// PPU频率为21.48MHz分为4份
		// PPU 1cc对应CPU 3cc
		// 每条扫描述总周期:1364cc,对应的CPU是1364 / (3*4) = 114cc,HDraw占85.3,HBlank占28.3(不可用86和29,宁缺勿多)
		// 113.85321246819338422391857506361
		// 85.47337944826248199801511793631
		// 28.37983301993090222590345712729

		// because of DMA,so VM maybe scan multi-line in one times
		// 因为DMA,所以可能一次扫描多条扫描线

		var bankCC:Int = 0;
		while (true) {
			// 1.CPU cc of HDraw of need to execute(执行HDraw相应的CPU时钟频率)
			bankCC = 85;
			if (bus.cpu.executedCC < bankCC) {
				// trace("oooooo>>>",bankCC - bus.cpu.executedCC);
				if (bus.cpu.exec(bankCC - bus.cpu.executedCC) == false) {
					thread.stop();
					return;
				}
			}
			// 2.reset CPU cc(重置CPU时钟频率)
			bus.cpu.executedCC -= bankCC;
			// 3.render scanline(渲染扫描线)
			nextScanline = bus.ppu.renderLine();
			// 4.CPU cc of HBlank of need to execute(执行HBalnk对应的CPU时钟频率)
			bankCC = 28;
			if (bus.cpu.executedCC < bankCC) {
				if (bus.cpu.exec(int(bankCC - bus.cpu.executedCC)) == false) {
					thread.stop();
					return;
				}
			}
			// 5.reset CPU cc(重置CPU时钟频率)
			bus.cpu.executedCC -= bankCC;
			// All scanlines render are finish(所有扫描线渲染结束)
			if (nextScanline == 0) {
				vm_ft = openfl.Lib.getTimer() - vm_ft;
				runTime += vm_ft;
				thread.delay = fc_ft > vm_ft ? (fc_ft - vm_ft) : 0;
				// count FPS(计算FPS) - FC的CPU主频为1789772Hz/1秒
				if (bus.ppu.nFrameCount % fc_fps == 0) {
					runSecond += 1;
					var avgTime:TextField = new TextField();
					avgTime.text = Std.string(TV.stage.getChildByName('tfTime'));
					avgTime.text = Std.string(Std.int(runTime / runSecond));
				}
				break;
			}
		}
	}
}
