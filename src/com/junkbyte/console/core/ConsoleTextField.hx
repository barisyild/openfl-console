package com.junkbyte.console.core;

import openfl.text.TextField;

class ConsoleTextField extends TextField {
    #if !flash
    public var styleSheet:openfl.text.StyleSheet;
    #end

    public function new() {
        super();
    }

    @:setter(htmlText) private #if !flash override #end function set_htmlText(value:String)
    {
        /*
            _css.setStyle("high",{color:hesh(highColor), fontFamily:menuFont, fontSize:menuFontSize, display:'inline'});
            _css.setStyle("low",{color:hesh(lowColor), fontFamily:menuFont, fontSize:menuFontSize-2, display:'inline'});
            _css.setStyle("menu",{color:hesh(menuColor), display:'inline'});
            _css.setStyle("menuHi",{color:hesh(menuHighlightColor), display:'inline'});
            _css.setStyle("chs",{color:hesh(channelsColor), fontSize:menuFontSize, leading:'2', display:'inline'});
            _css.setStyle("ch",{color:hesh(channelColor), display:'inline'});
            _css.setStyle("tt",{color:hesh(menuColor),fontFamily:menuFont,fontSize:menuFontSize, textAlign:'center'});
            _css.setStyle("r",{textAlign:'right', display:'inline'});
            _css.setStyle("p",{fontFamily:traceFont, fontSize:traceFontSize});
            _css.setStyle("p0",{color:hesh(priority0), display:'inline'});
            _css.setStyle("p1",{color:hesh(priority1), display:'inline'});
            _css.setStyle("p2",{color:hesh(priority2), display:'inline'});
            _css.setStyle("p3",{color:hesh(priority3), display:'inline'});
            _css.setStyle("p4",{color:hesh(priority4), display:'inline'});
            _css.setStyle("p5",{color:hesh(priority5), display:'inline'});
            _css.setStyle("p6",{color:hesh(priority6), display:'inline'});
            _css.setStyle("p7",{color:hesh(priority7), display:'inline'});
            _css.setStyle("p8",{color:hesh(priority8), display:'inline'});
            _css.setStyle("p9",{color:hesh(priority9), display:'inline'});
            _css.setStyle("p10",{color:hesh(priority10), fontWeight:'bold', display:'inline'});
            _css.setStyle("p-1",{color:hesh(priorityC1), display:'inline'});
            _css.setStyle("p-2",{color:hesh(priorityC2), display:'inline'});
            _css.setStyle("logs",{color:hesh(logHeaderColor), display:'inline'});
         */
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

    @:getter(htmlText) private #if !flash override #end function get_htmlText()
    {
        var htmlText:String = super.htmlText;



        return htmlText;
    }
}
