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
package com.junkbyte.console.addons.displaymap;

import com.junkbyte.console.Console;
import com.junkbyte.console.core.LogReferences;
import com.junkbyte.console.view.ConsolePanel;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.TextEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.utils.Dictionary;

/**
	 * @private
	 */
class DisplayMapPanel extends ConsolePanel
{

    public static inline var NAME:String = "displayMapPanel";

    public static var numOfFramesToUpdate:UInt = 10;

    private var rootDisplay:DisplayObject;

    private var mapIndex:UInt = 0;

    private var indexToDisplayMap:Map<Int, Dynamic>;

    private var openings:Map<DisplayObject, Bool>;

    private var framesSinceUpdate:UInt = 0;

    public function new(m:Console)
    {
        super(m);
        name = NAME;
        init(60, 100, false);
        txtField = makeTF("mapPrints");
        txtField.multiline = true;
        txtField.autoSize = TextFieldAutoSize.LEFT;
        registerTFRoller(txtField, onMenuRollOver, linkHandler);
        registerDragger(txtField);
        addChild(txtField);
    }

    public function start(container:DisplayObject):Void
    {
        rootDisplay = container;
        openings = new Map();

        if (rootDisplay == null)
        {
            return;
        }

        rootDisplay.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);

        addToOpening(rootDisplay);
    }

    public function stop():Void
    {
        if (rootDisplay == null)
        {
            return;
        }

        rootDisplay.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        rootDisplay = null;
    }

    private function onEnterFrame(event:Event):Void
    {
        framesSinceUpdate++;
        if (framesSinceUpdate >= numOfFramesToUpdate)
        {
            framesSinceUpdate = 0;
            update();
        }
    }

    private function update():Void
    {
        mapIndex = 0;
        indexToDisplayMap = new Map();

        var string:String = "<p><p3>";

        if (rootDisplay == null)
        {
            string += "null";
        }
        else
        {
            string += "<menu> <a href=\"event:close\"><b>X</b></a></menu><br/>";

            var rootParent:DisplayObjectContainer = rootDisplay.parent;
            if (rootParent != null)
            {
                string += "<p5><b>" + makeLink(rootParent, " ^ ", "focus") + "</b>" + makeName(rootParent) + "</p5><br/>";
                string += printChild(rootDisplay, 1);
            }
            else
            {
                string += printChild(rootDisplay, 0);
            }
        }

        txtField.htmlText = string + "</p3></p>";

        width = txtField.width + 4;
        height = txtField.height;
    }

    private function printChild(display:DisplayObject, currentStep:UInt):String
    {
        if (display == null)
        {
            return "";
        }
        if (Std.is(display, DisplayObjectContainer))
        {
            var string:String;
            var container:DisplayObjectContainer = cast(display, DisplayObjectContainer);
            if (openings.get(display) == true)
            {
                string = "<p5><b>" + generateSteps(display, currentStep) + makeLink(display, "-" + container.numChildren, "minimize") + "</b> " + makeName(display) + "</p5><br/>";
                string += printChildren(container, currentStep + 1);
            }
            else
            {
                string = "<p4><b>" + generateSteps(display, currentStep) + makeLink(display, "+" + container.numChildren, "expand") + "</b> " + makeName(display) + "</p4><br/>";
            }
            return string;
        }
        return "<p3>" + generateSteps(display, currentStep) + makeName(display) + "</p3><br/>";
    }

    private function printChildren(container:DisplayObjectContainer, currentStep:UInt):String
    {
        var string:String = "";
        var len:UInt = container.numChildren;
        for (i in 0...len)
        {
            string += printChild(container.getChildAt(i), currentStep);
        }
        return string;
    }

    private function generateSteps(display:Dynamic, steps:UInt):String
    {
        var str:String = "";
        for (i in 0...steps)
        {
            if (i == steps - 1)
            {
                if (Std.is(display, DisplayObjectContainer))
                {
                    str += makeLink(display, " &gt; ", "focus");
                }
                else
                {
                    str += " &gt; ";
                }
            }
            else
            {
                str += " · ";
            }
        }
        return str;
    }

    private function onMenuRollOver(e:TextEvent):Void
    {
        var txt:String = e.text != null ? StringTools.replace(e.text, "event:", "") : "";

        if (txt == "close")
        {
            txt = "Close";
        }
        else if (txt.indexOf("expand") == 0)
        {
            txt = "expand";
        }
        else if (txt.indexOf("minimize") == 0)
        {
            txt = "minimize";
        }
        else if (txt.indexOf("focus") == 0)
        {
            txt = "focus";
        }
        else
        {
            txt = null;
        }
        console.panels.tooltip(txt, this);
    }

    private function makeName(display:DisplayObject):String
    {
        return makeLink(display, display.name, "scope") + " {<menu>" + makeLink(display, LogReferences.ShortClassName(display), "inspect") + "</menu>}";
    }

    private function makeLink(display:Dynamic, text:String, event:String):String
    {
        mapIndex++;
        indexToDisplayMap[mapIndex] = display;
        return "<a href='event:" + event + "_" + mapIndex + "'>" + text + "</a>";
    }

    private function getDisplay(string:String):DisplayObject
    {
        var split:Array<String> = string.split("_");
        return indexToDisplayMap.get(Std.parseInt(split[split.length - 1]));
    }

    private function linkHandler(e:TextEvent):Void
    {
        cast(e.currentTarget, TextField).setSelection(0, 0);
        console.panels.tooltip(null);

        if (e.text == "close")
        {
            close();
        }
        else if (e.text.indexOf("expand") == 0)
        {
            addToOpening(getDisplay(e.text));
        }
        else if (e.text.indexOf("minimize") == 0)
        {
            removeFromOpening(getDisplay(e.text));
        }
        else if (e.text.indexOf("focus") == 0)
        {
            focus(cast(getDisplay(e.text), DisplayObjectContainer));
        }
        else if (e.text.indexOf("scope") == 0)
        {
            scope(getDisplay(e.text));
        }
        else if (e.text.indexOf("inspect") == 0)
        {
            inspect(getDisplay(e.text));
        }

        e.stopPropagation();
    }

    private function focus(container:DisplayObjectContainer):Void
    {
        rootDisplay = container;
        addToOpening(container);
        update();
    }

    private function addToOpening(display:DisplayObject):Void
    {
        if (!openings.exists(display))
        {
            openings.set(display, true);
            update();
        }
    }

    private function removeFromOpening(display:DisplayObject):Void
    {
        if (openings.exists(display))
        {
            openings.remove(display);
            update();
        }
    }

    private function scope(display:DisplayObject):Void
    {
        console.cl.setReturned(display, true);
    }

    private function inspect(display:DisplayObject):Void
    {
        console.refs.focus(display);
    }

    override public function close():Void
    {
        stop();
        super.close();
    }
}