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
package com.junkbyte.console.addons.memoryRecorder;

import com.junkbyte.console.utils.FlashRegex;
import openfl.errors.Error;
import openfl.utils.Function;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.sampler.NewObjectSample;
import openfl.sampler.Sample;
import openfl.sampler.clearSamples;
import openfl.sampler.getSamples;
import openfl.sampler.pauseSampling;
import openfl.sampler.startSampling;
import openfl.system.System;
import openfl.utils.getDefinitionByName;

class MemoryRecorder extends EventDispatcher
{
    public static var instance:MemoryRecorder = new MemoryRecorder();

    private var _interestedClassExpressions:Array<Dynamic> = new Array();
    private var _ignoredClassExpressions:Array<Dynamic> = new Array();

    private var _started:Bool;

    private var startMemory:UInt;
    private var endMemory:UInt;
    private var startTimer:Int;
    private var endTimer:Int;

    private var ticker:Sprite;

    public var reportCallback:Function;

    public var ignoredClassExpressions(get, never):Array<Dynamic>;
    public function get_ignoredClassExpressions():Array<Dynamic>
    {
    return _ignoredClassExpressions;
    }

    public function addIgnoredClassExpression(expression:Dynamic):Void
    {
        _ignoredClassExpressions.push(expression);
    }

    public var interestedClassExpressions(get, never):Array<Dynamic>;
    public function get_interestedClassExpressions():Array<Dynamic>
    {
        return _interestedClassExpressions;
    }

    public function addInterestedClassExpression(expression:Dynamic):Void
    {
        _interestedClassExpressions.push(expression);
    }

    public var running(get, never):Bool;
    public function get_running():Bool
    {
        return _started || ticker != null;
    }

    public function start():Void
    {
        if (running)
        {
            return;
        }

        _started = true;

        startMemory = System.totalMemory;
        startTimer = openfl.Lib.getTimer();

        startSampling();
        clearSamples();
    }

    public function end():Void
    {
        if (!_started || ticker != null)
        {
            return;
        }

        pauseSampling();
        endMemory = System.totalMemory;
        endTimer = openfl.Lib.getTimer();

        System.gc();
        ticker = new Sprite();
        ticker.addEventListener(Event.ENTER_FRAME, onEndingEnterFrame);
    }

    private function onEndingEnterFrame(event:Event):Void
    {
        ticker.removeEventListener(Event.ENTER_FRAME, onEndingEnterFrame);
        ticker = null;
        System.gc();
        endSampling();
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function endSampling():Void
    {
        var newCount:UInt;
        var liveCount:UInt;
        var lastMicroTime:Int = 0;

        report("MemoryRecorder...");
        report("Objects still alive: >>>");

        //var objectsMap:Object = new Object();
        for (sample in getSamples())
        {
            if (Std.is(sample, NewObjectSample))
            {
                var newSample:NewObjectSample = NewObjectSample(sample);
                if (shouldPrintClass(newSample.type))
                {
                    newCount++;
                    if (newSample.object != null)
                    {
                        liveCount++;
                        reportNewSample(newSample);
                    }
                }
            }
            /*
            else if (sample is DeleteObjectSample)
            {
                //var delSample:DeleteObjectSample = DeleteObjectSample(s);
            }
            else
            {

            }*/
        }

        var timerTaken:UInt = endTimer - startTimer;

        report("<<<", liveCount, "object(s).");
        report("New objects:", newCount);
        report("Time taken:", timerTaken + "ms.");
        report("Memory change:", roundMem(startMemory) + "mb to", roundMem(endMemory) + "mb (" + roundMem(endMemory - startMemory) + "mb)");

        _started = false;
        clearSamples();
    }

    private function roundMem(num:Int):Float
    {
        return Math.round(num / 10485.76) / 100;
    }

    private function reportNewSample(sample:NewObjectSample):Void
    {
        var className:String = openfl.Lib.getQualifiedClassName(sample.type);
        try
        {
            if (sample.type == String)
            {
                reportNewStringSample(sample, className);
            }
            else
            {
                report(sample.id, className, getSampleSize(sample), sample.object, getSampleStack(sample));
            }
        }
        catch (err:Error)
        {
            report(sample.id, getSampleSize(sample), className, getSampleStack(sample));
        }
    }

    private function reportNewStringSample(sample:NewObjectSample, className:String):Void
    {
        var output:String = "";
        var masterStringFunction:Function = cast(getDefinitionByName("openfl.sampler.getMasterString"), Function); // only supported post flash 10.1

        var str:String = cast sample.object;
        if (masterStringFunction != null)
        {
            while (str)
            {
                output += "\"" + str + "\" > ";
                str = masterStringFunction(str);
            }
        }
        report(sample.id, className, getSampleSize(sample), output, getSampleStack(sample));
    }

    private function getSampleStack(sample:Sample):String
    {
        var output:String = "";
        for (stack in sample.stack)
        {
            stack = FlashRegex.replace(stack, ~/.*?\\:\\:/, "");
            stack = FlashRegex.replace(stack, ~/\[.*?\\:([0-9]+)\\]/, ":$1");
            //TODO: Check if Regex is working.
            output += stack + "; ";
        }
        return output;
    }

    private function getSampleSize(sample:Sample):String
    {
        /*if ("size" in sample)
        {
            return sample['size'];
        }*/
        //TODO: implement required
        return "";
    }

    //TODO: Warning Modified arguement, ...args:Array => args:Array<Dynamic>
    private function report(args:Array<Dynamic>):Void
    {
        var call:Function = reportCallback != null ? reportCallback : trace;
        call.apply(this, args);
    }

    private function shouldPrintClass(type:Class):Bool
    {
        return !isClassInIgnoredList(type) && isClassInInterestedList(type);
    }

    private function isClassInInterestedList(type:Class):Bool
    {
        if (_interestedClassExpressions.length == 0)
        {
            return true;
        }
        return classMatchesExpressionList(type, _interestedClassExpressions);
    }

    private function isClassInIgnoredList(type:Class):Bool
    {
        return classMatchesExpressionList(type, _ignoredClassExpressions);
    }

    private function classMatchesExpressionList(type:Class, list:Array<EReg>):Bool
    {
        var className:String = openfl.Lib.getQualifiedClassName(type);
        for (expression in list)
        {
            if (FlashRegex.search(className, expression) == 0)
            {
                return true;
            }
        }
        return false;
    }
}