package com.junkbyte.console.addons.memorytracker;


import com.junkbyte.console.addons.memorytracker.MemoryTrackerAddon;
import openfl.events.Event;
import openfl.text.TextFormatAlign;
import openfl.text.TextFormat;
import openfl.events.TextEvent;
import com.junkbyte.console.view.ConsolePanel;

class MemoryTrackerPanel extends ConsolePanel
{
    public static inline var NAME:String = "MemoryTrackerPanel";

    public function new(m:Console) {
        super(m);
        name = NAME;
        registerDragger(bg);
        minWidth = 200;
        minHeight = 200;

        txtField = makeTF("menuField");
        #if !flash
        var textFieldFormat:TextFormat = new TextFormat();
        textFieldFormat.align = TextFormatAlign.LEFT;
        txtField.defaultTextFormat = textFieldFormat;
        #end
        txtField.height = style.menuFontSize+4;
        //txtField.width = minWidth;
        txtField.y = -3;
        txtField.selectable = false;
        registerTFRoller(txtField, onMenuRollOver, linkHandler);
        addChild(txtField);

        //
        init(minWidth,minHeight,true);
        registerDragger(txtField); // so that we can still drag from textfield

        openfl.Lib.current.stage.addEventListener(Event.ENTER_FRAME, update);
    }

    private function linkHandler(e:TextEvent):Void {
        txtField.setSelection(0, 0);

        if(e.text == "close")
        {
            close();
        }

        txtField.setSelection(0, 0);
        e.stopPropagation();
    }

    #if (flash && haxe_ver < 4.3) @:setter(width) #else override #end public function set_width(value:Float):#if (!flash || haxe_ver >= 4.3) Float #else Void #end
    {
        super.width = value;
        txtField.width = value-6;
        #if (!flash || haxe_ver >= 4.3) return value; #end
    }

    #if (flash && haxe_ver < 4.3) @:setter(height) #else override #end public function set_height(value:Float):#if (!flash || haxe_ver >= 4.3) Float #else Void #end
    {
        super.height = value;
        txtField.height = value-6;
        #if (!flash || haxe_ver >= 4.3) return value; #end
    }

    private function onMenuRollOver(e:TextEvent):Void {
        console.panels.mainPanel.onMenuRollOver(e, this);
    }

    @:access(com.junkbyte.console.Cc)
    @:access(com.junkbyte.console.Console)
    @:access(com.junkbyte.console.core.MemoryMonitor)
    private function update(e:Event):Void
    {
        var map:Map<String, Int> = new Map<String, Int>();

        #if html5
        for(key in com.junkbyte.console.Cc._console._mm._objectsList.keys())
        #else
        for(key in com.junkbyte.console.Cc._console._mm._namesList.keys())
        #end
        {
            var lastIndex:Int = key.lastIndexOf("@");

            if(lastIndex != -1)
            {
                key = key.substr(0, lastIndex);
            }

            if(!map.exists(key))
                map.set(key, 1);
            else
                map.set(key, map.get(key) + 1);
        }

        var keys:Array<String> = [];

        for(key in map.keys())
        {
            var count:Int = map.get(key);

            if(count == 1)
            {
                keys.push(key);
            }else{
                keys.push('$key (${count}x)');
            }
        }

        keys.sort(cast MemoryTrackerAddon.sort);

        txtField.htmlText = getText(keys);
    }

    private inline function getText(keys:Array<String>):String
    {
        return '<high><menu><a href=\"event:close\">X</a></menu>\n<p3>${keys.join("\n")}</p3></high>';
    }

    public override function close():Void {

        openfl.Lib.current.stage.removeEventListener(Event.ENTER_FRAME, update);
        super.close();
    }
}