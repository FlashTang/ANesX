package;

import openfl.net.FileFilter;
import openfl.events.KeyboardEvent;
import haxe.Timer;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.display.Bitmap;
import openfl.net.FileReference;
import openfl.display.Sprite;
class Main extends Sprite {
	// global variable
	var timeId:UInt;
	var file:FileReference;

	// keyboard mapping
	var jp1_r:Int = 0;
	var jp1_l:Int = 0;
	var jp1_u:Int = 0;
	var jp1_d:Int = 0;
	var jp1_se:Int = 0;
	var jp1_st:Int = 0;
	var jp1_b:Int = 0;
	var jp1_a:Int = 0;
	var vm:VM;
	public function new() {
		super();
		// create TV
		var TV:Bitmap = new Bitmap();
		TV.bitmapData = new BitmapData(256, 240, false, 0);
		this.stage.addChild(TV);
		stage.color = 0x1D3E04;
		// create speed of VM execution
		var tf:TextField = new TextField();
		tf.textColor = 0xFFFFFF;
		tf.text = '---';
		tf.x = 300;
		tf.y = 10;
		tf.name = 'tfTime';
		this.stage.addChild(tf);

		// adjust system
		this.stage.frameRate = 60;

		// add Nes Virtual Machine
		vm = new VM();
		vm.connectTV(TV);

		// listen event
		var bnOpen = new Sprite();
		var text:TextField = new TextField();
		text.textColor = 0xffffff;
		text.width = 120;
		text.text = "Open 打开 Nes Rom";
		text.mouseEnabled = false;
		bnOpen.addChild(text);
		bnOpen.graphics.beginFill(0x000000);
		bnOpen.graphics.drawRect(0,0,120,22);
		bnOpen.x = 2;
		bnOpen.y = 242;
		addChild(bnOpen);
		bnOpen.addEventListener(MouseEvent.CLICK, OnClick_Open);
		//bnStop.addEventListener(MouseEvent.CLICK, OnClick_Stop);
		//bnPlay.addEventListener(MouseEvent.CLICK, OnClick_Play);
		stage.addEventListener(KeyboardEvent.KEY_DOWN,OnKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP,OnKeyUp);
	}
	 

	function OnClick_Stop(e:MouseEvent):Void {
		vm.suspend();
	}
	function OnClick_Play(e:MouseEvent):Void {
		vm.resume();
	}
	function OnClick_Open(e:MouseEvent):Void {
		vm.suspend();
		var nesFilter:FileFilter = new FileFilter("Nes/FC Rom", "*.nes");
		file = new FileReference();
		file.addEventListener(Event.CANCEL,OnCancel_Open,false,0,true);
		file.addEventListener(Event.SELECT, OnSelect_Open,false,0,true);
		file.addEventListener(Event.COMPLETE,OnComplete_Open,false,0,true);
		file.browse([nesFilter]);
	}
	function OnSelect_Open(e:Event):Void {
		file.load();
	}
	var timer:Timer;
	function OnComplete_Open(e:Event):Void {
	
		if(timer != null) timer.stop();
		timer = new Timer(100);
		timer.run = function () {
			touchJoypad();
		}
		vm.reset();
		vm.insertCartridge(e.target.data);

	}
	function OnCancel_Open(e:Any){
		vm.resume();
	}
	function OnKeyDown(e:KeyboardEvent){
		if(e.keyCode == 68){
			jp1_r = 1;
		}
		else if(e.keyCode == 65){
			jp1_l = 1;
		}
		else if(e.keyCode == 87){
			jp1_u = 1;
		}
		else if(e.keyCode == 83){
			jp1_d = 1;
		}
		else if(e.keyCode == 70){
			jp1_se = 1;
		}
		else if(e.keyCode == 72){
			jp1_st = 1;
		}
		else if(e.keyCode == 74){
			jp1_b = 1;
		}
		else if(e.keyCode == 75){
			jp1_a = 1;
		}
	}
	function OnKeyUp(e:KeyboardEvent){
		if(e.keyCode == 68){
			jp1_r = 0;
		}
		else if(e.keyCode == 65){
			jp1_l = 0;
		}
		else if(e.keyCode == 87){
			jp1_u = 0;
		}
		else if(e.keyCode == 83){
			jp1_d = 0;
		}
		else if(e.keyCode == 70){
			jp1_se = 0;
		}
		else if(e.keyCode == 72){
			jp1_st = 0;
		}
		else if(e.keyCode == 74){
			jp1_b = 0;
		}
		else if(e.keyCode == 75){
			jp1_a = 0;
		}
	}
	function touchJoypad(){
		var pulse:UInt = jp1_a | jp1_b << 1 | jp1_se << 2 | jp1_st << 3 | jp1_u << 4 | jp1_d << 5 | jp1_l << 6 | jp1_r << 7;
		vm.touchJoypad(pulse,0);
	}
}
