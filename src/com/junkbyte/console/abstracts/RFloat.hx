package com.junkbyte.console.abstracts;

// https://code.haxe.org/category/abstract-types/rounded-float.html
abstract RFloat(Float) from Float {
    inline function new(value : Float)
    this = value;

    // The following rounds the result whenever converted to a Float
    @:to inline public function toFloat():Float  {
        return roundFloat(this);
    }

    @:to inline public function toString():String {
        return Std.string(toFloat());
    }

    // The number of zeros in the following valuer
    // corresponds to the number of decimals rounding precision
    static inline var multiplier = 10000000;

    static inline function roundFloat(value:Float):Float
    return Math.round(value * multiplier) / multiplier;
}