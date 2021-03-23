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
package com.junkbyte.console.core;

import Type.ValueType;
import openfl.errors.Error;
import openfl.utils.Function;
import openfl.utils.ByteArray;
import com.junkbyte.console.Console;
import com.junkbyte.console.vos.WeakObject;
import com.junkbyte.console.vos.WeakRef;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;

/**
	 * @private
	 */
class CommandLine extends ConsoleCore {

    private static inline var DISABLED:String = "<b>Advanced CommandLine is disabled.</b>\nEnable by setting `Cc.config.commandLineAllowed = true;´\nType <b>/commands</b> for permitted commands.";

    private static var RESERVED:Array<String> = [Executer.RETURNED, "base", "C"];

    private var _saved:WeakObject;

    private var _scope:Dynamic;
    private var _prevScope:WeakRef;
    private var _scopeStr:String = "";
    private var _slashCmds:Map<String, SlashCommand>;

    public var localCommands:Array<String> = ["filter", "filterexp"];

    public function new(m:Console) {
        super(m);
        _saved = new WeakObject();
        _scope = m;
        _slashCmds = new Map<String, SlashCommand>();
        _prevScope = new WeakRef(m);
        _saved.set("C", m);

        remoter.registerCallback("cmd", function(bytes:ByteArray):Void {
            run(bytes.readUTF());
        });
        remoter.registerCallback("scope", function(bytes:ByteArray):Void {
            handleScopeEvent(bytes.readUnsignedInt());
        });
        remoter.registerCallback("cls", handleScopeString);
        remoter.addEventListener(Event.CONNECT, sendCmdScope2Remote);

        addCLCmd("help", printHelp, "How to use command line");
        addCLCmd("save|store", saveCmd, "Save current scope as weak reference. (same as Cc.store(...))");
        addCLCmd("savestrong|storestrong", saveStrongCmd, "Save current scope as strong reference");
        addCLCmd("saved|stored", savedCmd, "Show a list of all saved references");
        addCLCmd("string", stringCmd, "Create String, useful to paste complex strings without worrying about \" or \'", false, null);
        addCLCmd("commands", cmdsCmd, "Show a list of all slash commands", true);
        addCLCmd("inspect", inspectCmd, "Inspect current scope");
        addCLCmd("explode", explodeCmd, "Explode current scope to its properties and values (similar to JSON)");
        addCLCmd("map", mapCmd, "Get display list map starting from current scope");
        addCLCmd("function", funCmd, "Create function. param is the commandline string to create as function. (experimental)");
        addCLCmd("autoscope", autoscopeCmd, "Toggle autoscoping.");
        addCLCmd("base", baseCmd, "Return to base scope");
        addCLCmd("/", prevCmd, "Return to previous scope");

    }

    public var base(get, set):Dynamic;

    public function set_base(obj:Dynamic):Dynamic {
        if (base) {
            report("Set new commandLine base from "+base+ " to "+ obj, 10);
        }else{
            _prevScope.reference = _scope;
            _scope = obj;
            _scopeStr = LogReferences.ShortClassName(obj, false);
        }
        _saved.set("base", obj);
        return obj;
    }

    public function get_base():Dynamic {
        return _saved.get("base");
    }

    public function handleScopeString(bytes:ByteArray):Void {
        _scopeStr = bytes.readUTF();
    }
    public function handleScopeEvent(id:UInt):Void{
        if(remoter.remoting == Remoting.RECIEVER){
            var bytes:ByteArray = new ByteArray();
            bytes.writeUnsignedInt(id);
            remoter.send("scope", bytes);
        }else{
            var v:Dynamic = console.refs.getRefById(id);
            if(v != null) console.cl.setReturned(v, true, false);
            else console.report("Reference no longer exist.", -2);
        }
    }

    public function store(n:String, obj:Dynamic, strong:Bool = false):Void {
        if(n == null) {
            report("ERROR: Give a name to save.",10);
            return;
        }
        // if it is a function it needs to be strong reference atm,
        // otherwise it fails if the function passed is from a dynamic class/instance
        if(Type.typeof(obj) == ValueType.TFunction) strong = true;
        //n = n.replace(/[^\w]*/g, "");
        //TODO: implement required
        if(RESERVED.indexOf(n)>=0){
            report("ERROR: The name ["+n+"] is reserved",10);
            return;
        }else{
            _saved.set(n, obj, strong);
        }
    }

    public function getHintsFor(str:String, max:Int):Array<Array<String>> {
        var all:Array<Array<String>> = new Array();

        //TODO: for (var X:String in _slashCmds){
        for (X in _slashCmds.keys()){
            var cmd:SlashCommand = _slashCmds[X];
            if(config.commandLineAllowed || cmd.allow)
                all.push(["/"+X+" ", cmd.d != null ? cmd.d : null]);
        }
        if(config.commandLineAllowed){
            /*for (var Y:String in _saved){
                all.push(["$"+Y, LogReferences.ShortClassName(_saved.get(Y))]);
            }*/
            //TODO: implement required
            if(_scope){
                all.push(["this", LogReferences.ShortClassName(_scope)]);
                //all = all.concat(console.refs.getPossibleCalls(_scope));
                //TODO: implement required
                all = all.concat([console.refs.getPossibleCalls(_scope)]);
            }
        }
        str = str.toLowerCase();
        var hints:Array<Array<String>> = new Array();
        //TODO: for each(var canadate:Array in all){
        for(canadate in all){
            if(canadate[0].toLowerCase().indexOf(str) == 0){
                hints.push(canadate);
            }
        }
        //TODO: hints = hints.sort(function(a:Array, b:Array):Int {
        hints.sort(function(a:Array<String>, b:Array<String>):Int {
            if(a[0].length < b[0].length) return -1;
            if(a[0].length > b[0].length) return 1;
            return 0;
        });
        if(max > 0 && hints.length > max){
            hints.splice(max, hints.length);
            hints.push(["..."]);
        }
        return hints;
    }

    public var scopeString(get, never):String;
    public function get_scopeString():String{
        return config.commandLineAllowed?_scopeStr:"";
    }

    public function addCLCmd(n:String, callback:Function, desc:String, allow:Bool = false, endOfArgsMarker:String = ";"):Void {
        var split:Array<String> = n.split("|");
        for(i in 0...split.length){
            n = split[i];
            _slashCmds[n] = new SlashCommand(n, callback, desc, false, allow, endOfArgsMarker);
            //if(i>0) _slashCmds.setPropertyIsEnumerable(n, false);
            //TODO: implement required
        }
    }

    public function addSlashCommand(n:String, callback:Function, desc:String = "", alwaysAvailable:Bool = true, endOfArgsMarker:String = ";"):Void {
        //n = n.replace(/[^\w]*/g, "");
        //TODO: implement required
        if(_slashCmds[n] != null){
            var prev:SlashCommand = _slashCmds[n];
            if(!prev.user) {
                throw new Error("Can not alter build-in slash command ["+n+"]");
            }
        }
        if(callback == null)
        {
            _slashCmds.remove(n);
        }else{
            _slashCmds[n] = new SlashCommand(n, callback, LogReferences.EscHTML(desc), true, alwaysAvailable, endOfArgsMarker);
        }
    }

    public function run(str:String, saves:Dynamic = null):Dynamic {
        if(str == null) return null;
        //str = str.replace(/\s*/,"");
        //TODO: implement required
        if(remoter.remoting == Remoting.RECIEVER){
            if(str.charAt(0) == "~"){
                str = str.substring(1);
            //}else if(str.search(new RegExp("\/"+localCommands.join("|\/"))) != 0){
            //TODO: implement required
            }else if(false){
                report("Run command at remote: "+str,-2);

                var bytes:ByteArray = new ByteArray();
                bytes.writeUTF(str);
                if(!console.remoter.send("cmd", bytes)){
                    report("Command could not be sent to client.", 10);
                }
                return null;
            }
        }
        report("&gt; "+str, 4, false);
        var v:Dynamic = null;
        try{
            if(str.charAt(0) == "/"){
                execCommand(str.substring(1));
            }else{
                if(!config.commandLineAllowed) {
                    report(DISABLED, 9);
                    return null;
                }
                var exe:Executer = new Executer();
                exe.addEventListener(Event.COMPLETE, onExecLineComplete, false, 0, true);
                if(saves != null){
                    /*for(X in _saved){
                        if(!saves[X]) saves[X] = _saved[X];
                    }*/
                    //TODO: implement reqired
                }else{
                    //TODO: cast
                    saves = cast _saved;
                }
                exe.setStored(saves);
                exe.setReserved(RESERVED);
                exe.autoScope = config.commandLineAutoScope;
                v = exe.exec(_scope, str);
            }
        }catch(e:Error){
            reportError(e);
        }
        return v;
    }

    private function onExecLineComplete(e:Event):Void {
        var exe:Executer = cast(e.currentTarget, Executer);
        if(_scope == exe.scope) setReturned(exe.returned);
        else if(exe.scope == exe.returned) setReturned(exe.scope, true);
        else {
            setReturned(exe.returned);
            setReturned(exe.scope, true);
        }
    }

    private function execCommand(str:String):Void {
        //var brk:Int = str.search(/[^\w]/);
        //TODO: implement required

        throw "implement required";

        var brk:Int = 0;
        var cmd:String = str.substring(0, brk>0?brk:str.length);
        if(cmd == ""){
            setReturned(_saved.get(Executer.RETURNED), true);
            return;
        }
        var param:String = brk>0?str.substring(brk+1):"";
        if(_slashCmds[cmd] != null){
            try{
                var slashcmd:SlashCommand = _slashCmds[cmd];
                if(!config.commandLineAllowed && !slashcmd.allow)
                {
                    report(DISABLED, 9);
                    return;
                }
                var restStr:String = null;
                if(slashcmd.endMarker != null){
                    var endInd:Int = param.indexOf(slashcmd.endMarker);
                    if(endInd >= 0){
                        restStr = param.substring(endInd+slashcmd.endMarker.length);
                        param = param.substring(0, endInd);
                    }
                }
                if(param.length == 0){
                    slashcmd.f();
                } else {
                    slashcmd.f(param);
                }
                if(restStr != null){
                    run(restStr);
                }
            }catch(err:Error){
                reportError(err);
            }
        } else{
            report("Undefined command <b>/commands</b> for list of all commands.",10);
        }
    }

    public function setReturned(returned:Dynamic, changeScope:Bool = false, say:Bool = true):Void {
        if(!config.commandLineAllowed) {
            report(DISABLED, 9);
            return;
        }

        if(returned != null)
        {
            _saved.set(Executer.RETURNED, returned, true);
            if(changeScope && returned != _scope){
                // scope changed
                _prevScope.reference = _scope;
                _scope = returned;
                if(remoter.remoting != Remoting.RECIEVER){
                    _scopeStr = LogReferences.ShortClassName(_scope, false);
                    sendCmdScope2Remote();
                }
                report("Changed to "+console.refs.makeRefTyped(returned), -1);
            }else{
                if(say) report("Returned "+console.refs.makeString(returned), -1);
            }
        }else{
            if(say) report("Exec successful, undefined return.", -1);
        }
    }

    public function sendCmdScope2Remote(e:Event = null):Void {
        var bytes:ByteArray = new ByteArray();
        bytes.writeUTF(_scopeStr);
        console.remoter.send("cls", bytes);
    }

    private function reportError(e:Error):Void {
        var str:String = console.refs.makeString(e);
        //var lines:Array<String> = str.split(/\n\s*/);
        //TODO: implement required

        var lines:Array<String> = [];
        var p:Int = 10;
        var internalerrs:Int = 0;
        var len:Int = lines.length;
        var parts:Array<String> = [];
        //var reg:RegExp = new RegExp("\\s*at\\s+("+Executer.CLASSES+"|"+openfl.Lib.getQualifiedClassName(this)+")");
        //TODO: implement required
        for (i in 0...len){
            var line:String = lines[i];
            //if(line.search(reg) == 0)
            //TODO: implement required
            if(false)
            {
                // don't trace more than one internal errors :)
                if(internalerrs>0 && i > 0) {
                    break;
                }
                internalerrs++;
            }
            parts.push("<p"+p+"> "+line+"</p"+p+">");
            if(p>6) p--;
        }
        report(parts.join("\n"), 9);
    }

    private function saveCmd(param:String = null):Void {
        store(param, _scope, false);
    }

    private function saveStrongCmd(param:String = null):Void {
        store(param, _scope, true);
    }

    //TODO: Warning Modified arguement, ...args => args:Array<Dynamic>
    private function savedCmd(args:Array<Dynamic>):Void {
        report("Saved vars: ", -1);
        var sii:UInt = 0;
        var sii2:UInt = 0;
        /*for(X in _saved){
            var ref:WeakRef = _saved.getWeakRef(X);
            sii++;
            if(ref.reference==null) sii2++;
            report((ref.strong?"strong":"weak")+" <b>$"+X+"</b> = "+console.refs.makeString(ref.reference), -2);
        }*/
        //TODO: implement required
        report("Found "+sii+" item(s), "+sii2+" empty.", -1);
    }

    private function stringCmd(param:String):Void {
        report("String with "+param.length+" chars entered. Use /save <i>(name)</i> to save.", -2);
        setReturned(param, true);
    }

    //TODO: Warning Modified arguement, ...args => args:Array<Dynamic>
    private function cmdsCmd(args:Array<Dynamic>):Void {
        var buildin:Array<SlashCommand> = [];
        var custom:Array<SlashCommand> = [];
        for(cmd in _slashCmds){
            if(config.commandLineAllowed || cmd.allow){
                if(cmd.user) custom.push(cmd);
                else buildin.push(cmd);
            }
        }
        //buildin = buildin.sortOn("n");
        //TODO: implement required
        report("Built-in commands:"+(!config.commandLineAllowed?" (limited permission)":""), 4);
        for(cmd in buildin){
            report("<b>/"+cmd.n+"</b> <p-1>" + cmd.d+"</p-1>", -2);
        }
        if(custom.length != 0){
            //custom = custom.sortOn("n");
            //TODO: implement required
            report("User commands:", 4);
            for (cmd in custom){
                report("<b>/"+cmd.n+"</b> <p-1>" + cmd.d+"</p-1>", -2);
            }
        }
    }

    //TODO: Warning Modified arguement, ...args:Array => args:Array<Dynamic>
    private function inspectCmd(args:Array<Dynamic>):Void {
        console.refs.focus(_scope);
    }

    private function explodeCmd(param:String = "0"):Void {
        var depth:Int = Std.parseInt(param);
        console.explodech(console.panels.mainPanel.reportChannel, _scope, depth<=0?3:depth);
    }

    private function mapCmd(param:String = "0"):Void {
        console.mapch(console.panels.mainPanel.reportChannel, cast(_scope, DisplayObjectContainer), Std.parseInt(param));
    }

    private function funCmd(param:String = ""):Void {
        var fakeFunction:FakeFunction = new FakeFunction(run, param);
        report("Function created. Use /savestrong <i>(name)</i> to save.", -2);
        setReturned(fakeFunction.exec, true);
    }

    //TODO: Warning Modified arguement, ...args:Array => args:Array<Dynamic>
    private function autoscopeCmd(args:Array<Dynamic>):Void {
        config.commandLineAutoScope = !config.commandLineAutoScope;
        report("Auto-scoping <b>"+(config.commandLineAutoScope?"enabled":"disabled")+"</b>.",10);
    }

    //TODO: Warning Modified arguement, ...args:Array => args:Array<Dynamic>
    private function baseCmd(args:Array<Dynamic>):Void {
        setReturned(base, true);
    }

    //TODO: Warning Modified arguement, ...args:Array => args:Array<Dynamic>
    private function prevCmd(args:Array<Dynamic>):Void {
        setReturned(_prevScope.reference, true);
    }

    //TODO: Warning Modified arguement, ...args:Array => args:Array<Dynamic>
    private function printHelp(args:Array<Dynamic>):Void {
        report("____Command Line Help___",10);
        report("/filter (text) = filter/search logs for matching text",5);
        report("/commands to see all slash commands",5);
        report("Press up/down arrow keys to recall previous line",2);
        report("__Examples:",10);
        report("<b>stage.stageWidth</b>",5);
        report("<b>stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE</b>",5);
        report("<b>stage.frameRate = 12</b>",5);
        report("__________",10);
    }
}

class FakeFunction {
    private var line:String;
    private var run:Function;
    public function new(r:Function, l:String):Void
    {
        run = r;
        line = l;
    }
    //TODO: Warning Modified arguement, ...args => args:Array<Dynamic>
    public function exec(args:Array<Dynamic>):Dynamic
    {
        return run(line, args);
    }
}

class SlashCommand {
    public var n:String;
    public var f:Function;
    public var d:String;
    public var user:Bool;
    public var allow:Bool;
    public var endMarker:String;
    public function new(nn:String, ff:Function, dd:String, cus:Bool, permit:Bool, argsMarker:String) {
        n = nn;
        f = ff;
        d = dd != null ? dd : "";
        user = cus;
        allow = permit;
        endMarker = argsMarker;
    }
}