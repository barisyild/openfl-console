package com.junkbyte.console.text;

#if (!flash && openfl <= "9.1.0")
class StyleSheet extends openfl.events.EventDispatcher {
    public var styleNames(get,never) : Array<Dynamic>;
    private var styles:Map<String, Dynamic>;

    public function new() : Void
    {
        super();
        styles = new Map();
    }

    public function clear() : Void
    {
        styles.clear();
    }

    public function getStyle(styleName : String):Dynamic
    {
        return styles.get(styleName);
    }

    public function getStyles():Map<String, Dynamic>
    {
        return styles;
    }

    private function get_styleNames() : Array<Dynamic>
    {
        return Reflect.fields(styles);
    }

    public function setStyle(styleName : String, styleObject : openfl.utils.Object) : Void
    {
        styles.set(styleName, styleObject);
    }
}
#else
class StyleSheet extends #if flash flash.text.StyleSheet #else openfl.text.StyleSheet #end {
    public function new() : Void
    {
        super();
    }
}
#end
