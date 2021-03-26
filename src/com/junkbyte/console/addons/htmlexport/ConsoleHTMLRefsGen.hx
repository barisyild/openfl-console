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
package com.junkbyte.console.addons.htmlexport;
import com.junkbyte.console.utils.FlashRegex;
import openfl.errors.Error;
import openfl.xml.XML;
import com.junkbyte.console.Console;
import com.junkbyte.console.core.LogReferences;
import com.junkbyte.console.vos.Log;

import openfl.utils.describeType;

/**
	 * @private
	 */
class ConsoleHTMLRefsGen
{
    private static inline var refSearchExpression:EReg = ~/<a(\s+)href=\'event:ref_(\d+)\'>/g;

    private var console:Console;
    private var referencesDepth:UInt;
    private var referencesMap:Map<UInt, Dynamic>;

    public function new(console:Console, referencesDepth:UInt)
    {
        this.console = console;
        this.referencesDepth = referencesDepth;
    }

    public function fillData(data:Dynamic):Void
    {
        referencesMap = new Map();

        data.references = referencesMap;

        var line:Log = console.logs.last;
        while(line != null)
        {
            processRefIdsFromLine(line.text);
            line = line.prev;
        }
    }

    private function processRefIdsFromLine(line:String, currentDepth:UInt = 0):Void
    {
        var result = FlashRegex.exec(line, refSearchExpression);
        while(result != null)
        {
            var id:UInt = Std.parseInt(result.elements[2]);
            processRefId(id, currentDepth);
            result = FlashRegex.exec(line, refSearchExpression);
        }
    }

    private function processRefId(id:UInt, currentDepth:UInt):Void
    {
        var obj:Dynamic = console.refs.getRefById(id);
        if(obj != null && referencesMap[id] == null)
        {
            referencesMap[id] = processRef(obj, currentDepth);
        }
    }

    private function processRef(obj:Dynamic, currentDepth:UInt):Dynamic
    {
        // should reuse code from LogReference, but not possible atm. wait for modular version.

        var V:XML = describeType(obj);
        var cls:Dynamic = Std.is(obj, Class)?obj:obj.constructor;
        var clsV:XML = describeType(cls);

        var isClass:Bool = Std.is(obj, Class);

        var result:Dynamic = {};
        var isstatic:Bool;
        var targetObj:Dynamic;


        //result.name = LogReferences.EscHTML(V.@name);
        //TODO: implement required

        /*
			var properties:Object = new Object();
			result.properties = properties;
			properties.isStatic = V.@isDynamic=="true";
			properties.isDynamic = V.@isDynamic=="true";
			properties.isFinal = V.@isFinal=="true";
			*/
        //
        // constants
        //
        var constants:Dynamic = {};
        result.constants = constants;
        /*for(constantX in clsV..constant)
        {
            constants[constantX.@name.toString()] = makeValue(cls, constantX.@name.toString(), currentDepth);
        }*/
        //TODO: implement required
        //
        // accessors
        //
        var accessors:Dynamic = {};
        result.accessors = accessors;
        var staticAccessors:Dynamic = {};
        result.staticAccessors = staticAccessors;
        /*for (accessorX in clsV..accessor)
        {
            isstatic = accessorX.parent().name()!="factory";
            targetObj = isstatic ? staticAccessors : accessors;

            if(accessorX.@access.toString() != "writeonly" && (isstatic || !isClass))
            {
                targetObj[accessorX.@name] = makeValue(isstatic?cls:obj, accessorX.@name.toString(), currentDepth);
            }
        }*/
        //TODO: implement required

        //
        // variables
        //
        var variables:Dynamic = {};
        result.variables = variables;
        var staticVariables:Dynamic = {};
        result.staticVariables = staticVariables;
        /*for (variableX in clsV..variable)
        {
            isstatic = variableX.parent().name()!="factory";
            targetObj = isstatic ? staticVariables : variables;
            targetObj[variableX.@name] = makeValue(isstatic ? cls : obj, variableX.@name.toString(), currentDepth);
        }*/
        //TODO: implement required

        //
        // dynamic values
        // - It can sometimes fail if we are looking at proxy object which havnt extended nextNameIndex, nextName, etc.
        var dynamicVariables:Dynamic = {};
        result.dynamicVariables = dynamicVariables;
        try
        {
            for (X in obj)
            {
                Reflect.setField(dynamicVariables, X, makeValue(obj, X, currentDepth));
            }
        }
        catch(e : Error)
        {
            result.dynamicVariables = e.message;
        }

        return result;
    }

    private function makeValue(obj:Dynamic, prop:Dynamic, currentDepth:UInt):String
    {
        try
        {
            var v:Dynamic = obj[prop];
        }
        catch(err:Error)
        {
            return "<p0><i>"+err.toString()+"</i></p0>";
        }
        var string:String = console.refs.makeString(v, null, true);
        if(currentDepth < referencesDepth)
        {
            currentDepth++;
            processRefIdsFromLine(string, currentDepth);
        }
        return string;
    }

}