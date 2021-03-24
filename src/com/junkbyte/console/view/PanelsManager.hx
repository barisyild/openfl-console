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

import openfl.text.TextFieldAutoSize;
import com.junkbyte.console.Console;
import com.junkbyte.console.vos.GraphGroup;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;

class PanelsManager {

    private var console:Console;
    private var _mainPanel:MainPanel;
    private var _ruler:Ruler;

    private var _chsPanel:ChannelsPanel;
    private var _fpsPanel:GraphingPanel;
    private var _memPanel:GraphingPanel;
    private var _graphsMap:Map<String, GraphingPanel> = new Map();
    private var _graphPlaced:UInt = 0;

    private var _tooltipField:TextField;
    private var _canDraw:Bool;

    public function new(master:Console) {
        console = master;
        _mainPanel = new MainPanel(console);
        _tooltipField = mainPanel.makeTF("tooltip", true);
        _tooltipField.mouseEnabled = false;
        _tooltipField.autoSize = TextFieldAutoSize.CENTER;
        _tooltipField.multiline = true;
        addPanel(_mainPanel);
    }
    public function addPanel(panel:ConsolePanel):Void {
        if(console.contains(_tooltipField)){
            console.addChildAt(panel, console.getChildIndex(_tooltipField));
        }else{
            console.addChild(panel);
        }
        panel.addEventListener(ConsolePanel.DRAGGING_STARTED, onPanelStartDragScale, false,0, true);
        panel.addEventListener(ConsolePanel.SCALING_STARTED, onPanelStartDragScale, false,0, true);
    }
    public function removePanel(n:String):Void {
        var panel:ConsolePanel = cast(console.getChildByName(n), ConsolePanel);
        if(panel != null){
            // this removes it self from parent. this way each individual panel can clean up before closing.
            panel.close();
        }
    }
    public function getPanel(n:String):ConsolePanel{
        return cast(console.getChildByName(n), ConsolePanel);
    }
    public var mainPanel(get, never):MainPanel;
    public function get_mainPanel():MainPanel{
        return _mainPanel;
    }

    public function panelExists(n:String):Bool{
        return Std.is(console.getChildByName(n), ConsolePanel)?true:false;
    }
    /**
		 * Set panel position and size.
		 * <p>
		 * See panel names in Console.NAME, FPSPanel.NAME, MemoryPanel.NAME, RollerPanel.NAME, RollerPanel.NAME, etc...
		 * No effect if panel of that name doesn't exist.
		 * </p>
		 * @param	Name of panel to set
		 * @param	Rectangle area for panel size and position. Leave any property value zero to keep as is.
		 *  		For example, if you don't want to change the height of the panel, pass rect.height = 0;
		 */
    public function setPanelArea(panelname:String, rect:Rectangle):Void{
        var panel:ConsolePanel = getPanel(panelname);
        if(panel != null){
            panel.x = rect.x;
            panel.y = rect.y;
            if(rect.width != 0) panel.width = rect.width;
            if(rect.height != 0) panel.height = rect.height;
        }
    }
    /**
     * @private
     */
    public function updateMenu():Void{
        _mainPanel.updateMenu();
        var chpanel:ChannelsPanel = cast(getPanel(ChannelsPanel.NAME), ChannelsPanel);
        if(chpanel != null) chpanel.update();
    }

    /**
     * @private
     */
    public function update(paused:Bool, lineAdded:Bool):Void {
        _canDraw = !paused;
        _mainPanel.update(!paused && lineAdded);
        if(!paused) {
            if(lineAdded && _chsPanel!=null){
                _chsPanel.update();
            }
        }
    }
    /**
     * @private
     */
    public function updateGraphs(graphs:Array<GraphGroup>):Void {
        var usedMap:Dynamic = null;
        var fpsGroup:GraphGroup = null;
        var memGroup:GraphGroup = null;
        _graphPlaced = 0;
        for(group in graphs){
            if(group.type == GraphGroup.FPS) {
                fpsGroup = group;
            }else if(group.type == GraphGroup.MEM) {
                memGroup = group;
            }else{
                var n:String = group.name;
                var panel:GraphingPanel = cast(_graphsMap[n], GraphingPanel);
                if(panel == null){
                    var rect:Rectangle = group.rect;
                    if(rect == null) rect = new Rectangle(Math.NaN,Math.NaN, 0, 0);
                    var size:Int = 100;
                    if(rect.x == Math.NaN || rect.y == Math.NaN){
                        if(_mainPanel.width < 150){
                            size = 50;
                        }
                        var maxX:Int = Math.floor(_mainPanel.width/size)-1;
                        if(maxX <=1) maxX = 2;
                        var ix:Int = _graphPlaced%maxX;
                        var iy:Int = Math.floor(_graphPlaced/maxX);
                        rect.x = _mainPanel.x+size+(ix*size);
                        rect.y = _mainPanel.y+(size*0.6)+(iy*size);
                        _graphPlaced++;
                    }
                    if(rect.width<=0 || rect.width == Math.NaN)  rect.width = size;
                    if(rect.height<=0 || rect.height == Math.NaN) rect.height = size;
                    panel = new GraphingPanel(console, rect.width,rect.height);
                    panel.x = rect.x;
                    panel.y = rect.y;
                    panel.name = "graph_"+n;
                    _graphsMap[n] = panel;
                    addPanel(panel);
                }
                if(usedMap == null)
                {
                    usedMap = {};
                }
                Reflect.setField(usedMap, n, true);
                panel.update(group, _canDraw);
            }
        }

        for(X in _graphsMap.keys()){
            if(usedMap == null || !Reflect.hasField(usedMap, X)){

                _graphsMap[X].close();
                _graphsMap.remove(X);
            }
        }
        //
        //
        if(fpsGroup != null){
            if (_fpsPanel == null) {
                _fpsPanel = new GraphingPanel(console, 80 ,40, GraphingPanel.FPS);
                _fpsPanel.name = GraphingPanel.FPS;
                _fpsPanel.x = _mainPanel.x+_mainPanel.width-160;
                _fpsPanel.y = _mainPanel.y+15;
                addPanel(_fpsPanel);
                _mainPanel.updateMenu();
            }
            _fpsPanel.update(fpsGroup, _canDraw);
        }else if(_fpsPanel!=null){
            removePanel(GraphingPanel.FPS);
            _fpsPanel = null;
        }
        //
        //
        if(memGroup != null){
            if(_memPanel == null){
                _memPanel = new GraphingPanel(console, 80 ,40, GraphingPanel.MEM);
                _memPanel.name = GraphingPanel.MEM;
                _memPanel.x = _mainPanel.x+_mainPanel.width-80;
                _memPanel.y = _mainPanel.y+15;
                addPanel(_memPanel);
                _mainPanel.updateMenu();
            }
            _memPanel.update(memGroup, _canDraw);
        }else if(_memPanel!=null){
            removePanel(GraphingPanel.MEM);
            _memPanel = null;
        }
        _canDraw = false;
    }
    /**
		 * @private
		 */
    public function removeGraph(group:GraphGroup):Void
    {
        if(_fpsPanel != null && group == _fpsPanel.group){
            _fpsPanel.close();
            _fpsPanel = null;
        }else if(_memPanel != null && group == _memPanel.group){
            _memPanel.close();
            _memPanel = null;
        }else{
            var graph:GraphingPanel = _graphsMap[group.name];
            if(graph != null){
                graph.close();
                _graphsMap.remove(group.name);
            }
        }
    }
    //
    //
    //
    /**
     * @private
     */
    public var displayRoller(get, set):Bool;
    public function get_displayRoller():Bool
    {
        return Std.is(getPanel(RollerPanel.NAME), RollerPanel)?true:false;
    }

    public function set_displayRoller(n:Bool):Bool
    {
        if(displayRoller != n){
            if(n){
                if(console.config.displayRollerEnabled){
                    var roller:RollerPanel = new RollerPanel(console);
                    roller.x = _mainPanel.x+_mainPanel.width-180;
                    roller.y = _mainPanel.y+55;
                    addPanel(roller);
                }else{
                    console.report("Display roller is disabled in config.", 9);
                }
            }else{
                removePanel(RollerPanel.NAME);
            }
            _mainPanel.updateMenu();
        }
        return n;
    }
    //
    //
    //
    public var channelsPanel(get, set):Bool;
    public function get_channelsPanel():Bool {
        return _chsPanel != null;
    }

    public function set_channelsPanel(b:Bool):Bool {
        if(channelsPanel != b){
            console.logs.cleanChannels();
            if(b){
                _chsPanel = new ChannelsPanel(console);
                _chsPanel.x = _mainPanel.x+_mainPanel.width-332;
                _chsPanel.y = _mainPanel.y-2;
                addPanel(_chsPanel);
                _chsPanel.update();
                updateMenu();
            }else {
                removePanel(ChannelsPanel.NAME);
                _chsPanel = null;
            }
            updateMenu();
        }
        return b;
    }
    //
    //
    //
    /**
     * @private
     */
    public var memoryMonitor(get, never):Bool;
    public function get_memoryMonitor():Bool{
        return _memPanel!=null;
    }

    /**
     * @private
     */
    public var fpsMonitor(get, never):Bool;
    public function get_fpsMonitor():Bool{
        return _fpsPanel!=null;
    }
    //
    //
    //
    /**
     * @private
     */
    public function tooltip(str:String = null, panel:ConsolePanel = null):Void{
        if(str != null && !rulerActive){
            var split:Array<String> = str.split("::");
            str = split[0];
            if(split.length > 1) str += "<br/><low>"+split[1]+"</low>";
            console.addChild(_tooltipField);
            _tooltipField.wordWrap = false;
            _tooltipField.htmlText = "<tt>"+str+"</tt>";
            if(_tooltipField.width>120){
                _tooltipField.width = 120;
                _tooltipField.wordWrap = true;
            }
            _tooltipField.x = console.mouseX-(_tooltipField.width/2);
            _tooltipField.y = console.mouseY+20;
            if(panel != null){
                var txtRect:Rectangle = _tooltipField.getBounds(console);
                var panRect:Rectangle = new Rectangle(panel.x,panel.y,panel.width,panel.height);
                var doff:Float = txtRect.bottom - panRect.bottom;
                if(doff>0){
                    if((_tooltipField.y - doff)>(console.mouseY+15)){
                        _tooltipField.y -= doff;
                    }else if(panRect.y<(console.mouseY-24) && txtRect.y>panRect.bottom){
                        _tooltipField.y = console.mouseY-_tooltipField.height-15;
                    }
                }
                var loff:Float = txtRect.left - panRect.left;
                var roff:Float = txtRect.right - panRect.right;
                if(loff<0){
                    _tooltipField.x -= loff;
                }else if(roff>0){
                    _tooltipField.x -= roff;
                }
            }
        }else if(console.contains(_tooltipField)){
            console.removeChild(_tooltipField);
        }
    }
    //
    //
    //
    public function startRuler():Void{
        if(rulerActive){
            return;
        }
        _ruler = new Ruler(console);
        _ruler.addEventListener(Event.COMPLETE, onRulerExit, false, 0, true);
        console.addChild(_ruler);
        _mainPanel.updateMenu();
    }

    public var rulerActive(get, never):Bool;

    public function get_rulerActive():Bool{
        return (_ruler != null && console.contains(_ruler))?true:false;
    }

    private function onRulerExit(e:Event):Void{
        if(_ruler != null && console.contains(_ruler)){
            console.removeChild(_ruler);
        }
        _ruler = null;
        _mainPanel.updateMenu();
    }
    //
    //
    //
    private function onPanelStartDragScale(e:Event):Void{
        var target:ConsolePanel = cast(e.currentTarget, ConsolePanel);
        if(console.config.style.panelSnapping != 0) {
            var X:Array<Float> = [0];
            var Y:Array<Float> = [0];
            if(console.stage != null){
                // this will only work if stage size is not changed or top left aligned
                X.push(console.stage.stageWidth);
                Y.push(console.stage.stageHeight);
            }
            var numchildren:Int = console.numChildren;
            for(i in 0...numchildren){
                if(Std.is(console.getChildAt(i), ConsolePanel))
                {
                    var panel:ConsolePanel = cast(console.getChildAt(i), ConsolePanel);
                    if(panel != null && panel.visible){
                        X.push(panel.x);
                        X.push(panel.x + panel.width);
                        Y.push(panel.y);
                        Y.push(panel.y + panel.height);
                    }
                }
            }
            target.registerSnaps(X, Y);
        }
    }
}