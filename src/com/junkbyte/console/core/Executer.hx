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

import haxe.rtti.CType.ClassField;
import haxe.Json;
import com.junkbyte.console.utils.FlashRegex;
import Type.ValueType;
import openfl.utils.Function;
import openfl.errors.Error;
import com.junkbyte.console.vos.WeakObject;
import openfl.events.Event;
import openfl.events.EventDispatcher;

/**
 * @private
 */
class Executer extends EventDispatcher{

    public static inline var RETURNED:String = "returned";
    public static inline var CLASSES:String = "ExeValue|((com.junkbyte.console.core::)?Executer)";

    public static function Exec(scope:Dynamic, str:String, saved:Dynamic = null):Dynamic{
        var e:Executer = new Executer();
        e.setStored(saved);
        return e.exec(scope, str);
    }


    private static inline var VALKEY:String = "#";

    //TODO: values? i have no idea?
    private var _values:Array<Dynamic>;
    private var _running:Bool;
    private var _scope:Dynamic;
    private var _returned:Dynamic;

    private var _saved:Dynamic;
    private var _reserved:Array<String>;

    public var autoScope:Bool;

    public var returned(get, never):Dynamic;
    public function get_returned():Dynamic {
        return _returned;
    }

    public var scope(get, never):Dynamic;
    public function get_scope():Dynamic {
        return _scope;
    }

    public function setStored(o:Dynamic):Void {
        _saved = o;
    }
    public function setReserved(a:Array<String>):Void {
        _reserved = a;
    }

    // TEST CASES...
    // com.junkbyte.console.Cc.instance.visible
    // com.junkbyte.console.Cc.instance.addGraph('test',stage,'mouseX')
    // trace('simple stuff. what ya think?');
    // $C.error('He\'s cool! (not really)','',"yet 'another string', what ya think?");
    // this.getChildAt(0);
    // stage.addChild(root.addChild(this.getChildAt(0)));
    // getChildByName(new String('Console')).getChildByName('mainPanel').alpha = 0.5
    // com.junkbyte.console.Cc.add('Hey how are you?');
    // new Array(11,22,33,44,55,66,77,88,99).1 // should return 22
    // new Array(11,22,33,44,55,66,77,88,99);/;1 // should be 1
    // new Array(11,22,33,44,55,66,77,88,99);/;this.1 // should be 22
    // new XML("<t a=\"A\"><b>B</b></t>").attribute("a")
    // new XML("<t a=\"A\"><b>B</b></t>").b
    public function exec(s:Dynamic, str:String):Dynamic{
        if(_running) throw new Error("CommandExec.exec() is already runnnig. Does not support loop backs.");
        _running = true;
        _scope = s;
        _values = [];
        if(_saved == null) _saved = {};
        if(_reserved == null) _reserved = new Array();
        try{
            _exec(str);
        }catch (e:Error){
            reset();
            throw e;
        }
        reset();
        return _returned;
    }

    private function reset():Void {
        _saved = null;
        _reserved = null;
        _values = null;
        _running = false;
    }

    private function _exec(str:String):Void {
        //
        // STRIP strings - '...', "...", '', "", while ignoring \' \" etc inside.
        var strReg:EReg = new EReg("''|\"\"|('(.*?)[^\\\\]')|(\"(.*?)[^\\\\]\")", "");
        var result = FlashRegex.exec(str, strReg);
        while(result != null){
            var match:String = result.elements[0];
            var quote:String = match.charAt(0);
            var start:Int = match.indexOf(quote);
            var end:Int = match.lastIndexOf(quote);
            var string:String = FlashRegex.replace(match.substring(start+1,end), ~/\\(.)/g, "$1");
            //trace(VALUE_CONST+_values.length+" = "+string);
            str = tempValue(str,new ExeValue(string), result.index+start, result.index+end+1);
            //trace(str);
            result = FlashRegex.exec(str, strReg);
        }
        //
        // All strings will have replaced by #0, #1, etc
        if(FlashRegex.search(str, new EReg('\'|\"', ''))>=0)
        {
            throw new Error('Bad syntax extra quotation marks');
        }
        //
        // Run each line
        var lineBreaks:Array<String> = FlashRegex.split(str, ~/\s*;\s*/);
        for(line in lineBreaks){
            if(line.length != 0){
                var returned = Reflect.field(_saved, RETURNED);
                if(returned != null && line == "/"){
                    _scope = returned;
                    dispatchEvent(new Event(Event.COMPLETE));
                }else{
                    execNest(line);
                }
            }
        }
    }
    //
    // Nested strip
    // aaa.bbb(1/2,ccc(dd().ee)).ddd = fff+$g.hhh();
    //
    private function execNest(line:String):Dynamic {
        // exec values inside () - including functions and groups.
        line = ignoreWhite(line);
        var indOpen:Int = line.lastIndexOf("(");
        while(indOpen>=0){
            var firstClose:Int = line.indexOf(")", indOpen);
            //if there is params...
            if(FlashRegex.search(line.substring(indOpen+1, firstClose), ~/\w/)>=0){
                // increment closing if there r more opening inside
                var indopen2:Int = indOpen;
                var indClose:Int = indOpen+1;
                while(indopen2>=0 && indopen2<indClose){
                    indopen2++;
                    indopen2 = line.indexOf("(",indopen2);
                    indClose = line.indexOf(")",indClose+1);
                }
                //
                var inside:String = line.substring(indOpen+1, indClose);
                // must be a better way to see if its letter/digit or not :/
                var isfun:Bool = false;
                var fi:Int = indOpen-1;
                while(true)
                {
                    var char:String = line.charAt(fi);
                    if(FlashRegex.match(char, ~/[^\s]/) || fi<=0) {
                        if(FlashRegex.match(char, ~/\w/))
                            isfun = true;
                        break;
                    }
                    fi--;
                }
                if(isfun){
                    var params:Array<Dynamic> = inside.split(",");
                    //trace("#"+_values.length+" stores function params ["+params+"]");
                    line = tempValue(line, new ExeValue(params), indOpen+1, indClose);
                    var tempArray = [];

                    for(X in params){
                        tempArray.push(execOperations(ignoreWhite(X)).value);
                    }

                    params.splice(0, params.length);

                    for(value in tempArray)
                    {
                        params.push(value);
                    }

                }else{
                    var groupv:ExeValue = new ExeValue();
                    //trace("#"+_values.length+" stores group value for "+inside);
                    line = tempValue(line, groupv, indOpen, indClose+1);
                    groupv.setValue(execOperations(ignoreWhite(inside)).value);
                }
            }
            indOpen = line.lastIndexOf("(", indOpen-1);
        }
        _returned = execOperations(line).value;
        if(_returned != null && autoScope){
            /*var typ:String = typeof(_returned);
            if(typ == "object" || typ=="xml")*/
            //TODO: implement required
            var typ = Type.typeof(_returned);
            if(typ == ValueType.TObject)
            {
                trace("setScope");
                _scope = _returned;
            }
        }
        dispatchEvent(new Event(Event.COMPLETE));
        return _returned;
    }

    private function tempValue(str:String, v:Dynamic, indOpen:Int, indClose:Int):String {
        //trace("tempValue", VALUE_CONST+_values.length, " = "+str);
        str = str.substring(0,indOpen)+VALKEY+_values.length+str.substring(indClose);

        _values.push(v);
        return str;
    }
    //
    // Simple strip with operations.
    // aaa.bbb.ccc(1/2,3).ddd += fff+$g.hhh();
    //
    private function execOperations(str:String):ExeValue {
        trace("execOperations: " + str);
        var reg:EReg = new EReg('\\s*(((\\|\\||\\&\\&|[+|\\-|*|\\/|\\%|\\||\\&|\\^]|\\=\\=?|\\!\\=|\\>\\>?\\>?|\\<\\<?)\\=?)|=|\\~|\\sis\\s|typeof|delete\\s)\\s*', 'g');
        var result = FlashRegex.exec(str, reg);
        var seq:Array<Dynamic> = [];
        if(result == null){
            seq.push(str);
        }else{
            var lastindex:Int = 0;
            while(result != null) {
                var index:Int = result.index;
                var operation:String = result.elements[0];
                trace("operation: " + operation);
                trace("index: " + index);
                result = FlashRegex.exec(str, reg, index);
                if(result==null)
                {
                    seq.push(str.substring(lastindex, index));
                    seq.push(ignoreWhite(operation));
                    seq.push(str.substring(index+operation.length));
                }else{
                    seq.push(str.substring(lastindex, index));
                    seq.push(ignoreWhite(operation));
                    lastindex = index+operation.length;
                }
            }
        }
        //trace("execOperations: "+seq);
        // EXEC values in sequence fisrt

        var len:Int = seq.length;
        var i:Int = 0;
        while(i<len)
        {
            seq[i] = execSimple(seq[i]);
            i+=2;
        }
        var op:String;
        var res:Dynamic;
        var setter:EReg = new EReg("((\\|\\||\\&\\&|[+|\\-|*|\\/|\\%|\\||\\&|\\^]|\\>\\>\\>?|\\<\\<)\\=)|=", "");
        // EXEC math operations
        var i:Int = 1;
        while(i<len)
        {
            op = seq[i];
            if(FlashRegex.replace(op, setter,"") != "") {
                res = operate(seq[i-1], op, seq[i+1]);
                //debug("operate: "+seq[i-1].value, op, seq[i+1].value, "=", res);
                var sv:ExeValue = cast(seq[i-1], ExeValue);
                sv.setValue(res);
                seq.splice(i,2);
                i-=2;
                len-=2;
            }
            i+=2;
        }
        // EXEC setter operations after reversing the sequence
        seq.reverse();
        var v:ExeValue = seq[0];
        var i:Int = 1;
        while(i<len)
        {
            op = seq[i];
            if(FlashRegex.replace(op, setter,"")==""){
                v = seq[i-1];
                var subject:ExeValue = seq[i+1];
                if(op.length>1)
                    op = op.substring(0,op.length-1);
                res = operate(subject, op, v);
                subject.setValue(res);
            }
            i+=2;
        }
        return v;
    }
    //
    // Simple strip
    // aaa.bbb.ccc(0.5,3).ddd
    // includes class path detection and 'new' operation
    //
    private function execSimple(str:String):ExeValue{
        trace("execSimple: " + str);

        var v:ExeValue = new ExeValue(_scope);
        //debug('execStrip: '+str);
        //
        // if it is 'new' operation
        if(str.indexOf("new ")==0){
            var newstr:String = str;
            var defclose:Int = str.indexOf(")");
            if(defclose>=0){
                newstr = str.substring(0, defclose+1);
            }
            var newobj:Dynamic = makeNew(newstr.substring(4));
            str = tempValue(str, new ExeValue(newobj), 0, newstr.length);
        }
        //
        //
        var reg:EReg = ~/\.|\(/g;
        var result:Dynamic = FlashRegex.exec(str, reg);
        if(result == null || !Math.isNaN(Std.parseFloat(str))){
            trace("execValue");
            return execValue(str, _scope);
        }
        //
        // AUTOMATICALLY detect classes in packages
        var firstparts:Array<String> = str.split("(")[0].split(".");
        if(firstparts.length>0){
            while(firstparts.length != 0){
                var classstr:String = firstparts.join(".");
                try{
                    var def:Dynamic = openfl.Lib.getDefinitionByName(ignoreWhite(classstr));

                    if(def == null)
                    {
                        throw "";
                    }

                    //trace("classstr: " + classstr);
                    //trace("ignoreWhite(classstr): " + ignoreWhite(classstr));
                    var havemore:Bool = str.length > classstr.length;
                    //trace(classstr+" is a definition:", def);
                    //trace("before tempValue: " + str);
                    str = tempValue(str, new ExeValue(def), 0, classstr.length);
                    //trace("after tempValue: " + str);
                    //trace(str);
                    if(havemore){
                        result = cast FlashRegex.exec(str, reg, 0);
                    }else{
                        return execValue(str);
                    }
                    break;
                }catch(e){
                    firstparts.pop();
                }
            }
        }
        //
        // dot syntex and simple function steps
        var previndex:Int = 0;
        var lastIndex:Int = 0;
        var index:Int = result.index;
        while(result != null)
        {
            var index:Int = result.index;
            var isFun:Bool = str.charAt(index)=="(";
            trace("isFun: " + isFun);
            var basestr:String = ignoreWhite(str.substring(previndex, index));
            //trace("_scopestr = "+basestr+ " v.base = "+v.value);
            var newv:ExeValue = previndex==0?execValue(basestr, v.value):new ExeValue(v.value, basestr);
            //trace("_scope = "+newv.value+"  isFun:"+isFun);
            if(isFun)
            {
                var newbase:Dynamic = newv.value;
                trace("newbase: " + newbase);
                trace("newbase string: " + str);

                var closeindex:Int = str.indexOf(")", index);
                var paramstr:String = str.substring(index+1, closeindex);
                paramstr = ignoreWhite(paramstr);
                var params:Array<Dynamic> = [];
                if(paramstr != null){
                    params = cast execValue(paramstr).value;
                }

                //debug("params = "+params.length+" - ["+ params+"]");
                // this is because methods in stuff like XML/XMLList got AS3 namespace.
                if(!(Reflect.isFunction(newbase)))
                {
                    /*try{
                        var nss:Array<Namespace> = [AS3];
                        for(ns in nss){
                            var nsv:Dynamic = v.obj.ns::[basestr];
                            if(Std.isOfType(nsv, Function)){
                                newbase = nsv;
                                break;
                            }
                        }
                    }catch(e:Error){
                        // Will throw below...
                    }*/
                    //TODO: implement required
                    if(!(Reflect.isFunction(newbase))) {
                        throw new Error(basestr+" is not a function.");
                    }
                }
                //trace("Apply function:", newbase, v.base, params);
                v.obj = Reflect.callMethod(v.value, newbase, params);
                v.prop = null;
                //trace("Function return:", v.base);
                index = closeindex+1;
            }else{
                v = newv;
            }
            previndex = index+1;
            lastIndex = index+1;
            result = cast FlashRegex.exec(str, reg, lastIndex);
            if(result != null)
            {
                //v.base = v.value;
            }else if(index+1 < str.length){
                //v.base = v.value;
                lastIndex = str.length;
                result = {index:str.length};
            }
        }

        return v;
    }

    public static function resolveAllFields(resolveClass:Class<Dynamic>):Dynamic
    {
        var items:Dynamic = {};
        items.staticVariables = new Array<Dynamic>();
        items.staticFunctions = new Array<Dynamic>();
        items.variables = new Array<Dynamic>();
        items.functions = new Array<Dynamic>();
        items.superClasses = new Array<String>();


        if(!haxe.rtti.Rtti.hasRtti(resolveClass))
        {
            trace("rtti not found!");
            return null;
        }

        var rtti = haxe.rtti.Rtti.getRtti(resolveClass);

        while(rtti != null && haxe.rtti.Rtti.hasRtti(resolveClass))
        {
            for(fieldType in [rtti.statics, rtti.fields])
            {
                var fields:Array<Dynamic> = cast fieldType;
                for(field in fields)
                {
                    if(field.name == "new")
                        continue;
                    var item:Dynamic = {};
                    var isFunction:Bool = Reflect.hasField(field.type, "args");
                    var isStatic:Bool = fields == rtti.statics;
                    var type:String = "Dynamic";

                    item.name = field.name;
                    item.isFunction = isFunction;
                    item.isPublic = field.isPublic;
                    item.isFinal = field.isFinal;
                    item.isOverride = field.isOverride;
                    item.isStatic = isStatic;

                    if(isFunction)
                    {
                        var variables:Map<String, {
                            type:String,
                            optional:Bool,
                            value:Dynamic
                        }> = new Map();
                        var name:String = "";
                        var type:String = "Dynamic";
                        var args:Array<Dynamic> = cast field.type.args;
                        for(i in 0...args.length)
                        {
                            var arg:Dynamic = args[i];

                            //trace("args: " + arg);
                            var variableType:String = "";
                            if(arg.name != null)
                            {
                                var params:Array<Dynamic> = null;
                                name = arg.name;

                                if(arg.t.params != null)
                                {
                                    params = arg.t.params;
                                    variableType = arg.t.name;
                                }

                                if(arg.params != null)
                                {
                                    params = arg.params;
                                }

                                if(params != null && params.length > 0)
                                {
                                    variableType += "<";
                                    for(i in 0...params.length)
                                    {
                                        var paramType:String = params[i].name;
                                        if(paramType == null)
                                        {
                                            paramType = "Dynamic";
                                        }
                                        if(i == 0)
                                        {
                                            variableType += paramType;
                                        }else{
                                            variableType += ", " + paramType;
                                        }
                                    }
                                    variableType += ">";
                                }
                            }

                            variables.set(name, {
                                type: variableType,
                                optional: arg.opt,
                                value: arg.value != null ? arg.value : null
                            });

                            if(field.type.ret.name != null)
                            {
                                type = field.type.ret.name;
                                var params:Array<Dynamic> = field.type.ret.params;
                                if(params != null && params.length > 0)
                                {

                                    type += "<";
                                    for(i in 0...params.length)
                                    {
                                        var param = params[i];
                                        var variableType:String = param.name;
                                        if(variableType == null)
                                        {
                                            variableType = "Dynamic";
                                        }
                                        if(i == 0)
                                        {
                                            type += variableType;
                                        }else{
                                            type += ", " + variableType;
                                        }
                                    }
                                    type += ">";
                                }
                            }
                        }

                        item.variables = variables;
                    }else{
                        if(Reflect.hasField(field.type, "name"))
                        {
                            type = field.type.name; //Map
                        }


                        var params:Array<Dynamic> = field.type.params;
                        if(params != null && params.length > 0)
                        {
                            type += "<";
                            for(i in 0...field.type.params.length)
                            {
                                var param:Dynamic = field.type.params[i];
                                var variableType:String = param.name;
                                if(variableType == null)
                                {
                                    variableType = "Dynamic";
                                }
                                if(i == 0)
                                {
                                    type += variableType;
                                }else{
                                    type += ", " + variableType;
                                }
                            }
                            type += ">";
                        }
                    }

                    item.type = type;

                    if(isFunction)
                    {
                        if(isStatic)
                        {
                            items.staticFunctions.push(item);

                        }else{
                            items.functions.push(item);
                        }
                    }else{
                        if(isStatic)
                        {
                            items.staticVariables.push(item);
                        }else{
                            items.variables.push(item);
                        }
                    }
                }
            }

            if(rtti.superClass != null)
            {
                resolveClass = Type.resolveClass(rtti.superClass.path);
                if(resolveClass != null && haxe.rtti.Rtti.hasRtti(resolveClass))
                {
                    items.superClasses.push(rtti.superClass.path);
                    rtti = haxe.rtti.Rtti.getRtti(resolveClass);
                }else{
                    rtti = null;
                }

            }else{
                rtti = null;
            }
        }


        return items;
    }

    //
    // single values such as string, int, null, $a, ^1 and Classes without package.
    //
    private function execValue(str:String, base:Dynamic = null):ExeValue{
        trace("execValueString: " + str);
        trace("execValueBase: " + base);
        var v:ExeValue = new ExeValue();
        if (str == "true") {
            v.obj = cast true;
        }else if (str == "false") {
            v.obj = cast false;
        }else if (str == "this") {
            v.obj = _scope;
        }else if (str == "null") {
            v.obj = null;
        }else if (!Math.isNaN(Std.parseFloat(str))) {
            v.obj = cast Std.parseFloat(str);
        }else if(str.indexOf(VALKEY)==0){
            var vv:ExeValue = _values[Std.parseInt(str.substring(VALKEY.length))];
            v.obj = vv.value;
        }else if(str.charAt(0) == "$"){
            var key:String = str.substring(1);
            if(_reserved.indexOf(key)<0){
                v.obj = _saved;
                v.prop = key;
            }else if(Std.isOfType(_saved, WeakObject)){
                v.obj = cast(_saved, WeakObject).get(key);
            }else {
                v.obj = Reflect.field(_saved, key);
            }
        }else{
            try{
                v.obj = cast openfl.Lib.getDefinitionByName(str);
                if(v.obj == null)
                {
                    throw "";
                }
            }catch(e){
                v.obj = base;
                v.prop = str;
            }
        }
        //debug("value: "+str+" = "+openfl.Lib.getQualifiedClassName(v.value)+" - "+v.value+" base:"+v.base);
        trace("v: " + v);
        return v;
    }
    // * typed cause it could be String +  OR comparison such as || or &&
    private function operate(v1:ExeValue, op:String, v2:ExeValue):Dynamic{
        switch (op){
            case "=":
                return v2.value;
            case "+":
                return v1.value+v2.value;
            case "-":
                return v1.value-v2.value;
            case "*":
                return v1.value*v2.value;
            case "/":
                return v1.value/v2.value;
            case "%":
                return v1.value%v2.value;
            case "^":
                return v1.value^v2.value;
            case "&":
                return v1.value&v2.value;
            case ">>":
                return v1.value>>v2.value;
            case ">>>":
                return v1.value>>>v2.value;
            case "<<":
                return v1.value<<v2.value;
            case "~":
                return ~v2.value;
            case "|":
                return v1.value|v2.value;
            case "!":
                return !v2.value;
            case ">":
                return v1.value>v2.value;
            case ">=":
                return v1.value>=v2.value;
            case "<":
                return v1.value<v2.value;
            case "<=":
                return v1.value<=v2.value;
            case "||":
                return v1.value||v2.value;
            case "&&":
                return v1.value&&v2.value;
            case "is":
                return Std.isOfType(v1.value, v2.value);
            case "typeof":
                return Type.typeof(v2.value);
            case "delete":
                return Reflect.deleteField(v2.obj, v2.prop);
            case "==":
                return v1.value==v2.value;
            case "===":
                return v1.value==v2.value;
            case "!=":
                return v1.value!=v2.value;
            case "!==":
                return v1.value!=v2.value;
        }
        return null;
    }
    //
    // make new instance
    //
    private function makeNew(str:String):Dynamic {
        //debug("makeNew "+str);
        var openindex:Int = str.indexOf("(");
        var defstr:String = openindex>0?str.substring(0, openindex):str;
        defstr = ignoreWhite(defstr);
        var def = execValue(defstr).value;
        if(openindex>0){
        var closeindex:Int = str.indexOf(")", openindex);
        var paramstr:String = str.substring(openindex+1, closeindex);
        paramstr = ignoreWhite(paramstr);
        var p:Array<Dynamic> = [];
        if(paramstr != null && paramstr != "") {
            p = execValue(paramstr).value;
        }
        var len:Int = p.length;
            //
            // HELP! how do you construct an object with unknown number of arguments?
            // calling a function with multiple arguments can be done by fun.apply()... but can't for constructor :(
            if(len==0){
                return Type.createInstance(def, []);
            }if(len==1){
                return Type.createInstance(def, [p[0]]);
            }else if(len==2){
                return Type.createInstance(def, [p[0], p[1]]);
            }else if(len==3){
                return Type.createInstance(def, [p[0], p[1], p[2]]);
            }else if(len==4){
                return Type.createInstance(def, [p[0], p[1], p[2], p[3]]);
            }else if(len==5){
                return Type.createInstance(def, [p[0], p[1], p[2], p[3], p[4]]);
            }else if(len==6){
                return Type.createInstance(def, [p[0], p[1], p[2], p[3], p[4], p[5]]);
            }else if(len==7){
                return Type.createInstance(def, [p[0], p[1], p[2], p[3], p[4], p[5], p[6]]);
            }else if(len==8){
                return Type.createInstance(def, [p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]]);
            }else if(len==9){
                return Type.createInstance(def, [p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]]);
            }else if(len==10){
                return Type.createInstance(def, [p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]]);
            }else {
                throw new Error("CommandLine can't create new class instances with more than 10 arguments.");
            }
            // won't work with more than 10 arguments...
        }
        return null;
    }

    private function ignoreWhite(str:String):String{
        // can't just do /\s*(.*?)\s*/  :(  any better way?
        str = FlashRegex.replace(str, ~/\s*(.*)/,"$1");
        var i:Int = str.length-1;
        while(i>0){
            if(FlashRegex.match(str.charAt(i), ~/\s/)) str = str.substring(0,i);
            else break;
            i--;
        }
        return str;
    }
}

class ExeValue{
    public var obj:Dynamic;
    public var prop:String;

    public function new(b:Dynamic = null, p:String = null):Void{
        obj = b;
        prop = p;
    }

    public var value(get, never):Dynamic;
    public function get_value():Dynamic{
        return prop != null?Reflect.field(obj, prop):obj;
    }
    public function setValue(v:Dynamic):Void{
        if(prop != null) Reflect.setField(obj, prop, v);
        else obj = v;
    }
}