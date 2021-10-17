package com.junkbyte.console.addons.hscript;

import com.junkbyte.console.core.LogReferences;
import openfl.Lib;
import flash.utils.ByteArray;
import hscript.Expr;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import haxe.io.Bytes;
import openfl.text.TextFieldType;
import openfl.text.TextFormatAlign;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.TextEvent;
import openfl.text.TextFieldAutoSize;
import com.junkbyte.console.view.ConsolePanel;
class HScriptPanel extends ConsolePanel
{
    public static inline var NAME:String = "HScriptPanel";
    private var scriptField:TextField = null;
    private var fileReference:FileReference;

    public function new(m:Console) {
        super(m);
        name = NAME;
        registerDragger(bg);
        minWidth = 300;
        minHeight = 300;

        txtField = makeTF("menuField");
        #if !flash
        var textFieldFormat:TextFormat = new TextFormat();
        textFieldFormat.align = TextFormatAlign.RIGHT;
        txtField.defaultTextFormat = textFieldFormat;
        #end
        txtField.height = style.menuFontSize+4;
        //txtField.width = minWidth;
        txtField.y = -3;
        txtField.selectable = false;
        //txtField.htmlText = "<high><menu> <a href=\"event:load\">Load</a> ¦ <a href=\"event:save\">Save</a> ¦ <b><a href=\"event:execute\">Execute</a></b> ¦ <a href=\"event:close\">X</a> </high>";
        //TODO: load and save disabled temporarily.
        txtField.htmlText = "<high><menu> <b><a href=\"event:execute\">Execute</a></b> ¦ <a href=\"event:close\">X</a> </high>";
        registerTFRoller(txtField, onMenuRollOver, linkHandler);
        addChild(txtField);

        scriptField = makeTF("scriptField");
        scriptField.height = style.menuFontSize+2;
        scriptField.multiline = true;
        scriptField.type = TextFieldType.INPUT;
        #if !flash
        var scriptFieldFormat:TextFormat = new TextFormat();
        scriptFieldFormat.color = 0xffffff;
        scriptField.defaultTextFormat = scriptFieldFormat;
        #end
        addChild(scriptField);

        //
        init(minWidth,minHeight,true);
        registerDragger(txtField); // so that we can still drag from textfield
    }

    @:setter(width) public override function set_width(value:Float)
    {
        super.width = value;
        txtField.width = value-6;
        scriptField.width = value;
        #if !flash return value; #end
    }

    @:setter(height) public override function set_height(value:Float)
    {
        super.height = value;
        scriptField.y = txtField.height;
        scriptField.height = value - txtField.height - 6;
        #if !flash return value; #end
    }

    private function onMenuRollOver(e:TextEvent):Void {
        console.panels.mainPanel.onMenuRollOver(e, this);
    }

    private function linkHandler(e:TextEvent):Void {
        txtField.setSelection(0, 0);

        var parser:hscript.Parser = null;
        var program:Expr = null;

        if(e.text == "close"){
            close();
        }else if(e.text == "execute")
        {
            var script;
            try
            {
                script = new hscript.Parser().parseString(scriptField.text);
            }
            catch(e)
            {
                Cc.fatalch("HScript", [Std.string(e)]);
                return;
            }

            executeScript(script, ["Main"]);
        }/*else if(e.text == "save")
        {
            var script;
            try
            {
                script = new hscript.Parser().parseString(scriptField.text);
            }
            catch(e)
            {
                Cc.fatalch("HScript", [Std.string(e)]);
                return;
            }
            fileReference = new FileReference();
            fileReference.save(ByteArray.fromBytes(hscript.Bytes.encode(script)), Date.now().getTime() + ".hscript");
        }else if(e.text == "load")
        {
            fileReference = new FileReference();
            fileReference.addEventListener(Event.SELECT, onFileSelected);
            fileReference.browse([new FileFilter("HScript File (*.hscript)", "*.hscript")]);
        }*/

        txtField.setSelection(0, 0);
        e.stopPropagation();
    }

    /*private function onFileSelected(e:Event):Void
    {
        fileReference.addEventListener(Event.COMPLETE, onFileLoaded);
        fileReference.load();
    }

    private function onFileLoaded(event:Event):Void
    {
        var script:Expr = hscript.Bytes.decode(cast fileReference.data);
        executeScript(script);
    }*/

    private function executeScript(script:Expr, classes:Array<String> = null):Void
    {
        var interp = new hscript.Interp();
        interp.variables.set("Cc",Cc);
        interp.variables.set("Reflect", Reflect);
        interp.variables.set("Type", Type);
        interp.variables.set("stage", Lib.current.stage);


        if(classes != null)
        {
            for(className in classes)
            {
                var dynamicClass:Class<Dynamic> = Type.resolveClass(className);

                if(dynamicClass == null)
                {
                    Cc.fatalch("HScript", [className, "class not found, if you are sure you typed it correctly, make sure it is not cleaned by DCE (Dead Code Elimination)"]);
                    return;
                }

                var shortName:String = openfl.Lib.getQualifiedClassName(dynamicClass);
                var ind:Int = shortName.indexOf("::");
                shortName = shortName.substring(ind>=0?(ind+2):0);

                interp.variables.set(shortName, dynamicClass);
                interp.variables.set(className, dynamicClass);
            }
        }


        try
        {
            Cc.infoch("HScript", [interp.execute(script)]);
        }
        catch(e)
        {
            Cc.fatalch("HScript", [Std.string(e)]);
        }
    }
}
