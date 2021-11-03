package com.junkbyte.console.core;

import openfl.text.TextField;

class ConsoleTextField extends TextField {
    #if (!flash && openfl <= "9.1.0")
    public var styleSheet:com.junkbyte.console.text.StyleSheet;
    #end

    public function new() {
        super();
    }

    #if (!flash && openfl <= "9.1.0")
    @:setter(htmlText) private #if !flash override #end function set_htmlText(value:String)
    {
        var htmlText:String = value;
        var styles:Map<String, Dynamic> = styleSheet.getStyles();
        for(key in styles.keys())
        {
            if(htmlText.indexOf("<" + key + ">") == -1)
                continue;

            var style:Dynamic = styles.get(key);
            if(style.color != null || style.fontSize != null || style.fontSize != null)
            {
                var styleString:String = "<font";
                if(style.color != null)
                {
                    styleString += " color=\"" + style.color + "\"";
                }
                if(style.fontSize != null)
                {
                    styleString += " size=\"" + style.fontSize + "\"";
                }
                if(style.fontFamily != null)
                {
                    styleString += " face=\"" + style.fontFamily + "\"";
                }
                styleString += '>';
                htmlText = StringTools.replace(htmlText, "<" + key + ">", styleString + "<" + key + ">");
                htmlText = StringTools.replace(htmlText, "</" + key + ">", "</" + key + ">" + "</font>");
            }

            if(style.textAlign != null)
            {
                htmlText = StringTools.replace(htmlText, "<" + key, "<" + key + " align=\"" + style.textAlign + "\"");
            }

            //htmlText = StringTools.replace(htmlText, "<" + key, "<div");
            //htmlText = StringTools.replace(htmlText, "</" + key, "</div");
        }

        super.htmlText = htmlText;

        #if !flash return htmlText; #end
    }
    #end
}
