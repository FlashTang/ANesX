package;

import openfl.Vector;

class PPU extends Node {
	
	/** I/0 register
		--------------------------- */
	// ------------ 2000
	/* bit2 */
	private var nOffset32:Int = 0; // nt_addr offset value(递增地址数量标志)
	/* bit3 */
	private var nSPHeadAddr:Int = 0; // sprite head adderess - 0:0x0000,1:0x1000(图形的起始地址)
	/* bit4 */
	private var nBGHeadAddr:Int = 0; // background head address - 0:0x0000,1:0x1000(背景的起始地址)
	/* bit5 */
	private var b8x16:Bool; // big sprite flag - 0:8*8 sprite,1:8*16 sprite(大图形标志)
	/* bit7 */
	private var bNMI:Bool; // NMI flag - 0:on,1:off(NMI中断标志)

	public var nENC:Int = 0; // spend time that enter NMI interrupt 7cc(进入中断花费的时间)

	// ------------ 2001
	/* bit0 */
	private var bBWColor:Bool; // [no uesd]		- 黑白色标志 - 0:彩色;1:黑白色
	/* bit1 */
	private var bBgL1Col:Bool; // [no uesd]		- 显示背景左1列标志 - 0:不显示;1:显示
	/* bit2 */
	private var bSpL1Col:Bool; // [no uesd]		- 显示图形左1列标志 - 0:不显示;1:显示
	/* bit3 */
	private var bHideBG:Bool; // hide background	- 显示背景标志 - 0:不显示;1:显示
	/* bit4 */
	private var bHideSP:Bool; // hide sprite		- 显示图形标志 - 0:不显示;1:显示
	/* point[5-7] */
	private var nLightness:Int = 0; // [no uesd]
	// ------------ 2002
	/* bit4 */
	private var bIgnoreWrite:Bool; // [no uesd]		- 忽略写入VRAM标志
	/* bit5 */
	private var bMore8Sprite:Bool; // [no uesd]		- 扫描超过8个图形标志
	/* bit6 */
	private var bHit:Bool; // hit flag			- 碰撞检测标志
	/* bit7 */
	private var bVBlank:Bool; // VBlank Flag		- VBlank标志
	// ------------ 2003
	private var nReg2003:Int = 0;
	// ------------ 2005 & 2006共享标志
	private var bToggle:Bool;
	// ------------ 2006
	private var nReg2006:Int = 0; // Counter			- 计数器
	// ------------ 2007
	private var nReadBuffer:Int = 0; // VRAM read buffer,first read $2007 is invalid(under 0x3000)

	// VRAM读取缓冲区,第一次读2007是无效的(0x3000以下地址)

	/** register
		--------------------------- */
	private var nRegTemp:Int = 0; // temporary register			- 临时寄存器

	private var FV:Int = 0; // fine vertical				- 精确垂直偏移
	private var VT:Int = 0; // vertical tile index			- 垂直Tile索引
	private var HT:Int = 0; // horizontal tile index		- 水平Tile索引
	private var V:Int = 0; // vertical table index			- 垂直表索引
	private var H:Int = 0; // horizontal table index		- 水平表索引
	private var VH:Int = 0;

	private var FH:Int = 0; // fine horizontal				- 精确水平偏移

	// private var S:Int = 0;		// 背景图案表索引(nBGHeadAddr代替)
	// private var PAR:Int = 0;		// 图片地址寄存器
	// private var AR:Int = 0;		// 调色板选择器

	/** public variant
		--------------------------- */
	public var vtVRam:Array<Int>; // PPU's memory,somrwhere are mapping(PPU内存,某些地址为映射地址)

	public var vtSpRAM:Array<Int>; // Sprite RAM(256 bytes,64 sprites)
	public var vtIMG:Vector<UInt>; // bitmap of output image(输出的位图图像)
	public var nFrameCount:Int = 0;

	/** private variant
		--------------------------- */
	private var vtBG:Array<Int>; // bitmap of background 			- 背景矩阵点

	private var vtSM_0:Array<Int>; // Matrix Mapping 0					- 方块索引转换属性表位的映射表0
	private var vtSM_1:Array<Int>; // Matrix Mapping 1					- 方块索引转换属性表位的映射表1
	private var nScanline:Int = 0; // Current Scan   Line				- 当前扫描线
	private var nRenderLine:Int = 0; // Cureent Render Line				- 当前渲染线
	private var bForcedVBlank:Bool; // Forced VBlank					- 强制VBlank模式
	private var vtSprite0:Array<Int>; // Sprite 0 graphics,used in hit	- Sprite 0的图形,用在碰撞上

	/** 局部变量(提到全局变量以提速)
		--------------------------- */
	// coordinate(坐标)
	private var topX:Int = 0;

	private var topY:Int = 0;
	private var sp_H:Int = 0;
	private var sp0_Y:Int = 0;
	private var sp0_X:Int = 0;
	// name table(命名表)
	private var nt_addr:Int = 0;
	// attribute table(属性表)
	private var groupRow:Int = 0;
	private var squareRow:Int = 0;
	private var sq_index:Int = 0;
	private var at_addr:Int = 0;
	private var at_data:Int = 0;
	// pattern table(图案表)
	private var pt_addr:Int = 0;
	private var pt0_data:Int = 0;
	private var pt1_data:Int = 0;
	// point attribute(绘点属性)
	private var point:Int = 0;
	private var point_row:Int = 0;
	private var l_bit_pal:Int = 0; // lower image palette address
	private var u_bit_pal:Int = 0; // upper image palette address
	private var pal_index:Int = 0; // image palette address
	private var pal_data:UInt; // image palette value
	// Sprite
	private var pt0_row:Int = 0;
	private var pt1_row:Int = 0;
	private var pt0_vt:Array<Int>;
	private var pt1_vt:Array<Int>;

	private var pt_index:Int = 0;
	private var sp_at:Int = 0;
	private var bFG:Bool;
	private var bFlipH:Bool;
	private var bFlipV:Bool;
	private var bg_point:Int = 0;

	private var fitX:Int = 0;
	private var fitY:Int = 0;

	private var bitX:Int = 0;
	private var bitY:Int = 0;

	/** construction
		--------------------------- */
	public function new() {
		//----------------------------------------------------
		nOffset32 = 0;
		nSPHeadAddr = 0;
		nBGHeadAddr = 0;
		b8x16 = false;
		bNMI = false;
		nENC = 0;
		bBWColor = false;
		bBgL1Col = false;
		bSpL1Col = false;
		bHideBG = true;
		bHideSP = true;
		nLightness = 0;
		bIgnoreWrite = false;
		bMore8Sprite = false;
		bHit = false;
		bVBlank = false;
		nReg2003 = 0;
		bToggle = false;
		nReg2006 = 0;
		nReadBuffer = 0;
		//----------------------------------------------------
		nRegTemp = 0;
		FV = 0;
		VT = 0;
		HT = 0;
		FH = 0;
		V = 0;
		H = 0;
		VH = 0;
		//----------------------------------------------------
		vtVRam = [for (c in 0...0x10000) 0]; // new Array<Int>();//(0x10000);
		vtSpRAM = [for (c in 0...0x100) 0]; // new Array<Int>();//(0x100);
		vtIMG = new Vector(256 * 240); // (256 * 240);
		for (i in 0...256 * 240) {
			vtIMG[i] = 0;
		}
		//----------------------------------------------------
		vtBG = [for (c in 0...(256 * 240)) 0]; // new Array<Int>();//(256 * 240);
		vtSM_0 = new Array<Int>();
		vtSM_0 = [
			0x03, 0x03, 0x0C, 0x0C, 0x03, 0x03, 0x0C, 0x0C, 0x30, 0x30, 0xC0, 0xC0, 0x30, 0x30, 0xC0, 0xC0
		];
		vtSM_1 = new Array<Int>();
		vtSM_1 = [0, 0, 2, 2, 0, 0, 2, 2, 4, 4, 6, 6, 4, 4, 6, 6];
		nScanline = 0;
		nRenderLine = 0;
		bForcedVBlank = false;
		vtSprite0 = [for (c in 0...0x80) 0]; // new Array<Int>();//(0x80);
		//----------------------------------------------------
		topX = 0;
		topY = 0;
		sp_H = 0;
		sp0_Y = 0;
		sp0_X = 0;
		nt_addr = 0;
		groupRow = 0;
		squareRow = 0;
		sq_index = 0;
		at_addr = 0;
		at_data = 0;
		pt_addr = 0;
		pt0_data = 0;
		pt1_data = 0;
		point = 0;
		point_row = 0;
		l_bit_pal = 0;
		u_bit_pal = 0;
		pal_index = 0;
		pal_data = 0;
		pt0_row = 0;
		pt1_row = 0;
		pt0_vt = new Array<Int>(); // (16);
		pt1_vt = new Array<Int>(); // (16);
		pt_index = 0;
		sp_at = 0;
		bFG = false;
		bFlipH = false;
		bFlipV = false;
		bg_point = 0;
		fitX = 0;
		fitY = 0;
		bitX = 0;
		bitY = 0;
	}

	// render line(return next scanline number)
	// 渲染线(返回下条扫描线行号)
	public function renderLine():Int {
		if (nScanline == 0) { // initial render line(渲染初始化线)
			// 1.set flag(设置标志)
			bVBlank = false;
			bHit = false;
			bMore8Sprite = false;
			// 2.update counter(更新计数器)
			if (!bHideBG || !bHideSP) {
				nReg2006 = nRegTemp;
			}
			renderSprite0();
		} else if (nScanline >= 1 && nScanline <= 240) { // render line(渲染线)
			// both of bHideBG and bHideSP are true,then enter VBlank mode(两者都隐藏的话,进入'被迫VBlank'模式)
			if (bHideBG && bHideSP) {
				renderBGColor();
				bForcedVBlank = true;
			} else if (bHideBG) {
				renderBGColor();
			} else {
				if (bForcedVBlank) {
					nReg2006 = nRegTemp;
					bForcedVBlank = false;
				}
				renderBG();
			}
		} else if (nScanline == 241) { // end render line(渲染结束线)
			if (!bHideSP) {
				renderSprite();
			}
			// 1.set flag(设置标志)
			bVBlank = true;
			// 2.create a interrupt(产生中断)
			if (bNMI) {
				nENC = 7; // enter NMI must spend 7 cc
			}
		} else if (nScanline == 261) { // end frame line(帧结束线)
			nScanline = -1;
			nFrameCount += 1;
		}
		// increase line(递增扫描线)
		nScanline += 1;
		return nScanline;
	}

	private function renderBGColor():Void {
		nRenderLine = nScanline - 1;
		point_row = nRenderLine * 256;
		// trace(Utils.int(vtVRam[0x3F00]));
		var bgColor:Int = bus.curPAL[Utils.int(vtVRam[0x3F00])];

		for (i in 0...256) {
			point = point_row + i;

			vtIMG[point] = bgColor;
			vtBG[point] = 0;
		}
	}

	private function renderBG():Void {
		nRenderLine = nScanline - 1;
		// parse counter(分解计数器)
		FV = (nReg2006 & 0x7000) >> 12;
		V = (nReg2006 & 0x0800) >> 11;
		H = (nReg2006 & 0x0400) >> 10;
		VT = (nReg2006 & 0x03E0) >> 5;
		HT = nReg2006 & 0x001F;
		// update counter(更新计数器)
		H = (nRegTemp & 0x0400) >> 10;
		HT = nRegTemp & 0x001F;
		// initialize variable(初始化变量)
		groupRow = (VT >> 2) * 8; // Tile所在的4*4 组
		squareRow = (VT & 0x03) * 4; // Tile所在的2*2方块
		point_row = nRenderLine * 256; // 位行
		var fineX:Int = FH;
		var XRenderPoint:Int = 0; // X渲染点
		// draw tile(渲染tile)

		// for (times in 0...33) {
		var times:Int = 0;
		while (times < 33) {
			VH = Utils.int((V << 11) + (H << 10)) + 0x2000;
			// 1.get name table(获取命名表)
			nt_addr = Utils.int(VH + HT) + (VT << 5);
			// 2.get attribute table(获取属性表)
			at_addr = Utils.int(VH + 0x3C0) + Utils.int(groupRow + (HT >> 2));
			// 3.get pattern table(获取命名表值=图案表)
			pt_addr = (vtVRam[nt_addr] << 4) + Utils.int(nBGHeadAddr + FV);
			// 4.get tile index(获取Tile对应的方块索引)
			sq_index = squareRow + (HT & 0x03);
			// 5.get upper 2 bits of palette(获取高2位调色板值)
			u_bit_pal = (vtVRam[at_addr] & vtSM_0[sq_index]) >> vtSM_1[sq_index];
			// 6.get character matrix(获取字模矩阵)
			pt0_data = vtVRam[pt_addr];
			pt1_data = vtVRam[Utils.int(pt_addr + 8)];
			// 7.get draw point position(生成渲染起点)
			point = point_row + XRenderPoint;
			// 8.get render X(渲染X轴像素)
			// for(;fineX < 8;fineX += 1){
			while (fineX < 8) {
				// 1.get lower 2 bits of palette(获取低2位调色板值/也是背景矩阵/00为背景色板)
				l_bit_pal = ((pt1_data & 0x80 >> fineX) << 1 | (pt0_data & 0x80 >> fineX)) >> (7 - fineX);
				// 2.get color of palette(获取调色板颜色)
				pal_data = vtVRam[Utils.int(0x3F00 + (u_bit_pal << 2 | l_bit_pal))];
				// 3.save point of infomation(保存点信息)
				vtIMG[point] = bus.curPAL[pal_data];
				vtBG[point] = l_bit_pal; // used in hit(保存背景矩阵以用作与Sprite做碰撞测试)
				// 4.move to next render poUtils.int(偏移下个渲染点)
				point += 1;
				XRenderPoint += 1;
				if (XRenderPoint >= 256) { // 256个点
					times = 1000;
					break;
				}
				fineX += 1;
			}
			// reset fine X
			fineX = 0;
			// update HT、H
			HT += 1;
			HT &= 31;
			if (HT == 0) {
				H ^= 1;
			}
			times++;
		}
		// update FV、VT、V
		FV += 1;
		FV &= 7;
		if (FV == 0) {
			VT += 1;
			// Tile Y只有30行，索引0开始到29
			if (VT == 30) {
				VT = 0;
				V ^= 1;
			}
			// 从30开始的值只递增不翻转V
			else if (VT == 32) {
				VT = 0;
			}
		}
		// update counter(更新计数器)
		nReg2006 = (FV << 12) + (V << 11) + (H << 10) + (VT << 5) + HT;
		// hit test(碰撞测试)
		if (!bHit && nRenderLine < Utils.int(sp0_Y + sp_H) && nRenderLine >= sp0_Y) {
			// for(XRenderPoint = 0;XRenderPoint < 256;XRenderPoint += 1){
			XRenderPoint = 0;
			while (XRenderPoint < 256) {
				if (XRenderPoint >= Utils.int(sp0_X + 8)) {
					break;
				}
				if (XRenderPoint >= sp0_X) {
					if (vtSprite0[Utils.int(Utils.int(nRenderLine - sp0_Y << 3) + Utils.int(XRenderPoint - sp0_X))] != 0
						&& vtIMG[Utils.int(point_row + XRenderPoint)] != 0) {
						bHit = true;
						break;
					}
				}
				XRenderPoint += 1;
			}
		}
	}

	// render Sprite 0 for hit(渲染Sprite 0为了碰撞)
	private function renderSprite0():Void {
		// 1.get infomation(获取信息)
		sp0_Y = vtSpRAM[0];
		pt_index = vtSpRAM[1];
		sp_at = vtSpRAM[2];
		sp0_X = vtSpRAM[3];
		sp_H = 1 << 3 + Utils.int(b8x16);
		// 2.parse attribute(分析属性)
		u_bit_pal = sp_at & 0x03;
		bFG = (sp_at & 0x20) == 0; // foreground
		bFlipH = Utils.i2b(sp_at & 0x40);
		bFlipV = Utils.i2b(sp_at & 0x80);
		if (b8x16) {
			if ((pt_index & 1) == 0) { // even number(偶数)
				// 1.get pattern table(获取图案表)
				pt_addr = pt_index << 4;
				// 2.get matrix(获取矩阵)
				pt0_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x00)];
				pt1_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x08)];
				pt0_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x01)];
				pt1_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x09)];
				pt0_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x02)];
				pt1_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x0A)];
				pt0_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x03)];
				pt1_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x0B)];
				pt0_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x04)];
				pt1_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x0C)];
				pt0_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x05)];
				pt1_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x0D)];
				pt0_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x06)];
				pt1_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x0E)];
				pt0_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x07)];
				pt1_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x0F)];
				pt0_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x10)];
				pt1_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x18)];
				pt0_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x11)];
				pt1_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x19)];
				pt0_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x12)];
				pt1_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x1A)];
				pt0_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x13)];
				pt1_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x1B)];
				pt0_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x14)];
				pt1_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x1C)];
				pt0_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x15)];
				pt1_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x1D)];
				pt0_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x16)];
				pt1_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x1E)];
				pt0_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x17)];
				pt1_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x1F)];
			} else { // odd number(奇数)
				// 1.get pattern table(获取图案表)
				pt_addr = 0x1000 + ((pt_index & 0xFE) << 4);
				// 2.get matrix(获取矩阵)
				pt0_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x00)];
				pt1_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x08)];
				pt0_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x01)];
				pt1_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x09)];
				pt0_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x02)];
				pt1_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x0A)];
				pt0_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x03)];
				pt1_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x0B)];
				pt0_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x04)];
				pt1_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x0C)];
				pt0_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x05)];
				pt1_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x0D)];
				pt0_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x06)];
				pt1_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x0E)];
				pt0_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x07)];
				pt1_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x0F)];
				pt0_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x10)];
				pt1_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x18)];
				pt0_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x11)];
				pt1_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x19)];
				pt0_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x12)];
				pt1_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x1A)];
				pt0_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x13)];
				pt1_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x1B)];
				pt0_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x14)];
				pt1_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x1C)];
				pt0_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x15)];
				pt1_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x1D)];
				pt0_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x16)];
				pt1_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x1E)];
				pt0_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x17)];
				pt1_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x1F)];
			}
		} else {
			// 1.get pattern table(获取图案表)
			pt_addr = nSPHeadAddr + (pt_index << 4);
			// 2.get matrix(获取矩阵)
			pt0_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x00)];
			pt1_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x08)];
			pt0_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x01)];
			pt1_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x09)];
			pt0_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x02)];
			pt1_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x0A)];
			pt0_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x03)];
			pt1_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x0B)];
			pt0_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x04)];
			pt1_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x0C)];
			pt0_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x05)];
			pt1_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x0D)];
			pt0_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x06)];
			pt1_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x0E)];
			pt0_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x07)];
			pt1_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x0F)];
		}
		// 3.render(渲染)
		for (spY in 0...sp_H) { // offset Y				- Y偏移点
			bFlipV ? fitY = Utils.int(sp_H - 1) - spY : fitY = spY; // flip vertical		- 垂直翻转
			pt0_row = pt0_vt[fitY]; // 对应字模0
			pt1_row = pt1_vt[fitY]; // 对应字模1
			for (spX in 0...8) { // offset X				- X偏移点
				bFlipH ? fitX = 7 - spX : fitX = spX; // flip horizintal		- 水平翻转
				point = spY * 8 + spX; // current render point - 当前渲染点
				l_bit_pal = ((pt1_row & 0x80 >> fitX) << 1 | (pt0_row & 0x80 >> fitX)) >> (7 - fitX);
				vtSprite0[point] = l_bit_pal;
			}
		}
	}

	private function renderSprite():Void {
		// 从Sprite 63开始绘起
		// for(var index:Int = 252;index >= 0;index -= 4){
		var index:Int = 252;
		while (index >= 0) {
			// 1.get infomation(获取信息)
			topY = vtSpRAM[index];
			pt_index = vtSpRAM[Utils.int(index + 1)];
			sp_at = vtSpRAM[Utils.int(index + 2)];
			topX = vtSpRAM[Utils.int(index + 3)];
			sp_H = 1 << 3 + Utils.int(b8x16);
			// 2.parse attribute(分析属性)
			u_bit_pal = sp_at & 0x03;
			bFG = (sp_at & 0x20) == 0; // foreground
			bFlipH = Utils.i2b(sp_at & 0x40);
			bFlipV = Utils.i2b(sp_at & 0x80);
			if (b8x16) {
				if ((pt_index & 1) == 0) { // even number(偶数)
					// 1.get pattern table(获取图案表)
					pt_addr = pt_index << 4;
					// 2.get matrix(获取矩阵)
					pt0_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x00)];
					pt1_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x08)];
					pt0_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x01)];
					pt1_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x09)];
					pt0_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x02)];
					pt1_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x0A)];
					pt0_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x03)];
					pt1_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x0B)];
					pt0_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x04)];
					pt1_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x0C)];
					pt0_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x05)];
					pt1_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x0D)];
					pt0_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x06)];
					pt1_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x0E)];
					pt0_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x07)];
					pt1_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x0F)];
					pt0_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x10)];
					pt1_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x18)];
					pt0_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x11)];
					pt1_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x19)];
					pt0_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x12)];
					pt1_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x1A)];
					pt0_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x13)];
					pt1_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x1B)];
					pt0_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x14)];
					pt1_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x1C)];
					pt0_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x15)];
					pt1_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x1D)];
					pt0_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x16)];
					pt1_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x1E)];
					pt0_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x17)];
					pt1_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x1F)];
				} else { // odd number(奇数)
					// 1.get pattern table(获取图案表)
					pt_addr = 0x1000 + ((pt_index & 0xFE) << 4);
					// 2.get matrix(获取矩阵)
					pt0_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x00)];
					pt1_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x08)];
					pt0_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x01)];
					pt1_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x09)];
					pt0_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x02)];
					pt1_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x0A)];
					pt0_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x03)];
					pt1_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x0B)];
					pt0_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x04)];
					pt1_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x0C)];
					pt0_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x05)];
					pt1_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x0D)];
					pt0_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x06)];
					pt1_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x0E)];
					pt0_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x07)];
					pt1_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x0F)];
					pt0_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x10)];
					pt1_vt[0x8] = vtVRam[Utils.int(pt_addr + 0x18)];
					pt0_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x11)];
					pt1_vt[0x9] = vtVRam[Utils.int(pt_addr + 0x19)];
					pt0_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x12)];
					pt1_vt[0xA] = vtVRam[Utils.int(pt_addr + 0x1A)];
					pt0_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x13)];
					pt1_vt[0xB] = vtVRam[Utils.int(pt_addr + 0x1B)];
					pt0_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x14)];
					pt1_vt[0xC] = vtVRam[Utils.int(pt_addr + 0x1C)];
					pt0_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x15)];
					pt1_vt[0xD] = vtVRam[Utils.int(pt_addr + 0x1D)];
					pt0_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x16)];
					pt1_vt[0xE] = vtVRam[Utils.int(pt_addr + 0x1E)];
					pt0_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x17)];
					pt1_vt[0xF] = vtVRam[Utils.int(pt_addr + 0x1F)];
				}
			} else {
				// 1.get pattern table(获取图案表)
				pt_addr = nSPHeadAddr + (pt_index << 4);
				// 2.get matrix(获取矩阵)
				pt0_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x00)];
				pt1_vt[0x0] = vtVRam[Utils.int(pt_addr + 0x08)];
				pt0_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x01)];
				pt1_vt[0x1] = vtVRam[Utils.int(pt_addr + 0x09)];
				pt0_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x02)];
				pt1_vt[0x2] = vtVRam[Utils.int(pt_addr + 0x0A)];
				pt0_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x03)];
				pt1_vt[0x3] = vtVRam[Utils.int(pt_addr + 0x0B)];
				pt0_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x04)];
				pt1_vt[0x4] = vtVRam[Utils.int(pt_addr + 0x0C)];
				pt0_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x05)];
				pt1_vt[0x5] = vtVRam[Utils.int(pt_addr + 0x0D)];
				pt0_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x06)];
				pt1_vt[0x6] = vtVRam[Utils.int(pt_addr + 0x0E)];
				pt0_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x07)];
				pt1_vt[0x7] = vtVRam[Utils.int(pt_addr + 0x0F)];
			}
			// 3.render(渲染)
			for (spY in 0...sp_H) { // offset Y				- Y偏移点
				bFlipV ? fitY = Utils.int(sp_H - 1) - spY : fitY = spY; // flip vertical		- 垂直翻转
				pt0_row = pt0_vt[fitY]; // 对应字模0
				pt1_row = pt1_vt[fitY]; // 对应字模1
				for (spX in 0...8) { // offset X				- X偏移点
					bFlipH ? fitX = 7 - spX : fitX = spX; // flip horizintal		- 水平翻转
					bitY = topY + spY;
					bitX = topX + spX;
					if (bitX >= 256 || bitY >= 240) {
						continue;
					}
					l_bit_pal = ((pt1_row & 0x80 >> fitX) << 1 | (pt0_row & 0x80 >> fitX)) >> (7 - fitX);
					// dont render transparent poUtils.int(不渲染透明点)
					if (l_bit_pal == 0) {
						continue;
					}
					point = Utils.int(bitY * 256) + bitX; // current render point - 当前渲染点
					bg_point = vtBG[point]; // 对应的背景点
					// if it is in foreground and isnt transparent(如果在前景或背景为透明的话)
					if (bFG || bg_point == 0) {
						pal_index = u_bit_pal << 2 | l_bit_pal; // make color index		- 生成颜色索引
						pal_data = vtVRam[Utils.int(0x3F10 + pal_index)];
						vtIMG[point] = bus.curPAL[pal_data]; // save ponit(保存点)
					}
				}
			}
			index -= 4;
		}
	}

	// read data
	public function r2(address:Int):Int {
		// inline:return PPU_r2(address);#
		var value:Int = 0;
		if (address == 0x2002) { // PPU status	- PPU状态
			value = Utils.int(bVBlank) << 7 | Utils.int(bHit) << 6 | Utils.int(bMore8Sprite) << 5 | Utils.int(bIgnoreWrite) << 4;
			bVBlank = false;
			bToggle = false;
		} else if (address == 0x2007) { // VRAM data	- VRAM 数据
			if (nReg2006 >= 0x3F20) {
				trace('PPU read 0x3F20');
			} else if (nReg2006 >= 0x3F00) {
				value = vtVRam[nReg2006];
			} else if (nReg2006 >= 0x3000) {
				trace('PPU read 0x3000');
			} else {
				value = nReadBuffer;
				nReadBuffer = vtVRam[nReg2006];
			}
			// move to next position(移动下个位置)
			nReg2006 += 1 + Utils.int(nOffset32 * 31);
			nReg2006 &= 0xFFFF;
		} else if (address == 0x2004) {
			value = vtVRam[nReg2003];
			nReg2003 += 1;
			nReg2003 &= 0xFF;
		} else {
			trace('unknown PPU read', address);
		}
		return value;
		// inline#
	}

	// write data
	public function w2(address:Int, value:Int):Void {
		// inline:PPU_w2(address,value);#
		if (address == 0x2007) { // VRAM data	- VRAM 数据
			if (nReg2006 >= 0x3F20) {
				trace('PPU write 0x3F20');
			} else if (nReg2006 >= 0x3F00) {
				if (nReg2006 % 0x10 == 0) { // 0x3F00 or 0x3F10
					var t:Int = (value & 0x3F);
					vtVRam[0x3F00] = t;
					vtVRam[0x3F04] = t;
					vtVRam[0x3F08] = t;
					vtVRam[0x3F0C] = t;
					vtVRam[0x3F10] = t;
					vtVRam[0x3F14] = t;
					vtVRam[0x3F18] = t;
					vtVRam[0x3F1C] = t;
				} else if (nReg2006 % 0x04 != 0) { // invalid write in 0x3F04|0x3F08|0x3F0C|0x3F14|0x3F18|0x3F1C(写入无效)
					vtVRam[nReg2006] = (value & 0x3F);
				}
			} else if (nReg2006 >= 0x3000) {
				trace('PPU write 0x3000', nScanline);
			} else if (nReg2006 >= 0x2000) {
				if (bus.bMirror_S) {
					vtVRam[Utils.int(0x2000 + (nReg2006 & 0x3FF))] = value;
					vtVRam[Utils.int(0x2400 + (nReg2006 & 0x3FF))] = value;
					vtVRam[Utils.int(0x2800 + (nReg2006 & 0x3FF))] = value;
					vtVRam[Utils.int(0x2C00 + (nReg2006 & 0x3FF))] = value;
				} else if (bus.bMirror_F) {
					vtVRam[nReg2006] = value;
				} else if (nReg2006 >= 0x2C00) {
					vtVRam[nReg2006] = value;
					if (bus.bMirror_V) {
						vtVRam[Utils.int(nReg2006 - 0x0800)] = value;
					} else {
						vtVRam[Utils.int(nReg2006 - 0x0400)] = value;
					}
				} else if (nReg2006 >= 0x2800) {
					vtVRam[nReg2006] = value;
					if (bus.bMirror_V) {
						vtVRam[Utils.int(nReg2006 - 0x0800)] = value;
					} else {
						vtVRam[Utils.int(nReg2006 + 0x0400)] = value;
					}
				} else if (nReg2006 >= 0x2400) {
					vtVRam[nReg2006] = value;
					if (bus.bMirror_V) {
						vtVRam[Utils.int(nReg2006 + 0x0800)] = value;
					} else {
						vtVRam[Utils.int(nReg2006 - 0x0400)] = value;
					}
				} else if (nReg2006 >= 0x2000) {
					vtVRam[nReg2006] = value;
					if (bus.bMirror_V) {
						vtVRam[Utils.int(nReg2006 + 0x0800)] = value;
					} else {
						vtVRam[Utils.int(nReg2006 + 0x0400)] = value;
					}
				}
			} else {
				vtVRam[nReg2006] = value;
			}
			// move to next position(移动下个位置)
			nReg2006 += 1 + Utils.int(nOffset32 * 31);
			nReg2006 &= 0xFFFF;
		} else if (address == 0x2006) { // VRAM address				- VRAM地址
			if (bToggle) { // lower,second time		- 低位,第二次
				nRegTemp &= 0x7F00; // cleare data				- 清数据
				nRegTemp |= value;
				nReg2006 = nRegTemp;
			} else { // upper,first time			- 高位,第一次
				nRegTemp &= 0x00FF; // cleare data				- 清数据
				nRegTemp |= (value & 0x3F) << 8;
			}
			bToggle = !bToggle; // toggle switch			- 切换开关
		} else if (address == 0x2005) { // VRAM address				- VRAM地址
			if (bToggle) { // Y,second time			- Y值,第二次
				nRegTemp &= 0xC1F; // cleare data				- 清数据
				nRegTemp |= (value & 0xF8) << 2; // Tile Y
				nRegTemp |= (value & 0x7) << 12; // Fine Y
			} else { // X,first time				- X值,第一次
				nRegTemp &= 0xFFE0; // cleare data				- 清数据
				nRegTemp |= value >> 3; // Tile X
				FH = value & 0x7; // Fine X
			}
			bToggle = !bToggle; // toggle switch			- 切换开关
		} else if (address == 0x2004) { // Spirte RAM address
			vtSpRAM[nReg2003] = value;
			nReg2003 += 1;
			nReg2003 &= 0xFF;
		} else if (address == 0x2003) { // Spirte RAM data
			nReg2003 = value;
		} else if (address == 0x2001) { // control register 2		- 控制寄存器2
			bBWColor = Utils.i2b(value & 0x01);
			bBgL1Col = Utils.i2b(value & 0x02);
			bSpL1Col = Utils.i2b(value & 0x04);
			bHideBG = (value & 0x08) == 0;
			bHideSP = (value & 0x10) == 0;
			nLightness = (value & 0xE0) >> 5;
			// trace(bSpL1Col,bBgL1Col);
		} else if (address == 0x2000) { // control register 1		- 控制寄存器2
			nRegTemp &= 0xF3FF; // cleare data				- 清数据
			nRegTemp |= (value & 0x03) << 10;
			nOffset32 = (value & 0x4) >> 2;
			nSPHeadAddr = (value & 0x08) == 0 ? 0 : 0x1000;
			nBGHeadAddr = (value & 0x10) == 0 ? 0 : 0x1000;
			b8x16 = Utils.i2b(value & 0x20);
			bNMI = Utils.i2b(value & 0x80);
		} else {
			trace('unknown PPU write', address);
		}
		// inline#
	}
}
