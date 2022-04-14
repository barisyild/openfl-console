package com.junkbyte.console.utils;
import haxe.Exception;
class FlashRegex {
    public static function search(text:String, regex:EReg, lastIndex:Int = 0):Int {
        var m = match(text, regex, lastIndex);

        return m ? regex.matchedPos().pos : -1;
    }

    public static function match(text:String, regex:EReg, lastIndex:Int = 0):Bool
    {
        if(lastIndex < 1)
        {
            return regex.match(text);
        }else{
            return regex.matchSub(text, lastIndex);
        }

    }

    public static function replace(text:String, search:EReg, value:String):String
    {
        return search.replace(text, value);
    }

    public static function split(text:String, regex:EReg):Array<String>
    {
        return regex.split(text);
    }

    public static function exec(text:String, regex:EReg, lastIndex:Int = 0):RegexResult
    {
        var regexArray:RegexResult = new RegexResult();

        if(match(text, regex, lastIndex))
        {
            try
            {
                var minIndex:Int = 0;

                var i:Int = 0;
                while(true)
                {
                    minIndex = search(text, regex, i);
                    if(minIndex == -1)
                        break;
                    if(minIndex >= lastIndex)
                    {
                        regexArray.elements.push(regex.matched(i));
                    }

                    i++;
                }
            }
            catch(e)
            {

            }
        }

        #if openfl_console_debug
        trace("regexArraySize: " + regexArray.elements);
        #end

        regexArray.index = search(text, regex, lastIndex);



        if(regexArray.index == -1 || regexArray.index == lastIndex)
            return null;

        return regexArray;
    }
}

class RegexResult {
    public var elements:Array<String>;
    public var index:Int = 0;

    public function new()
    {
        elements = [];
    }
}
