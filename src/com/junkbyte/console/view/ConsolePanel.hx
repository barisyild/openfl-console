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

import com.junkbyte.console.core.ConsoleTextField;
import flash.text.TextFormat;
import openfl.utils.Function;
import openfl.errors.Error;
import openfl.text.TextFieldAutoSize;
import com.junkbyte.console.ConsoleStyle;
import com.junkbyte.console.ConsoleConfig;
import openfl.events.TextEvent;
import com.junkbyte.console.Console;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import com.junkbyte.console.abstracts.RFloat;

class ConsolePanel extends Sprite {

    public static inline var DRAGGING_STARTED:String = "draggingStarted";
    public static inline var DRAGGING_ENDED:String = "draggingEnded";
    public static inline var SCALING_STARTED:String = "scalingStarted";
    public static inline var SCALING_ENDED:String = "scalingEnded";
    public static inline var VISIBLITY_CHANGED:String = "visibilityChanged";
    private static inline var TEXT_ROLL:String = "TEXT_ROLL";

    private var _snaps:Array<Array<Float>>;
    private var _dragOffset:Point;
    private var _resizeTxt:TextField;
    private var console:Console;
    private var bg:Sprite;
    private var scaler:Sprite;
    private var txtField:TextField;
    private var minWidth:Int = 18;
    private var minHeight:Int = 18;
    private var _movedFrom:Point;
    /**
     * Specifies whether this panel can be moved from GUI.
     */
    public var moveable:Bool = true;

    public function new(m:Console) {
        super();
        console = m;
        bg = new Sprite();
        bg.name = "background";
        addChild(bg);
    }

    private var config(get, never):ConsoleConfig;
    private function get_config() : ConsoleConfig {
        return console.config;
    }

    private var style(get, never):ConsoleStyle;
    private function get_style() : ConsoleStyle {
        return console.config.style;
    }

    private function init(w:Float, h:Float, resizable:Bool = false, col:Int = -1, a:Float = -1, rounding:Int = -1):Void {
        bg.graphics.clear();
        bg.graphics.beginFill(col>=0?col:style.backgroundColor, a>=0?a:style.backgroundAlpha);
        if(rounding < 0) rounding = style.roundBorder;
        if(rounding <= 0) bg.graphics.drawRect(0, 0, 100, 100);
        else {
            //TODO: Fix Background after scale9Grid fixed.
            #if flash
            bg.graphics.drawRoundRect(0, 0, rounding+10, rounding+10, rounding, rounding);
            bg.scale9Grid = new Rectangle(rounding*0.5, rounding*0.5, 10, 10);
            #else
            bg.graphics.drawRect(0, 0, w, h);
            #end
        }

        scalable = resizable;
        width = w;
        height = h;
    }

    /**
     * Close / remove the panel.
     */
    public function close():Void {
        stopDragging();
        console.panels.tooltip();
        if(parent != null){
            parent.removeChild(this);
        }
        dispatchEvent(new Event(Event.CLOSE));
    }

    #if (flash && haxe_ver < 4.3) @:setter(visible) #else override #end private function set_visible(value:Bool):#if (!flash || haxe_ver >= 4.3) Bool #else Void #end
    {
        super.visible = value;
        dispatchEvent(new Event(VISIBLITY_CHANGED));
        #if (!flash || haxe_ver >= 4.3) return value; #end
    }
    //
    // SIZE
    //
    #if (flash && haxe_ver < 4.3) @:getter(width) #else override #end private function get_width():Float
    {
        return bg.width;
    }

    #if (flash && haxe_ver < 4.3) @:setter(width) #else override #end private function set_width(value:Float):#if (!flash || haxe_ver >= 4.3) Float #else Void #end
    {
        if(value < minWidth) value = minWidth;
        if(scaler != null) scaler.x = value;
        bg.width = value;
        #if (!flash || haxe_ver >= 4.3) return value; #end
    }

    #if (flash && haxe_ver < 4.3) @:getter(height) #else override #end private function get_height():Float
    {
        return bg.height;
    }

    #if (flash && haxe_ver < 4.3) @:setter(height) #else override #end private function set_height(value:Float):#if (!flash || haxe_ver >= 4.3) Float #else Void #end
    {
        if(value < minHeight) value = minHeight;
        if(scaler != null) scaler.y = value;
        bg.height = value;
        #if (!flash || haxe_ver >= 4.3) return value; #end
    }
    //
    // MOVING
    //
    /**
     * @private
     */
    public function registerSnaps(X:Array<Float>, Y:Array<Float>):Void {
        _snaps = [X,Y];
    }

    private function registerDragger(mc:DisplayObject, dereg:Bool = false):Void {
        if(dereg){
            mc.removeEventListener(MouseEvent.MOUSE_DOWN, onDraggerMouseDown);
        }else{
            mc.addEventListener(MouseEvent.MOUSE_DOWN, onDraggerMouseDown, false, 0, true);
        }
    }

    private function onDraggerMouseDown(e:MouseEvent):Void {
        if(stage == null || !moveable) return;
        //
        _resizeTxt = makeTF("positioningField", true);
        _resizeTxt.mouseEnabled = false;
        _resizeTxt.autoSize = TextFieldAutoSize.LEFT;
        addChild(_resizeTxt);
        updateDragText();
        //
        _movedFrom = new Point(x, y);
        _dragOffset = new Point(mouseX,mouseY); // using this way instead of startDrag, so that it can control snapping.
        _snaps = [[],[]];
        dispatchEvent(new Event(DRAGGING_STARTED));
        stage.addEventListener(MouseEvent.MOUSE_UP, onDraggerMouseUp, false, 0, true);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onDraggerMouseMove, false, 0, true);
    }

    private function onDraggerMouseMove(e:MouseEvent = null):Void {
        if(style.panelSnapping==0) return;
        // YEE HA, SNAPPING!
        var p:Point = returnSnappedFor(parent.mouseX-_dragOffset.x, parent.mouseY-_dragOffset.y);
        x = p.x;
        y = p.y;
        updateDragText();
    }

    private function updateDragText():Void {
        _resizeTxt.htmlText = "<low>"+(x:RFloat)+","+(y:RFloat)+"</low>";
    }
    private function onDraggerMouseUp(e:MouseEvent):Void {
        stopDragging();
    }

    private function stopDragging():Void {
        _snaps = null;
        if(stage != null){
            stage.removeEventListener(MouseEvent.MOUSE_UP, onDraggerMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDraggerMouseMove);
        }
        if(_resizeTxt != null && _resizeTxt.parent != null){
            _resizeTxt.parent.removeChild(_resizeTxt);
        }
        _resizeTxt = null;
        dispatchEvent(new Event(DRAGGING_ENDED));
    }
    /**
     * @private
     */
    public function moveBackSafePosition():Void {
        if(_movedFrom != null){
            // This will only work if stage size is not altered OR stage.align is top left
            if(x+width<10 || (stage != null && stage.stageWidth<x+10) || y+height<10 || (stage != null && stage.stageHeight<y+20)) {
                x = _movedFrom.x;
                y = _movedFrom.y;
            }
            _movedFrom = null;
        }
    }
    //
    // SCALING
    //
    /**
		 * Specifies whether this panel can be scaled from GUI.
		 */
    public var scalable(get, set):Bool;
    public function get_scalable():Bool{
        return scaler != null?true:false;
    }

    public function set_scalable(b:Bool):Bool{
        if(b && scaler == null){
            var size:UInt = cast 8 + (style.controlSize * 0.5);
            scaler = new Sprite();
            scaler.name = "scaler";
            scaler.graphics.beginFill(0, 0);
            scaler.graphics.drawRect(-size*1.5, -size*1.5, size*1.5, size*1.5);
            scaler.graphics.endFill();
            scaler.graphics.beginFill(style.controlColor, style.backgroundAlpha);
            scaler.graphics.moveTo(0, 0);
            scaler.graphics.lineTo(-size, 0);
            scaler.graphics.lineTo(0, -size);
            scaler.graphics.endFill();
            scaler.buttonMode = true;
            scaler.doubleClickEnabled = true;
            scaler.addEventListener(MouseEvent.MOUSE_DOWN,onScalerMouseDown, false, 0, true);
            addChildAt(scaler, getChildIndex(bg)+1);
        }else if(!b && scaler != null){
            if(contains(scaler)){
                removeChild(scaler);
            }
            scaler = null;
        }
        return b;
    }

    private function onScalerMouseDown(e:Event):Void {
        _resizeTxt = makeTF("resizingField", true);
        _resizeTxt.mouseEnabled = false;
        _resizeTxt.autoSize = TextFieldAutoSize.RIGHT;
        _resizeTxt.x = -4;
        _resizeTxt.y = -17;
        scaler.addChild(_resizeTxt);
        updateScaleText();
        _dragOffset = new Point(scaler.mouseX, scaler.mouseY); // using this way instead of startDrag, so that it can control snapping.
        _snaps = [[],[]];
        scaler.stage.addEventListener(MouseEvent.MOUSE_UP,onScalerMouseUp, false, 0, true);
        scaler.stage.addEventListener(MouseEvent.MOUSE_MOVE,updateScale, false, 0, true);
        dispatchEvent(new Event(SCALING_STARTED));
    }

    private function updateScale(e:Event = null):Void {
        var p:Point = returnSnappedFor(x+mouseX-_dragOffset.x, y+mouseY-_dragOffset.x);
        p.x-=x;
        p.y-=y;
        width = p.x<minWidth?minWidth:p.x;
        height = p.y<minHeight?minHeight:p.y;
        updateScaleText();
    }

    private function updateScaleText():Void {
        _resizeTxt.htmlText = "<low>"+Std.int(width)+","+Std.int(height)+"</low>";
    }

    public function stopScaling():Void {
        onScalerMouseUp(null);
    }

    private function onScalerMouseUp(e:Event):Void {
        scaler.stage.removeEventListener(MouseEvent.MOUSE_UP,onScalerMouseUp);
        scaler.stage.removeEventListener(MouseEvent.MOUSE_MOVE,updateScale);
        updateScale();
        _snaps = null;
        if(_resizeTxt != null && _resizeTxt.parent != null){
            _resizeTxt.parent.removeChild(_resizeTxt);
        }
        _resizeTxt = null;
        dispatchEvent(new Event(SCALING_ENDED));
    }
    //
    //
    /**
     * @private
     */
    public function makeTF(n:String, back:Bool = false):TextField
    {
        var txt:ConsoleTextField = new ConsoleTextField();
        txt.name = n;
        txt.styleSheet = style.styleSheet;
        if(back){
            txt.background = true;
            txt.backgroundColor = style.backgroundColor;
        }
        return txt;
    }
    //
    //
    private function returnSnappedFor(X:Float,Y:Float):Point{
        return new Point(getSnapOf(X, true),getSnapOf(Y, false));
    }

    private function getSnapOf(v:Float, isX:Bool):Float{
        var end:Float = v+width;
        var a:Array<Float> = _snaps[isX?0:1];
        var s:Int = style.panelSnapping;
        for(ii in a){
            if(Math.abs(ii-v)<s) return ii;
            if(Math.abs(ii-end)<s) return ii-width;
        }
        return v;
    }

    private function registerTFRoller(field:TextField, overhandle:Dynamic->Void, linkHandler:Dynamic->Void = null):Void{
        field.addEventListener(MouseEvent.MOUSE_MOVE, onTextFieldMouseMove, false, 0, true);
        field.addEventListener(MouseEvent.ROLL_OUT, onTextFieldMouseOut, false, 0, true);
        field.addEventListener(TEXT_ROLL, overhandle, false, 0, true);
        if(linkHandler != null) {
            field.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
        }
    }

    private static function onTextFieldMouseOut(e:MouseEvent):Void{
        cast(e.currentTarget, TextField).dispatchEvent(new TextEvent(TEXT_ROLL));
    }

    private static function onTextFieldMouseMove(e:MouseEvent):Void{
        var field:TextField = cast(e.currentTarget, TextField);
        var index:Int = 0;
        if(field.scrollH>0){
            // kinda a hack really :(
            var scrollH:Int = field.scrollH;
            var w:Float = field.width;
            field.width = w + scrollH;
            index = field.getCharIndexAtPoint(field.mouseX + scrollH, field.mouseY);
            field.width = w;
            field.scrollH = scrollH;
        }else{
            index = field.getCharIndexAtPoint(field.mouseX, field.mouseY);
        }
        var url:String = null;
        //var txt:String = null;
        if(index>0){
            // TextField.getXMLText(...) is not documented
            /*try{
                var X:XML = new XML(field.getXMLText(index,index+1));
                if(X.hasOwnProperty("textformat")){
                    var txtformat:XML = cast(X["textformat"][0], XML);
                    if(txtformat != null){
                        url = txtformat.@url;
                    }
                }
            }catch(err:Error){
                url = null;
            }*/
            //TODO: implement required
        }

        field.dispatchEvent(new TextEvent(TEXT_ROLL,false,false,url));
    }
}