/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
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
* REQUIRES Flash Player 11.0 OR com.adobe.serialization.json.JSON
*/
package com.junkbyte.console.addons.htmlexport;

import haxe.Json;
import openfl.errors.Error;
import com.junkbyte.console.Cc;
import com.junkbyte.console.Console;
import com.junkbyte.console.ConsoleConfig;
import com.junkbyte.console.ConsoleStyle;
import com.junkbyte.console.view.MainPanel;
import com.junkbyte.console.vos.Log;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

/**
	 * This addon allows you to export logs from flash console to a HTML file.
	 *
	 * <ul>
	 * <li>Preserves channels and priorities.</li>
	 * <li>It also have all those filtering features in HTML page.</li>
	 * <li>Add to Console menu by calling ConsoleHtmlExport.addMenuToConsole();</li>
	 * </ul>
	 *
	 * REQUIRES Flash Player 11.0 OR com.adobe.serialization.json.JSON library.
	 */
class ConsoleHtmlExportAddon
{
    private static var EmbeddedTemplate:String;

    public static inline var HTML_REPLACEMENT:String = "{text:'HTML_REPLACEMENT'}";

    public var referencesDepth:UInt = 1;

    private var console:Console;

    /**
		 * Adding 'export' menu item at the top menu of Console.
		 *
		 * @param menuName Name of menu. Default = 'export'
		 * @param console Instance to Console. You do not need to pass this param if you use Cc.
		 *
		 * @return New ConsoleHTMLExport instance created by this method.
		 */
    public static function addToMenu(menuName:String = "export", console:Console = null):ConsoleHtmlExportAddon
    {
        if (console == null)
        {
            console = Cc.instance;
        }
        var exporter:ConsoleHtmlExportAddon = null;
        if (console != null)
        {
            exporter = new ConsoleHtmlExportAddon(console);
            console.addMenu(menuName, exporter.exportToFile, new Array(), "Export logs to HTML");
        }
        return exporter;
    }

    public function new(console:Console):Void
    {
        if (console == null)
        {
            console = Cc.instance;
        }
        this.console = console;
    }

    /**
		 * Trigger 'save to file' dialogue to save console logs in HTML file.
		 *
		 * @param fileName Initial file name to use in save dialogue.
		 */
    public function exportToFile(fileName:String = null):Void
    {
        if (fileName == null)
        {
            fileName = generateFileName();
        }

        var file:FileReference = new FileReference();
        try
        {
            var html:String = exportHTMLString();
            file.save(html, fileName); // flash player 10+
        }
        catch (err:Error)
        {
            console.report("Failed to save to file: " + err, 8);
        }
    }

    private function generateFileName():String
    {
        var date:Date = Date.now();
        var fileName:String = "log@" + date.getFullYear() + "." + (date.getMonth() + 1) + "." + (date.getDate() + 1);
        fileName += "_" + date.getHours() + "." + date.getMinutes();
        fileName += ".html";
        return fileName;
    }

    /**
		 * Generate HTML String of Console logs.
		 */
    public function exportHTMLString():String
    {
        var html:String = EmbeddedTemplate.toString();
        html = StringTools.replace(html, HTML_REPLACEMENT, exportJSON());
        return html;
    }

    private function exportJSON():String
    {
        var object:Dynamic = exportObject();
        return Json.stringify(object);
    }

    private function exportObject():Dynamic
    {
        var data:Dynamic = {};
        data.config = getConfigToEncode();
        data.ui = getUIDataToEncode();
        data.logs = getLogsToEncode();

        var refs:ConsoleHTMLRefsGen = new ConsoleHTMLRefsGen(console, referencesDepth);
        refs.fillData(data);

        return data;
    }

    private function getConfigToEncode():Dynamic
    {
        var config:ConsoleConfig = console.config;
        var object:Dynamic = convertTypeToObject(config);
        object.style = getStyleToEncode();
        return object;
    }

    private function getStyleToEncode():Dynamic
    {
        var style:ConsoleStyle = console.config.style;
        /*if(!preserveStyle)
        {
            style = new ConsoleStyle();
            style.updateStyleSheet();
        }*/

        var object:Dynamic = convertTypeToObject(style);
        object.styleSheet = getStyleSheetToEncode(style);

        return object;
    }

    private function getStyleSheetToEncode(style:ConsoleStyle):Dynamic
    {
        var object:Dynamic = {};
        for (styleName in style.styleSheet.styleNames)
        {
            Reflect.setField(object, styleName, style.styleSheet.getStyle(styleName));
        }
        return object;
    }

    private function getUIDataToEncode():Dynamic
    {
        var mainPanel:MainPanel = console.panels.mainPanel;

        var object:Dynamic = {};
        object.viewingPriority = mainPanel.priority;
        object.viewingChannels = mainPanel.viewingChannels;
        object.ignoredChannels = mainPanel.ignoredChannels;
        return object;
    }

    private function getLogsToEncode():Array<Dynamic>
    {
        var lines:Array<Dynamic> = new Array();
        var line:Log = console.logs.last;
        while (line != null)
        {
            var obj:Dynamic = convertTypeToObject(line);
            Reflect.deleteField(obj, "next");
            Reflect.deleteField(obj, "prev");
            lines.push(obj);
            line = line.prev;
        }
        lines.reverse();
        return lines;
    }

    private function convertTypeToObject(typedObject:Dynamic):Dynamic
    {
        var object:Dynamic = {};
        /*var desc:XML = describeType(typedObject);
        for each (var varXML:XML in desc.variable)
        {
            var key:String = varXML.@name;
            object[key] = typedObject[key];
        }*/
        //TODO: implement required
        return object;
    }
}