/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
* 
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
* 
*/
package com.junkbyte.console.view;

import com.junkbyte.console.Console;
import com.junkbyte.console.vos.GraphGroup;
import com.junkbyte.console.vos.GraphInterest;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.events.TextEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * @private
 */
class GraphingPanel extends ConsolePanel {
    //
    public static inline var FPS:String = "fpsPanel";
    public static inline var MEM:String = "memoryPanel";
    //
    private var _group:GraphGroup;
    private var _interest:GraphInterest;
    private var _infoMap:Map<String, Array<Dynamic>> = new Map();
    private var _menuString:String;
    //
    private var _type:String;
    //
    private var _needRedraw:Bool;
    //
    private var underlay:Shape;
    private var graph:Shape;
    private var lowTxt:TextField;
    private var highTxt:TextField;
    //
    public var startOffset:Int = 5;
    //

    public function new(m:Console, W:Float, H:Float, type:String = null) {
        super(m);
        _type = type;
        registerDragger(bg);
        minWidth = 32;
        minHeight = 26;
        //
        var textFormat:TextFormat = new TextFormat();
        var lowStyle:Dynamic = style.styleSheet.getStyle("low");
        textFormat.font = lowStyle.fontFamily;
        textFormat.size = lowStyle.fontSize;
        textFormat.color = style.lowColor;

        lowTxt = new TextField();
        lowTxt.name = "lowestField";
        lowTxt.defaultTextFormat = textFormat;
        lowTxt.mouseEnabled = false;
        lowTxt.height = style.menuFontSize+2;
        addChild(lowTxt);

        highTxt = new TextField();
        highTxt.name = "highestField";
        highTxt.defaultTextFormat = textFormat;
        highTxt.mouseEnabled = false;
        highTxt.height = style.menuFontSize+2;
        highTxt.y = style.menuFontSize-4;
        addChild(highTxt);
        //
        txtField = makeTF("menuField");
        txtField.height = style.menuFontSize+4;
        txtField.y = -3;
        txtField.selectable = false;
        registerTFRoller(txtField, onMenuRollOver, linkHandler);
        registerDragger(txtField); // so that we can still drag from textfield
        addChild(txtField);
        //
        underlay = new Shape();
        addChild(underlay);
        //
        graph = new Shape();
        graph.name = "graph";
        graph.y = style.menuFontSize;
        addChild(graph);
        //

        _menuString = "<menu>";
        if(_type == MEM){
            #if !html5
            _menuString += " <a href=\"event:gc\">G</a> ";
            #end
        }
        _menuString += "<a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></low></r>";

        //
        init(W,H,true);
    }

    private function stop():Void {
        if(_group != null) console.graphing.remove(_group.name);
    }

    public var group(get, never):GraphGroup;
    public function get_group():GraphGroup{
        return _group;
    }

    public function reset():Void {
        _infoMap.clear();
        graph.graphics.clear();
        if(!_group.fixed)
        {
            _group.low = Math.NaN;
            _group.hi = Math.NaN;
        }
    }

    /*public function set showKeyText(b:Boolean):void{
        keyTxt.visible = b;
    }

    public function get showKeyText():Boolean{
        return keyTxt.visible;
    }

    public function set showBoundsText(b:Boolean):void{
        lowTxt.visible = b;
        highTxt.visible = b;
    }

    public function get showBoundsText():Boolean{
        return lowTxt.visible;
    }*/

    #if (flash && haxe_ver < 4.3) @:setter(width) #else override #end public function set_width(value:Float):#if (!flash || haxe_ver >= 4.3) Float #else Void #end
    {
        super.width = value;
        lowTxt.width = value;
        highTxt.width = value;
        txtField.width = value;
        txtField.scrollH = txtField.maxScrollH;
        graph.graphics.clear();
        _needRedraw = true;
        #if (!flash || haxe_ver >= 4.3) return value; #end
    }

    #if (flash && haxe_ver < 4.3) @:setter(height) #else override #end public function set_height(value:Float):#if (!flash || haxe_ver >= 4.3) Float #else Void #end
    {
        super.height = value;
        lowTxt.y = value-style.menuFontSize;
        _needRedraw = true;

        var g:Graphics = underlay.graphics;
        g.clear();
        g.lineStyle(1,style.controlColor, 0.6);
        g.moveTo(0, graph.y);
        g.lineTo(width-startOffset, graph.y);
        g.lineTo(width-startOffset, value);
        #if (!flash || haxe_ver >= 4.3) return value; #end
    }
    //
    //
    //
    public function update(group:GraphGroup, draw:Bool):Void {
        _group = group;
        var push:Int = 1; // 0 = no push, 1 = 1 push, 2 = push all
        if(group.idle>0){
            push = 0;
            if(!_needRedraw) return;
        }
        if(_needRedraw) draw = true;
        _needRedraw = false;
        var interests:Array<GraphInterest> = group.interests;
        var W:Int = Std.int(width-startOffset);
        var H:Int = Std.int(height-graph.y);
        var lowest:Float = group.low;
        var highest:Float = group.hi;
        var diffGraph:Float = highest-lowest;
        var listchanged:Bool = false;
        if(draw) {
            cast(group.inv ? highTxt : lowTxt, TextField).text = Std.string(group.low);
            cast(group.inv ? lowTxt : highTxt, TextField).text = Std.string(group.hi);
            graph.graphics.clear();
        }
        var interest:GraphInterest;
        for(interest in interests){
            _interest = interest;
            var n:String = _interest.key;
            var info:Array<Dynamic> = _infoMap.get(n);
            if(info == null){
                listchanged = true;
                // used to use InterestInfo
                info = [StringTools.hex(_interest.col), new Array()];
                _infoMap.set(n, info);
            }
            var history:Array<Float> = info[1];
            if(push == 1) {
                // special case for FPS, because it needs to fill some frames for lagged 1s...
                if(group.type == GraphGroup.FPS){
                    var frames:Int = Math.floor(group.hi/_interest.v);
                    if(frames>30) frames = 30; // Don't add too many lagged frames
                    while(frames>0){
                        history.push(_interest.v);
                        frames--;
                    }
                }else{
                    history.push(_interest.v);
                }
            }
            var maxLen:Int = Math.floor(W)+10;
            while(history.length > maxLen)
            {
                history.shift();
            }
            if(draw) {
                var len:Int = history.length;
                graph.graphics.lineStyle(1, _interest.col);
                var maxi:Int = W>len?len:W;
                var Y:Float;
                for(i in 1...maxi){
                    Y = (diffGraph != 0 ? ((history[len-i]-lowest)/diffGraph):0.5)*H;
                    if(!group.inv) Y = H-Y;
                    if(Y<0)Y=0;
                    if(Y>H)Y=H;
                    if(i==1){
                        graph.graphics.moveTo(width, Y);
                    }
                    graph.graphics.lineTo((W-i), Y);
                }
                if(Math.isNaN(_interest.avg) && diffGraph != 0){
                    Y = ((_interest.avg-lowest)/diffGraph)*H;
                    if(!group.inv) Y = H-Y;
                    if(Y<0)Y=0;
                    if(Y>H)Y=H;
                    graph.graphics.lineStyle(1,_interest.col, 0.3);
                    graph.graphics.moveTo(0, Y);
                    graph.graphics.lineTo(W, Y);
                }
            }
        }
        for(X in _infoMap.keys()){
            var found:Bool = false;
            for(interest in interests){
                if(interest.key == X)
                {
                    found = true;
                }
            }
            if(!found){
                listchanged = true;
                _infoMap.remove(X);
            }
        }
        if(draw && (listchanged || _type != null)) updateKeyText();
    }

    public function updateKeyText():Void{
        var str:String = "<r><low>";
        if(_type != null){
            if(Math.isNaN(_interest.v)){
                str += "no input";
            }else if(_type == FPS){
                //str += _interest.avg.toFixed(1);
                //TODO: implement required
                str += Std.string(Std.int(_interest.avg));
            }else if(_type == MEM){
                str += _interest.v+"mb";
            }
        }else{
            for(X in _infoMap.keys()){
                str += " <font color='#" + _infoMap.get(X)[0] + "'>"+X+"</font>";
            }
            str += " |";
        }
        txtField.htmlText = str+_menuString;
        txtField.scrollH = txtField.maxScrollH;
    }

    private function linkHandler(e:TextEvent):Void {
        cast(e.currentTarget, TextField).setSelection(0, 0);
        if(e.text == "reset"){
            reset();
        }else if(e.text == "close"){
            if(_type == FPS) console.fpsMonitor = false;
            else if(_type == MEM) console.memoryMonitor = false;
            else stop();
            console.panels.removeGraph(_group);
        }else if(e.text == "gc"){
            console.gc();
        }
        e.stopPropagation();
    }

    private function onMenuRollOver(e:TextEvent):Void {
        var txt:String = e.text != null ? StringTools.replace(e.text, "event:", "") : "";
        if(txt == "gc"){
            txt = "Garbage collect::Requires debugger version of flash player";
        }
        console.panels.tooltip(txt, this);
    }
}
/*
Stopped using this to save 0.5kb! - wow
class InterestInfo{
	public var col:Number;
	public var history:Array = [];
	public function InterestInfo(c:Number){
		col = c;
	}
}*/