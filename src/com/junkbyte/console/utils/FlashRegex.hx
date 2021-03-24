package com.junkbyte.console.utils;
class FlashRegex {
    public static function search(text:String, regex:EReg):Int {
        var m = regex.match(text);

        return m ? regex.matchedPos().pos : -1;
    }
}
