package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

using StringTools;

class Boyfriend extends Character
{
	public var startedDeath:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished && startedDeath)
			{
				playAnim('death', true); //Change this to normal (so we can use as -loop)
			}

			//People had older version for compatibility stuff :/
			if (animation.curAnim.name == 'firstDeath' && animation.getByName('deathLoop') != null && animation.curAnim.finished && startedDeath)
			{
				playAnim('deathLoop');
			}
		}

		super.update(elapsed);
	}
}