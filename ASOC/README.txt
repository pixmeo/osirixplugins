ASOC (AppleScript Objective-C)
==============================

This is a level of integration between AppleScript and Objective-C available since Mac OS X 10.6 onwards. 

Scripts are transformed into Objective-C subclasses of NSObject (or of any other class defined in the  property parent: of the script) at runtime, during the execution of the method loadAppleScriptObjectiveCScripts. 

In the objective-C app code following that call, it is possible to create a reference to the dynamically created class and an instance of it, to which messages can be sent.

At compile time, the compiler just needs an objective-c protocol description of the handlers of the applescript. By the way, it also transforms the textual applescript of the project into a script object.


* * *


We designed this example of ASOC osirixplugin to demonstrate the bare functionality. All the magics is performed in ASOC.m. We use the initPlugin method, which is called only once at the start of OsiriX, to create the class, a reference to it and finally to instantiate it. We keep the pointers into static variables, which are available at any time during OsiriX execution.

ASOC osirixplugin is meant to be extended and modified to do something useful from OsiriX based on applescripts. For instance, inter application communication with Mail.app, iPhoto.app, Pages.app. We believe that it organizes better the code and simplifies the transmission of variables between objective-c and applescript.

Hopefully, it might also offer speed improvement in comparison to the use of NSApplescript class.

Jacques


* * *

References:
===========
http://developer.apple.com/library/mac/#releasenotes/ScriptingAutomation/RN-AppleScriptObjC/index.html
http://macscripter.net/viewtopic.php?id=37691
https://github.com/CraigWilliams/HelloThere