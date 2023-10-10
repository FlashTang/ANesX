package;

class Utils {

    public static function int(x:Any):Int {
        if(x is Bool){
            return x ? 1 : 0;
        }
        return Std.int(x);
    }

	public static function i2b(x:Any):Bool {
		return x != 0;
	}
}
