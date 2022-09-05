package;
import hscript.Interp;

import PlayState;  
import Discord;
import Character;
import Boyfriend;
import Song;
import GameOverSubstate;
import HealthIcon;
import Section;
import StrumNote;
import ClientPrefs;
import Note; 
import NoteSplash;
import BGSprite;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import lime.app.Application;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
#if hscript
import hscript.Interp;
import hscript.Parser;
#end
/**
 * STOLEN FROM FNF OS :(
 */
 using StringTools;
class FunkinHaxe 
{
  public var hscriptArray:Map<String, Interp> = [];
  public var scriptName:String = '';
  public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_StopHscript:Dynamic = 2;
  public var interp:Interp = new Interp();
  public var exparser:Parser = new Parser();
  public function new(script:String) {
    #if hscript
    scriptName = script;
    exparser.line = 1;
    exparser.allowMetadata = true;
    exparser.allowTypes = true;
    var parsedstring = exparser.parseString(File.getContent(script));
    interp = new Interp();
    interp.errorHandler = function(e) {
      var posInfo = interp.posInfos();

      var lineNumber = Std.string(posInfo.lineNumber);
      var methodName = posInfo.methodName;
      var className = posInfo.className;

      Application.current.window.alert('Exception occured at line $lineNumber ${methodName == null ? "" : 'in $methodName'}\n\n${e}\n\nIf the message boxes blocks the engine, hold down SHIFT to bypass.', 'HScript error! - ${scriptName}');
  };

    set('PlayState', PlayState);
    set('Character', Character);
    set('Stage', Stage);
    set('Paths', Paths);
    set('Boyfriend', Boyfriend);
    set('HealthIcon', HealthIcon);
    set('StrumNote', StrumNote);
    set('Conductor', Conductor);
    set('ClientPrefs', ClientPrefs);
    set('BGSprite', BGSprite);
    set('GameOverSubstate', GameOverSubstate);
    set('Note', Note);
    set('FlxG', FlxG);
    set('Song', Song);
    set('FlxGame', FlxGame);
    set('FlxBackdrop', FlxBackdrop);
    set('FlxBar', FlxBar);
    set('Section', Section);
    set('FlxState', FlxState);
    set('NoteSplash', NoteSplash);
    set('FlxSprite', FlxSprite);
    set('FlxBasic', FlxBasic);
    set('FlxTween', FlxTween);
    set('FlxSort', FlxSort);
    set('FlxTimer', FlxTimer);
    set('FlxEase', FlxEase);
    set('FlxText', FlxText);
    set('FlxSound', FlxSound);
    set('FlxText', FlxText);
    set('FlxRect', FlxRect);
    set('FlxPoint', FlxPoint);
    set('FlxTrail', FlxTrail);
    set('StringTools', StringTools);
    set('Function_StopHscript', Function_StopHscript);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);

    interp.variables.set('setVar', function(name:String, value:Dynamic)
    {
      PlayState.instance.variables.set(name, value);
    });
    interp.variables.set('getVar', function(name:String, value:Dynamic)
    {
      if(!PlayState.instance.variables.exists(name)) return null;
      return PlayState.instance.variables.get(name);
    });
    interp.variables.set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
    //Heh Why not I added this?
    interp.variables.set('addLibrary', function(libName:String, ?libFolder:String = '')
    {
			try {
				var str:String = '';
				if(libFolder.length > 0)
					str = libFolder + '.';

				set(libName, Type.resolveClass(str + libName));
			}
    });
    interp.execute(parsedstring);
    hscriptArray.set(script, interp);
    call('onCreate', []);
    #end
  }

  public function set(variable:String, data:Dynamic) {
    #if hscript
    interp.variables.set(variable, data);
    #end
  }
  
  function callSingleHScript(func:String, args:Array<Dynamic>, filename:String) {
    #if hscript
		if (!hscriptArray.get(filename).variables.exists(func)) {
			//trace("I can't find function with name: " + func); this is annoyned tbh
			return;
		}
		var method = hscriptArray.get(filename).variables.get(func);
		if (args.length == 0) {
			method();
		} else if (args.length == 1) {
			method(args[0]);
		}
    #end
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic {
    #if hscript
		for (i in hscriptArray.keys()) {
			callSingleHScript(func, args, i);	// it could be easier ig
      return Function_Continue;
		}
    #end
    return Function_Continue;
	}
}