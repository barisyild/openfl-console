OpenFL-Console is haxe logger/debugger for OpenFL.<br/>
It comes with a collection of features to help speed up your development.

Console overlays on top of your OpenFL application.<br/>
Remote logging feature is also available to log to an external console.<br/>
No special browser or player version is required.

### New features

* Optional tilemap support has been added to Display Roller. *(It must be enabled from config)*

### Main features

* *Channels*
* *Priorities* aka levels with colour code
* *Object linking* where you can click on objects in log to inspect aka introspection
* *[CommandLineHelp Command line]* _CL_ - lets you execute code at runtime (as3 syntax)
* *[Remoting Remote logging]* also as Adobe AIR app
* No dependencies, requirements and non-invasive
* Super fast!
* *[Addons]* adds specialized features

### Other features
* *filtering*/searching via exact match or regular expression
* *Roller tool* _Ro_ - shows display map of what's under your mouse pointer
* *Graph reporting* numeric values (such as FPS, memory, user definable)
* *Ruler tool* _RL_ - Measure distances/degrees on screen
* Garbage collection monitor - notifies you when objects of your interest are being garbage collected.
* *Key-binding* to functions
* Non-repetitive tracing
* Customizable UI
* Easy to remove when no longer needed


### Goal

* The goal is for the project to be fully compatible with OpenFL and to add new features.

### Completion Status

* %10

Pull requests are welcome

OpenFL Console is port of [Flash Console](https://github.com/junkbyte/flash-console)

### Installation

```
haxelib git openfl-console https://github.com/barisyild/openfl-console.git
```

#### add in your project.xml:

```
<haxelib name="openfl-console"/>
```