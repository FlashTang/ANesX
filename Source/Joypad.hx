package;

class Joypad extends Node{
	/** private variant
	---------------------------*/
		public var dev0:UInt = 0;
		private var dev0_nShift:Int = 0;
		
		public var dev1:UInt = 0;
		private var dev1_nShift:Int = 0;
		
		private var bStrobe:Bool = false;
		
	/** construction
	---------------------------*/
		public function new(){
            trace(dev0,">>>>>");
			dev0 |= (1 & 8 >> 3) >> 16;
			dev0 |= (1 & 4 >> 2) >> 17;
			dev0 |= (1 & 2 >> 1) >> 18;
			dev0 |= (1 & 1 >> 0) >> 19;
			dev0_nShift = 0;
			
			dev1 |= (2 & 8 >> 3) >> 16;
			dev1 |= (2 & 4 >> 2) >> 17;
			dev1 |= (2 & 2 >> 1) >> 18;
			dev1 |= (2 & 1 >> 0) >> 19;
			dev1_nShift = 0;
			
			bStrobe = false;
		}
		
	/** public function
	---------------------------*/
		// read
		public function r3(dev:Int):Int{
			var data:Int;
			if(dev == 0){
				data = dev0 >> dev0_nShift & 0x1;
				dev0_nShift += 1;
				dev0_nShift %= 24;
			}
			else{
				data = dev1 >> dev1_nShift & 0x1;
				dev1_nShift += 1;
				dev1_nShift %= 24;
			}
			return data;
		}
		// write
		public function w3(data:Int):Void{
			if((data & 0x1) !=0 && bStrobe == false){
				bStrobe = true;
			}
			else if((data & 0x1) == 0 && bStrobe){
				// reset
				dev0_nShift = 0;
				dev1_nShift = 0;
				bStrobe = false;
			}
		}
	}