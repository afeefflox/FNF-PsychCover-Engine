package openfl.display;

import haxe.Timer;
import openfl.events.Event;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import openfl.display.FPSSprite;
import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end
import flixel.FlxG;
import flixel.FlxGame;
import flixel.util.FlxColor;
import openfl.Assets;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end
import openfl.system.System;

using StringTools;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Float;

	public var curMemory:Float;
	public var maxMemory:Float;
	public var realAlpha:Float = 1;
	public var lagging:Bool = false;
	public var forceUpdateText(default, set):Bool = false;

	public var spriteParent:FPSSprite;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	public function getFont(Font:String):String
	{
		embedFonts = true;

		var newFontName:String = Font;

		if (Font != null)
		{
			if (Assets.exists(Font, AssetType.FONT))
			{
				newFontName = Assets.getFont(Font).fontName;
			}
		}
		return newFontName;
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}
		
		var currentCount = times.length;
		currentFPS = (currentCount + cacheCount) / 2;

		// currentFPS = 1 / (deltaTime / 1000);

		if (currentFPS > ClientPrefs.framerate)
			currentFPS = ClientPrefs.framerate;

		if (currentCount != cacheCount /*&& visible*/)
		{
			updateText();
		}

		cacheCount = currentCount;
	}

	private function set_forceUpdateText(value:Bool):Bool
	{
		updateText();
		return value;
	}

	private function updateText():Void
	{
		text = "FPS: " + Math.round(currentFPS);

		var ms:Float = 1 / Math.round(currentFPS);
		ms *= 1000;
		#if debug
		text += ' (${FlxMath.roundDecimal(ms, 2)}ms)';
		#end

		lagging = false;

		textColor = FlxColor.fromRGBFloat(1, 1, 1, realAlpha);
		if (currentFPS <= ClientPrefs.framerate / 2)
		{
			textColor = FlxColor.fromRGBFloat(1, 0, 0, realAlpha);
			lagging = true;
		}

		text += '\n';

		curMemory = obtainMemory();
		if (curMemory >= maxMemory)
			maxMemory = curMemory;
		text += 'Memory: ${formatMemory(Std.int(curMemory))}';
		text += '\n';
		text += 'Memory Peak: ${formatMemory(Std.int(maxMemory))}';
		text += '\n';
		#if debug
		text += '\nDEBUG INFO:\n';
		text += 'Usage:\n';
		text += '\nRuntime: ${FlxStringUtil.formatTime(currentTime / 1000)}';
		text += "\n";
		text += 'State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		if (FlxG.state.subState != null)
			text += ' (Sub State: ${Type.getClassName(Type.getClass(FlxG.state.subState))})';
		text += "\n";
		#end
	}

	function obtainMemory():Dynamic
	{
		return System.totalMemory;
	}

	function formatMemory(num:UInt):String
	{
		var size:Float = num;
		var data = 0;
		var dataTexts = ["B", "KB", "MB", "GB"];
		while (size > 1024 && data < dataTexts.length - 1)
		{
			data++;
			size = size / 1024;
		}

		size = Math.round(size * 100) / 100;
		var formatSize:String = formatAccuracy(size);
		return formatSize + " " + dataTexts[data];
	}

	function formatAccuracy(value:Float)
	{
		var conversion:Map<String, String> = [
			'0' => '0.00',
			'0.0' => '0.00',
			'0.00' => '0.00',
			'00' => '00.00',
			'00.0' => '00.00',
			'00.00' => '00.00', // gotta do these as well because lazy
			'000' => '000.00'
		]; // these are to ensure you're getting the right values, instead of using complex if statements depending on string length

		var stringVal:String = Std.string(value);
		var converVal:String = '';
		for (i in 0...stringVal.length)
		{
			if (stringVal.charAt(i) == '.')
				converVal += '.';
			else
				converVal += '0';
		}

		var wantedConversion:String = conversion.get(converVal);
		var convertedValue:String = '';

		for (i in 0...wantedConversion.length)
		{
			if (stringVal.charAt(i) == '')
				convertedValue += wantedConversion.charAt(i);
			else
				convertedValue += stringVal.charAt(i);
		}

		if (convertedValue.length == 0)
			return '$value';

		return convertedValue;		
	}

	public var textAfter:String = '';
}