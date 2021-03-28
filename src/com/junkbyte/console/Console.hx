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
package com.junkbyte.console;

import com.junkbyte.console.utils.FlashRegex;
import com.junkbyte.console.vos.GraphGroup;
import openfl.utils.Function;
import openfl.errors.Error;
import openfl.system.Capabilities;
import com.junkbyte.console.core.CommandLine;
import com.junkbyte.console.core.ConsoleTools;
import com.junkbyte.console.core.Graphing;
import com.junkbyte.console.core.KeyBinder;
import com.junkbyte.console.core.LogReferences;
import com.junkbyte.console.core.Logs;
import com.junkbyte.console.core.MemoryMonitor;
import com.junkbyte.console.core.Remoting;
import com.junkbyte.console.view.PanelsManager;
import com.junkbyte.console.view.RollerPanel;
import com.junkbyte.console.vos.Log;

import openfl.display.DisplayObjectContainer;
import openfl.display.LoaderInfo;
import openfl.display.Sprite;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.IEventDispatcher;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.net.SharedObject;
/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
class Console extends Sprite {

    public static inline var VERSION:Float = 2.6;
    public static inline var VERSION_STAGE:String = "";
    public static inline var BUILD:UInt = 611;
    public static inline var BUILD_DATE:String = "2012/02/22 00:11";
    //
    public static inline var LOG:UInt = 1;
    public static inline var INFO:UInt = 3;
    public static inline var DEBUG:UInt = 6;
    public static inline var WARN:UInt = 8;
    public static inline var ERROR:UInt = 9;
    public static inline var FATAL:UInt = 10;
    //
    public static inline var GLOBAL_CHANNEL:String = " * ";
    public static inline var DEFAULT_CHANNEL:String = "-";
    public static inline var CONSOLE_CHANNEL:String = "C";
    public static inline var FILTER_CHANNEL:String = "~";
    //
    private var _config:ConsoleConfig;
    private var _panels:PanelsManager;
    private var _cl:CommandLine;
    private var _kb:KeyBinder;
    private var _refs:LogReferences;
    private var _mm:MemoryMonitor;
    private var _graphing:Graphing;
    private var _remoter:Remoting;
    private var _tools:ConsoleTools;
    //
    private var _topTries:Int = 50;
    private var _paused:Bool;
    private var _rollerKey:KeyBind;
    private var _logs:Logs;

    private var _so:SharedObject;
    private var _soData:Dynamic = {};

    /**
     * Console is the main class. However please use Cc for singleton Console adapter.
     * Using Console through Cc will also make sure you can remove console in a later date
     * by simply removing Cc.start() or Cc.startOnStage()
     * See com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
     *
     * @see com.junkbyte.console.Cc
     * @see http://code.google.com/p/flash-console/
     */

    public function new(password:String = null, config:ConsoleConfig = null) {
        super();
        name = "Console";
        if(config == null) config = new ConsoleConfig();
        _config = config;
        if (password != null) {
            _config.keystrokePassword = password;
        }
        //
        _remoter = new Remoting(this);
        _logs = new Logs(this);
        _refs = new LogReferences(this);
        _cl = new CommandLine(this);
        _tools =  new ConsoleTools(this);
        _graphing = new Graphing(this);
        _mm = new MemoryMonitor(this);
        _kb = new KeyBinder(this);

        cl.addCLCmd("remotingSocket", function(str:String = ""):Void {
            var args:Array<String> = FlashRegex.split(str, ~/\s+|\\:/);
            remotingSocket(args[0], Std.parseInt(args[1]));
        }, "Connect to socket remote. /remotingSocket ip port");

        if(_config.sharedObjectName != null){
            try{
                _so = SharedObject.getLocal(_config.sharedObjectName, _config.sharedObjectPath);
                _soData = _so.data;
            }catch(e:Error){

            }
        }

        _config.style.updateStyleSheet();
        _panels = new PanelsManager(this);
        if(password != null) visible = false;

        //report("<b>Console v"+VERSION+VERSION_STAGE+" b"+BUILD+". Happy coding!</b>", -2);
        report("<b>Console v"+VERSION+VERSION_STAGE+"</b> build "+BUILD+". "+Capabilities.playerType+" "+Capabilities.version+".", -2);

        // must have enterFrame here because user can start without a parent display and use remoting.
        addEventListener(Event.ENTER_FRAME, _onEnterFrame);
        addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
    }

    private function stageAddedHandle(e:Event=null):Void {
        if(_cl.base == null) _cl.base = cast parent;
        if(loaderInfo != null){
            listenUncaughtErrors(loaderInfo);
        }
        removeEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
        addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
        stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave, false, 0, true);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, _kb.keyDownHandler, false, 0, true);
        stage.addEventListener(KeyboardEvent.KEY_UP, _kb.keyUpHandler, false, 0, true);
    }

    private function stageRemovedHandle(e:Event=null):Void {
        _cl.base = null;
        removeEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
        addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
        stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
        stage.removeEventListener(KeyboardEvent.KEY_DOWN, _kb.keyDownHandler);
        stage.removeEventListener(KeyboardEvent.KEY_UP, _kb.keyUpHandler);
    }

    private function onStageMouseLeave(e:Event):Void {
        _panels.tooltip(null);
    }

    /**
     * @copy com.junkbyte.console.Cc#listenUncaughtErrors()
     */

    public function listenUncaughtErrors(loaderinfo:LoaderInfo):Void {
        try{
            var uncaughtErrorEvents:IEventDispatcher = Reflect.field(loaderinfo, "uncaughtErrorEvents");
            if(uncaughtErrorEvents != null){
                uncaughtErrorEvents.addEventListener("uncaughtError", uncaughtErrorHandle, false, 0, true);
            }
        }catch(err:Error){
            // seems uncaughtErrorEvents is not avaviable on this player/target, which is fine.
        }
    }

    private function uncaughtErrorHandle(e:Event):Void
    {
        var error:Dynamic = Reflect.hasField(e, "error") ? Reflect.field(e, "error") : e; // for flash 9 compatibility
        var str:String = null;
        if (Std.is(error, Error)){
            str = _refs.makeString(error);
        }else if (Std.is(error, ErrorEvent)){
            str = cast(error, ErrorEvent).text;
        }
        if(str == null){
            str = Std.string(error);
        }
        report(str, FATAL, false);
    }


    /**
     * @copy com.junkbyte.console.Cc#addGraph()
     */

    //TODO: Warning Modified arguement, color:Number => color:Int
    public function addGraph(name:String, obj:Dynamic, property:String, color:Int = -1, key:String = null, rect:Rectangle = null, inverse:Bool = false):Void {
        _graphing.add(name, obj, property, color, key, rect, inverse);
    }

    /**
     * @copy com.junkbyte.console.Cc#fixGraphRange()
     */

    //TODO: Warning Modified arguement, min:Number = NaN => min:Float = Math.NaN, max:Number = NaN => max:Float = Math.NaN
    public function fixGraphRange(name:String, min:Float = null, max:Float = null):Void {
        if(min == null)
        {
            min = Math.NaN;
        }

        if(max == null)
        {
            max = Math.NaN;
        }

        _graphing.fixRange(name, min, max);
    }

    /**
     * @copy com.junkbyte.console.Cc#removeGraph()
     */

    public function removeGraph(name:String, obj:Dynamic = null, property:String = null):Void {
        _graphing.remove(name, obj, property);
    }

    /**
     * @copy com.junkbyte.console.Cc#bindKey()
     */

    public function bindKey(key:KeyBind, callback:Function ,args:Array<Dynamic> = null):Void {
        if(key != null) _kb.bindKey(key, callback, args);
    }

    /**
     * @copy com.junkbyte.console.Cc#addMenu()
     */

    public function addMenu(key:String, callback:Function, args:Array<Dynamic> = null, rollover:String = null):Void {
        panels.mainPanel.addMenu(key, callback, args, rollover);
    }
    //
    // Panel settings
    // basically passing through to panels manager to save lines
    //

    /**
     * @copy com.junkbyte.console.Cc#displayRoller
     */

    public var displayRoller(get, set):Bool;

    public function get_displayRoller():Bool{
        return _panels.displayRoller;
    }

    public function set_displayRoller(b:Bool):Bool{
        _panels.displayRoller = b;
        return b;
    }

    /**
     * @copy com.junkbyte.console.Cc#setRollerCaptureKey()
     */

    public function setRollerCaptureKey(char:String, shift:Bool = false, ctrl:Bool = false, alt:Bool = false):Void {
        if(_rollerKey != null){
            bindKey(_rollerKey, null);
            _rollerKey = null;
        }
        if(char != null && char.length==1) {
            _rollerKey = new KeyBind(char, shift, ctrl, alt);
            bindKey(_rollerKey, onRollerCaptureKey);
        }
    }

    public var rollerCaptureKey(get, never):KeyBind;
    public function get_rollerCaptureKey():KeyBind{
        return _rollerKey;
    }

    private function onRollerCaptureKey():Void{
        if(displayRoller){
            report("Display Roller Capture:<br/>"+cast(_panels.getPanel(RollerPanel.NAME), RollerPanel).getMapString(true), -1);
        }
    }

    /**
     * @copy com.junkbyte.console.Cc#fpsMonitor
     */
    public var fpsMonitor(get, set):Bool;
    public function get_fpsMonitor():Bool{
        return _graphing.fpsMonitor;
    }
    public function set_fpsMonitor(b:Bool):Bool{
        _graphing.fpsMonitor = b;
        return b;
    }

    /**
     * @copy com.junkbyte.console.Cc#memoryMonitor
     */
    public var memoryMonitor(get, set):Bool;
    public function get_memoryMonitor():Bool{
        return _graphing.memoryMonitor;
    }
    public function set_memoryMonitor(b:Bool):Bool{
        _graphing.memoryMonitor = b;
        return b;
    }

    /**
     * @copy com.junkbyte.console.Cc#watch()
     */
    public function watch(object:Dynamic, name:String = null):String{
        return _mm.watch(object, name);
    }

    /**
     * @copy com.junkbyte.console.Cc#unwatch()
     */
    public function unwatch(name:String):Void {
        _mm.unwatch(name);
    }

    public function gc():Void {
        _mm.gc();
    }

    /**
     * @copy com.junkbyte.console.Cc#store()
     */
    public function store(name:String, obj:Dynamic, strong:Bool = false):Void{
        _cl.store(name, obj, strong);
    }

    /**
     * @copy com.junkbyte.console.Cc#map()
     */
    public function map(container:DisplayObjectContainer, maxstep:UInt = 0):Void{
        _tools.map(container, maxstep, DEFAULT_CHANNEL);
    }

    /**
     * @copy com.junkbyte.console.Cc#mapch()
     */
    public function mapch(channel:Dynamic, container:DisplayObjectContainer, maxstep:UInt = 0):Void {
        _tools.map(container, maxstep, MakeChannelName(channel));
    }

    /**
     * @copy com.junkbyte.console.Cc#inspect()
     */
    public function inspect(obj:Dynamic, showInherit:Bool = true):Void {
        _refs.inspect(obj, showInherit, DEFAULT_CHANNEL);
    }

    /**
     * @copy com.junkbyte.console.Cc#inspectch()
     */
    public function inspectch(channel:Dynamic, obj:Dynamic, showInherit:Bool = true):Void {
        _refs.inspect(obj, showInherit, MakeChannelName(channel));
    }

    /**
     * @copy com.junkbyte.console.Cc#explode()
     */
    public function explode(obj:Dynamic, depth:Int = 3):Void {
        addLine([_tools.explode(obj, depth)], 1, null, false, true);
    }

    /**
		 * @copy com.junkbyte.console.Cc#explodech()
		 */
    public function explodech(channel:Dynamic, obj:Dynamic, depth:Int = 3):Void {
        addLine([_tools.explode(obj, depth)], 1, channel, false, true);
    }

    public var paused(get, set):Bool;
    public function get_paused():Bool{
        return _paused;
    }
    public function set_paused(newV:Bool):Bool{
        if(_paused == newV) return newV;
        if(newV) report("Paused", 10);
        else report("Resumed", -1);
        _paused = newV;
        _panels.mainPanel.setPaused(newV);
        return newV;
    }
    //
    //
    //
    @:getter(width) public #if !flash override #end function get_width()
    {
        return _panels.mainPanel.width;
    }

    @:setter(width) private #if !flash override #end function set_width(value:Float)
    {
        _panels.mainPanel.width = value;
        #if !flash return value; #end
    }

    @:getter(height) private #if !flash override #end function get_height()
    {
        return _panels.mainPanel.height;
    }

    @:setter(height) private #if !flash override #end function set_height(value:Float)
    {
        _panels.mainPanel.height = value;
        #if !flash return value; #end
    }

    @:setter(x) private #if !flash override #end function set_x(value:Float)
    {
        _panels.mainPanel.x = value;
        #if !flash return value; #end
    }

    @:getter(x) private #if !flash override #end function get_x()
    {
        return _panels.mainPanel.x;
    }

    @:setter(y) private #if !flash override #end function set_y(value:Float)
    {
        _panels.mainPanel.y = value;
        #if !flash return value; #end
    }

    @:getter(y) private #if !flash override #end function get_y()
    {
        return _panels.mainPanel.y;
    }

    @:setter(visible) private #if !flash override #end function set_visible(value:Bool)
    {
        super.visible = value;
        if(value) _panels.mainPanel.visible = true;
        #if !flash return value; #end
    }
    //
    //
    //
    private function _onEnterFrame(e:Event):Void {
        var time:Int = openfl.Lib.getTimer();
        _logs.update(time);
        _refs.update(time);
        _mm.update();
        var graphsList:Array<GraphGroup> = null;
        if(remoter.remoting != Remoting.RECIEVER)
        {
            graphsList = _graphing.update(stage != null ? Std.int(stage.frameRate) : 0);
        }
        _remoter.update();

        // VIEW UPDATES ONLY
        if(visible && parent != null){
            if(config.alwaysOnTop && _topTries > 0 && parent.numChildren > parent.getChildIndex(this) + 1)
            {
                _topTries--;
                parent.addChild(this);
                report("Moved console on top (alwaysOnTop enabled), "+_topTries+" attempts left.",-1);
            }
            _panels.update(_paused, _logs.hasNewLog);
            _logs.hasNewLog = false;
            if(graphsList != null) _panels.updateGraphs(graphsList);
        }
    }
    //
    // REMOTING
    //

    /**
     * @copy com.junkbyte.console.Cc#remoting
     */
    public var remoting(get, set):Bool;
    public function get_remoting():Bool {
        return _remoter.remoting == Remoting.SENDER;
    }
    public function set_remoting(b:Bool):Bool {
        _remoter.remoting = b?Remoting.SENDER:Remoting.NONE;
        return b;
    }

    /**
     * @copy com.junkbyte.console.Cc#remotingSocket()
     */
    public function remotingSocket(host:String, port:Int):Void {
        _remoter.remotingSocket(host, port);
    }
    //
    //
    //

    /**
     * @copy com.junkbyte.console.Cc#setViewingChannels()
     */

    //TODO: Warning Modified arguement, ...channels:Array => channels:Array<Dynamic>
    public function setViewingChannels(channels:Array<Dynamic>):Void {
        //_panels.mainPanel.setViewingChannels.apply(this, channels);
        //TODO: implement required

        _panels.mainPanel.setViewingChannels(channels);
    }

    /**
		 * @copy com.junkbyte.console.Cc#setIgnoredChannels()
		 */
    //TODO: Warning Modified arguement, ...channels:Array => channels:Array<Dynamic>
    public function setIgnoredChannels(channels:Array<Dynamic>):Void {
        //_panels.mainPanel.setIgnoredChannels.apply(this, channels);
        //TODO: implement required
        _panels.mainPanel.setIgnoredChannels(channels);
    }

    /**
		 * @copy com.junkbyte.console.Cc#minimumPriority
		 */
    public var minimumPriority(never, set):UInt;
    public function set_minimumPriority(level:UInt):UInt{
        _panels.mainPanel.priority = level;
        return level;
    }

    public function report(obj:Dynamic, priority:Int = 0, skipSafe:Bool = true, channel:String = null):Void {
        if(channel == null)
            channel = _panels.mainPanel.reportChannel;
        addLine([obj], priority, channel, false, skipSafe, 0);
    }

    public function addLine(strings:Array<Dynamic>, priority:Int = 0, channel:Dynamic = null,isRepeating:Bool = false, html:Bool = false, stacks:Int = -1):Void {
        var txt:String = "";
        var len:Int = strings.length;
        for(i in 0...len){
            txt += (i != 0?" ":"")+_refs.makeString(strings[i], null, html);
        }

        if(priority >= _config.autoStackPriority && stacks<0) stacks = _config.defaultStackDepth;

        if(!html && stacks>0){
            txt += _tools.getStack(stacks, priority);
        }
        _logs.add(new Log(txt, MakeChannelName(channel), priority, isRepeating, html));
    }
    //
    // COMMAND LINE
    //

    /**
		 * @copy com.junkbyte.console.Cc#commandLine
		 */
    public var commandLine(get, set):Bool;
    public function set_commandLine(b:Bool):Bool{
        _panels.mainPanel.commandLine = b;
        return b;
    }
    public function get_commandLine ():Bool{
        return _panels.mainPanel.commandLine;
    }

    /**
     * @copy com.junkbyte.console.Cc#addSlashCommand()
     */
    public function addSlashCommand(name:String, callback:Function, desc:String = "", alwaysAvailable:Bool = true, endOfArgsMarker:String = ";"):Void {
        _cl.addSlashCommand(name, callback, desc, alwaysAvailable, endOfArgsMarker);
    }
    //
    // LOGGING
    //

    /**
     * @copy com.junkbyte.console.Cc#add()
     */
    public function add(string:Dynamic, priority:Int = 2, isRepeating:Bool = false):Void {
        addLine([string], priority, DEFAULT_CHANNEL, isRepeating);
    }

    /**
     * @copy com.junkbyte.console.Cc#stack()
     */
    public function stack(string:Dynamic, depth:Int = -1, priority:Int = 5):Void {
        addLine([string], priority, DEFAULT_CHANNEL, false, false, depth>=0?depth:_config.defaultStackDepth);
    }

    /**
		 * @copy com.junkbyte.console.Cc#stackch()
		 */
    public function stackch(channel:Dynamic, string:Dynamic, depth:Int = -1, priority:Int = 5):Void {
        addLine([string], priority, channel, false, false, depth>=0?depth:_config.defaultStackDepth);
    }


    /**
     * @copy com.junkbyte.console.Cc#log()
     */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function log(strings:Array<Dynamic>):Void {
        addLine(strings, LOG);
    }

    /**
     * @copy com.junkbyte.console.Cc#info()
     */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function info(strings:Array<Dynamic>):Void {
        addLine(strings, INFO);
    }

    /**
     * @copy com.junkbyte.console.Cc#debug()
     */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function debug(strings:Array<Dynamic>):Void {
        addLine(strings, DEBUG);
    }

    /**
     * @copy com.junkbyte.console.Cc#warn()
     */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function warn(strings:Array<Dynamic>):Void {
        addLine(strings, WARN);
    }

    /**
     * @copy com.junkbyte.console.Cc#error()
     */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function error(strings:Array<Dynamic>):Void {
        addLine(strings, ERROR);
    }

    /**
     * @copy com.junkbyte.console.Cc#fatal()
     */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function fatal(strings:Array<Dynamic>):Void {
        addLine(strings, FATAL);
    }

    /**
     * @copy com.junkbyte.console.Cc#ch()
     */
    public function ch(channel:Dynamic, string:Dynamic, priority:Int = 2, isRepeating:Bool = false):Void {
        addLine([string], priority, channel, isRepeating);
    }

    /**
		 * @copy com.junkbyte.console.Cc#logch()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function logch(channel:Dynamic, strings:Array<Dynamic>):Void {
        addLine(strings, LOG, channel);
    }

    /**
		 * @copy com.junkbyte.console.Cc#infoch()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function infoch(channel:Dynamic, strings:Array<Dynamic>):Void {
        addLine(strings, INFO, channel);
    }

    /**
		 * @copy com.junkbyte.console.Cc#debugch()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function debugch(channel:Dynamic, strings:Array<Dynamic>):Void {
        addLine(strings, DEBUG, channel);
    }

    /**
		 * @copy com.junkbyte.console.Cc#warnch()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function warnch(channel:Dynamic, strings:Array<Dynamic>):Void {
        addLine(strings, WARN, channel);
    }

    /**
		 * @copy com.junkbyte.console.Cc#errorch()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function errorch(channel:Dynamic, strings:Array<Dynamic>):Void {
        addLine(strings, ERROR, channel);
    }

    /**
		 * @copy com.junkbyte.console.Cc#fatalch()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function fatalch(channel:Dynamic, strings:Array<Dynamic>):Void {
        addLine(strings, FATAL, channel);
    }

    /**
		 * @copy com.junkbyte.console.Cc#addCh()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<Dynamic>
    public function addCh(channel:Dynamic, strings:Array<Dynamic>, priority:Int = 2, isRepeating:Bool = false):Void{
        addLine(strings, priority, channel, isRepeating);
    }

    /**
		 * @copy com.junkbyte.console.Cc#addHTML()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<String>
    public function addHTML(strings:Array<String>):Void {
        addLine(strings, 2, DEFAULT_CHANNEL, false, testHTML(strings));
    }

    /**
		 * @copy com.junkbyte.console.Cc#addHTMLch()
		 */
    //TODO: Warning Modified arguement, ...strings => strings:Array<String>
    public function addHTMLch(channel:Dynamic, priority:Int, strings:Array<String>):Void {
        addLine(strings, priority, channel, false, testHTML(strings));
    }

    private function testHTML(args:Array<String>):Bool{
        try{
            //new XML("<p>"+args.join("")+"</p>"); // OR use RegExp?
            //TODO: implement required
        }catch(err:Error){
            return false;
        }
        return true;
    }
    //
    //
    //

    /**
     * @copy com.junkbyte.console.Cc#clear()
     */
    public function clear(channel:String = null):Void {
        _logs.clear(channel);
        if(!_paused) _panels.mainPanel.updateToBottom();
        _panels.updateMenu();
    }

    /**
     * @copy com.junkbyte.console.Cc#getAllLog()
     */
    public function getAllLog(splitter:String = "\r\n"):String {
        return _logs.getLogsAsString(splitter);
    }

    /**
     * @copy com.junkbyte.console.Cc#config
     */
    public var config(get, never):ConsoleConfig;
    public function get_config():ConsoleConfig {
        return _config;
    }

    /**
		 * Get panels manager which give access to console panels.
		 */
    public var panels(get, never):PanelsManager;
    public function get_panels():PanelsManager {
        return _panels;
    }

    /**
		 * @private
		 */
    public var cl(get, never):CommandLine;
    public function get_cl():CommandLine{
        return _cl;
    }
    /**
		 * @private
		 */
    public var remoter(get, never):Remoting;

    public function get_remoter():Remoting {
        return _remoter;
    }
    /**
		 * @private
		 */
    public var graphing(get, never):Graphing;
    public function get_graphing():Graphing {
        return _graphing;
    }
    /**
		 * @private
		 */
    public var refs(get, never):LogReferences;
    public function get_refs():LogReferences {
        return _refs;
    }
    /**
		 * @private
		 */
    public var logs(get, never):Logs;
    public function get_logs():Logs {
        return _logs;
    }
    /**
		 * @private
		 */
    public var mapper(get, never):ConsoleTools;
    public function get_mapper():ConsoleTools {
        return _tools;
    }

    /**
		 * @private
		 */
    public var so(get, never):Dynamic;
    public function get_so():Dynamic {
        return _soData;
    }
    /**
     * @private
     */
    public function updateSO(key:String = null):Void{
        if(_so != null) {
            if(key != null)
            {
                _so.setDirty(key);
                #if !flash
                _so.flush();
                #end
            }
            else
            {
                _so.clear();
            }
        }
    }
    //
    //
    //
    public static function MakeChannelName(obj:Dynamic):String{
        if(Std.is(obj, String)) return cast(obj, String);
        else if(obj) return LogReferences.ShortClassName(obj);
        return DEFAULT_CHANNEL;
    }
}