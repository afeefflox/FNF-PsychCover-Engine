package;


import haxe.crypto.Md5;
import haxe.Exception;
import flixel.addons.display.FlxBackdrop;
import openfl.display.BlendMode;
import flixel.tile.FlxTilemap;
import animateatlas.AtlasFrameMaker;
import haxe.EnumTools;
import hscript.Expr;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetManifest;
import haxe.io.Path;
import haxe.io.Bytes;
#if desktop
import cpp.Lib;
import Discord.DiscordClient;
#end
import flixel.util.FlxSave;
import lime.app.Application;
import haxe.PosInfos;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.util.FlxAxes;
import flixel.addons.text.FlxTypeText;
import openfl.display.PNGEncoderOptions;
import flixel.tweens.FlxEase;
import haxe.Json;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.display.JsonModuleTypes.JsonTypeParameters;
import flixel.addons.effects.chainable.FlxShakeEffect;
import flixel.FlxBasic;
import flixel.text.FlxText;
import flixel.FlxState;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import lime.utils.Assets;
import openfl.utils.Assets as DeezNutsAssets;
import flixel.system.FlxAssets;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;
import FunkinLua;
import Stage;

#if hscript
import hscript.Interp;
import hscript.Parser;
#end

#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

using StringTools;
class FunkinHaxe 
{
    public var hscript:Interp;
    public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_StopHscript:Dynamic = 2;
    public var superVar = {};
    public var scriptName:String = '';
    public var isStage:Bool = false;

    public function new(script:String, ?isStage:Bool = false) {
        scriptName = script;
        this.isStage = isStage;
        hscript = new Interp();
        hscript.errorHandler = function(e) {
            if (!FlxG.keys.pressed.SHIFT) {
                var posInfo = hscript.posInfos();

                var lineNumber = Std.string(posInfo.lineNumber);
                var methodName = posInfo.methodName;
                var className = posInfo.className;

                Application.current.window.alert('Exception occured at line $lineNumber ${methodName == null ? "" : 'in $methodName'}\n\n${e}\n\nIf the message boxes blocks the engine, hold down SHIFT to bypass.', 'HScript error! - ${scriptName}');
            }
        };

        for(k=>v in hscript.variables) {
            Reflect.setField(superVar, k, v);
        }
        set("this", hscript);
		set("super", superVar);

        set("import", function(className:String) {
            var splitClassName = [for (e in className.split(".")) e.trim()];
            var realClassName = splitClassName.join(".");
            var cl = Type.resolveClass(realClassName);
            var en = Type.resolveEnum(realClassName);
            if (en != null) {
                // ENUM!!!!
                var enumThingy = {};
                for(c in en.getConstructors()) {
                    Reflect.setField(enumThingy, c, en.createByName(c));
                }
                set(splitClassName[splitClassName.length - 1], enumThingy);
            } else if (cl != null) {
                // CLASS!!!!
                set(splitClassName[splitClassName.length - 1], cl);
            }
        });

        set("makeLuaCharacter", function(tag:String, char:String, ?isPlayer:Bool = false, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetCharacterTag(tag);
			resetGroupTag(tag + 'Group');
			var leGroup:ModchartGroup = new ModchartGroup(x, y);
			var leCharacter:ModchartCharacter = new ModchartCharacter(0, 0, char, isPlayer);

			PlayState.instance.startCharacterPos(leCharacter, !isPlayer);
			PlayState.instance.startCharacterHaxe(leCharacter.curCharacter);
			PlayState.instance.startCharacterLua(leCharacter.curCharacter);
            PlayState.instance.modchartCharacters.set(tag, leCharacter);
			PlayState.instance.modchartGroups.set(tag + 'Group', leGroup);
        });
        set("addLuaCharacter", function(tag:String, front:Bool = false, ?layersName:String = 'boyfriend') {
			if(PlayState.instance.modchartCharacters.exists(tag) && PlayState.instance.modchartGroups.exists(tag + 'Group')) {
				var shit:ModchartCharacter = PlayState.instance.modchartCharacters.get(tag);
				var shitGroup:ModchartGroup = PlayState.instance.modchartGroups.get(tag + 'Group');
				if(!shitGroup.wasAdded && !shit.wasAdded) {
					if(isStage)
					{
						if(front)
						{
							var layersCharacter:String = 'boyfriend';
							switch(layersName)
							{
								case 'gf'|'girlfriend':
									layersCharacter = 'gf';
								case 'dad'|'opponent':
									layersCharacter = 'dad';
							}
							Stage.instance.layers.get(layersCharacter).add(shitGroup);
						}
						else
						{
							Stage.instance.add(shitGroup);
						}
							
					}
					else
					{
						if(front)
						{
							PlayState.instance.add(shitGroup);
						}
	
						if(PlayState.instance.isDead)
						{
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shitGroup);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shitGroup);
						}
					}
					shit.wasAdded = true;
					shitGroup.wasAdded = true;
					shitGroup.add(shit);
					//trace('added a thing: ' + tag);
				}
			}
        });
        set("add", function(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend') {

            if(isStage) {
                if(front)
                {
                    var layersCharacter:String = 'boyfriend';
                    switch(layersName)
                    {
                        case 'gf'|'girlfriend':
                            layersCharacter = 'gf';
                        case 'dad'|'opponent':
                            layersCharacter = 'dad';
                    }
                    Stage.instance.layers.get(layersCharacter).add(obj);
                }
                else
                {
                    Stage.instance.add(obj);
                }
            }
            else
            {
                if(front)
                {
                    PlayState.instance.add(obj);
                }
                else
                {
                    if(PlayState.instance.isDead)
					{
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
					}
					else
					{
						var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
						if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
							position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
						} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
							position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
						}
						PlayState.instance.insert(position, obj);
					}
                }
            }
        });
        set("remove", function(obj:FlxBasic, ?front:Bool = false, ?layersName:String = 'boyfriend') {
            if(isStage) {
                if(front)
                {
                    var layersCharacter:String = 'boyfriend';
                    switch(layersName)
                    {
                        case 'gf'|'girlfriend':
                            layersCharacter = 'gf';
                        case 'dad'|'opponent':
                            layersCharacter = 'dad';
                    }
                    Stage.instance.layers.get(layersCharacter).remove(obj);
                }
                else
                {
                    Stage.instance.remove(obj);
                }
            }
            else
            {
                if(front)
                {
                    PlayState.instance.remove(obj);
                }
                else
                {
                    if(PlayState.instance.isDead)
					{
						GameOverSubstate.instance.remove(obj);
					}
					else
					{
						PlayState.instance.remove(obj);
					}
                }
            }
        });
        if(PlayState.instance != null)
        {
            set("PlayState", PlayState);
            set("game", PlayState.instance);
        }

        set("FlxSprite", FlxSprite);
		set("Alphabet", Alphabet);
		set("BitmapData", BitmapData);
		set("FlxBackdrop", FlxBackdrop);
		set("FlxG", FlxG);
		set("Paths", Paths);
		set("Std", Std);
		set("Math", Math);
		set("FlxMath", FlxMath);
		set("FlxAssets", FlxAssets);
        set("Assets", Assets);
		set("Note", Note);
		set("Character", Character);
        set("Stage", Stage);
		set("Conductor", Conductor);
		set("StringTools", StringTools);
		set("FlxSound", FlxSound);
		set("FlxEase", FlxEase);
		set("FlxTween", FlxTween);
		set("FlxPoint", flixel.math.FlxPoint);
		set("Boyfriend", Boyfriend);
		set("FlxTypedGroup", FlxTypedGroup);
		set("BackgroundDancer", BackgroundDancer);
		set("BackgroundGirls", BackgroundGirls);
		set("FlxTimer", FlxTimer);
		set("Json", Json);
		set("MP4Handler", MP4Handler);
		set("CoolUtil", CoolUtil);
		set("FlxTypeText", FlxTypeText);
		set("FlxText", FlxText);
		set("Rectangle", Rectangle);
        set("Lib", openfl.Lib);
		set("Point", Point);
		set("Window", Application.current.window);
        set("GameOverSubstate", GameOverSubstate);
		set("FlxAxes", FlxAxes);
        set("ClientPrefs", ClientPrefs);
        set("AtlasFrameMaker", AtlasFrameMaker);
        set("FlxTilemap", FlxTilemap);
        set("BlendMode", {
            ADD: BlendMode.ADD,
            ALPHA: BlendMode.ALPHA,
            DARKEN: BlendMode.DARKEN,
            DIFFERENCE: BlendMode.DIFFERENCE,
            ERASE: BlendMode.ERASE,
            HARDLIGHT: BlendMode.HARDLIGHT,
            INVERT: BlendMode.INVERT,
            LAYER: BlendMode.LAYER,
            LIGHTEN: BlendMode.LIGHTEN,
            MULTIPLY: BlendMode.MULTIPLY,
            NORMAL: BlendMode.NORMAL,
            OVERLAY: BlendMode.OVERLAY,
            SCREEN: BlendMode.SCREEN,
            SHADER: BlendMode.SHADER,
            SUBTRACT: BlendMode.SUBTRACT
        });
        set("FlxColor", FlxColorHelper);

        hscript.execute(getExpressionFromPath(script, true));
        call('create', []);
    }
    
    public function call(func:String, ?args:Array<Dynamic>):Dynamic {
        #if hscript
        if (hscript == null)
            return Function_Continue;
		if (hscript.variables.exists(func)) {
            var f = hscript.variables.get(func);
            if (Reflect.isFunction(f)) {
                if (args == null || args.length < 1)
                    return f();
                else
                    return Reflect.callMethod(null, f, args);
            }
		}
        #end
        return Function_Continue;
    }

    public function set(name:String, val:Dynamic) {
        hscript.variables.set(name, val);
        @:privateAccess
        hscript.locals.set(name, val);
    }

    public function get(name:String):Dynamic {
        if (@:privateAccess hscript.locals.exists(name) && @:privateAccess hscript.locals[name] != null) {
            @:privateAccess
            return hscript.locals.get(name).r;
        } else if (hscript.variables.exists(name))
            return hscript.variables.get(name);

        return null;
    }

    public function stop() {
        if(hscript == null) {
			return;
		}

		hscript = null;
    }

    function getExpressionFromPath(path:String, critical:Bool = false):hscript.Expr {
        var ast:Expr = null;
        try {
			var cachePath = path.toLowerCase();
			var fileData = FileSystem.stat(path);
            var content = sys.io.File.getContent(path);
            ast = getExpressionFromString(content, critical, path);
        } catch(ex) {
            if (!openfl.Lib.application.window.fullscreen && critical) openfl.Lib.application.window.alert('Could not read the file at "$path".');
            trace('Could not read the file at "$path".');
        }
        return ast;
    }

    function getExpressionFromString(code:String, critical:Bool = false, ?path:String):hscript.Expr {
        if (code == null) return null;
        var parser = new hscript.Parser();
		parser.allowTypes = true;
        var ast:Expr = null;
		try {
			ast = parser.parseString(code);
		} catch(ex) {
			trace(ex);
            var exThingy = Std.string(ex);
            var line = parser.line;
            if (path != null) {
                if (!openfl.Lib.application.window.fullscreen && critical) openfl.Lib.application.window.alert('Failed to parse the file located at "$path".\r\n$exThingy at $line');
                trace('Failed to parse the file located at "$path".\r\n$exThingy at $line');
            } else {
                if (!openfl.Lib.application.window.fullscreen && critical) openfl.Lib.application.window.alert('Failed to parse the given code.\r\n$exThingy at $line');
                trace('Failed to parse the given code.\r\n$exThingy at $line');
                if (!critical) throw new Exception('Failed to parse the given code.\r\n$exThingy at $line');
            }
		}
        return ast;
    }


    function resetGroupTag(tag:String) {
		if(!PlayState.instance.modchartGroups.exists(tag)) {
			return;
		}

		var pee:ModchartGroup = PlayState.instance.modchartGroups.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartGroups.remove(tag);
	}

	function resetCharacterTag(tag:String) {
		if(!PlayState.instance.modchartCharacters.exists(tag)) {
			return;
		}

		var pee:ModchartCharacter = PlayState.instance.modchartCharacters.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartCharacters.remove(tag);
	}
}
