package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;

using StringTools;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;
	var noDeathAnim:Bool = false;
	var deathTimer:FlxTimer = new FlxTimer();
	public var startedMusic:Bool = false;
	public var doIdle:Bool = false;
	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();
		characterName =  deathSpritesCheck(PlayState.instance.boyfriend.curCharacter);
		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.playerPositionArray[0];
		boyfriend.y += boyfriend.playerPositionArray[1];
		add(boyfriend);

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		if (boyfriend.animation.getByName('firstDeath') != null)
		{
			noDeathAnim = false;
			boyfriend.playAnim('firstDeath', true);
		}
		else
		{
			noDeathAnim = true;
			boyfriend.animation.pause();
		}

		deathTimer.start(2.375, function(tmr:FlxTimer)
		{
			if (!startedMusic)
			{
				startedMusic = true;
				coolStartDeath();
				if (noDeathAnim)
					doIdle = true;
			}
		});

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	function deathSpritesCheck(char:String)
	{
		//a simple check to see if a dead spritesheet exists.
		var daChar:String = char;

		//in case you have two or more dashes like bf-aloe-confused. ok this really only works with two dashes but whatever.
		var dashCount:Int = daChar.indexOf('-');

		if (dashCount >= 2)
		{
			daChar = char.split('-')[0];

			for (i in 1...dashCount)
				daChar = daChar + '-' + char.split('-')[i];
		}

		var daCharacterPath:String = 'characters/' + daChar  + '-dead.json';
		var characterPath:String = 'characters/' + char + '-dead.json';

		if (Paths.fileExists(daCharacterPath, TEXT))
			return daChar+'-dead';

		if (Paths.fileExists(characterPath, TEXT))
			return char+'-dead';

		return char;	
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else if(PlayState.isBETADCIU)
				MusicBeatState.switchState(new BETADCIUState());
			else if(PlayState.isBonus)
				MusicBeatState.switchState(new BonusState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !playingDeathSound)
			{
				if (PlayState.instance.stage.curStage == 'tank')
				{
					playingDeathSound = true;
					coolStartDeath(0.2);
					
					var exclude:Array<Int> = [];
					//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

					FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
						if(!isEnding)
						{
							FlxG.sound.music.fadeIn(0.2, 1, 4);
						}
					});
				}
				else
				{
					coolStartDeath();
				}
				boyfriend.startedDeath = true;
			}
		}
		else
		{
			if (noDeathAnim && boyfriend != null)
				boyfriend.setColorTransform(0, 0, 0, 1, 51, 51, 204);
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		if (doIdle)
			boyfriend.dance();

		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			if (boyfriend.animation.getByName('deathConfirm') != null)
				boyfriend.playAnim('deathConfirm', true);

			if (noDeathAnim)
			{
				doIdle = false;
				boyfriend.animation.pause();
				if(ClientPrefs.flashing) //this is my Problem FLASHING ISSUE
				{
					flashCamera('ffffff', 0.5);
				}
			}
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}

	function flashCamera(color:String, duration:Float, ?forced:Bool = false) {
		var colorNum:Int = Std.parseInt(color);
		if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
		FlxG.camera.flash(colorNum, duration,null,forced);
	}
}
