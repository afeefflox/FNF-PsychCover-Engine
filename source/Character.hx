package;

import flixel.FlxObject;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;
import data.DataType;
import FunkinHaxe;


using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;
	var arrowSkin:String;
	var arrowStyle:String;
	var splashSkin:String;

	var position:Array<Float>;
	var player_position:Array<Float>;
	var camera_position:Array<Float>;
	var playerCamera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var isPlayerChar:Bool;

	@:optional var spriteType:String;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	var offsets_player:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public var animOffsetsPlayer:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public var debugMode:Bool = false;

	public var isPlayer(default, set):Bool = false;
	public var wasPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var holding:Bool = false;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose'
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var stopIdle:Bool = false; //Character use Disabled Idle :/ from Blantados
	public var trail:Bool = false;
	public var flipAnim:Bool = false;
	public var skipDance:Bool = false;
	

	public var healthIcon:String = 'face';
	public var arrowSkin:String = 'NOTE_assets';
	public var arrowStyle:String = 'normal';
	public var splashSkin:String = 'noteSplashes';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var playerPositionArray:Array<Float> = [0, 0];
	public var playerCameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public static var characterScript:FunkinHaxe;
	public var spriteType:DataType;
	public var spriteTypeAlt:String = 'sparrow';
	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	function set_isPlayer(value:Bool):Bool
	{
		return isPlayer = value;
	}

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
		var library:String = null;
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/$DEFAULT_CHARACTER.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				imageFile = json.image;

				if (json.spriteType != null)
					spriteType = DataType.createByName(json.spriteType);
				else
				{
					#if MODS_ALLOWED
					var modTxtToFind:String = Paths.modsTxt(json.image);
					var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);
					if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
					#else
					if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
					#end
					{
						spriteType = PACKER;
						spriteTypeAlt = 'packer';
					}

					#if MODS_ALLOWED
					var modXmlToFind:String = Paths.modsXml(json.image);
					var xmlToFind:String = Paths.getPath('images/' + json.image + '.xml', TEXT);
					if (FileSystem.exists(modXmlToFind) || FileSystem.exists(xmlToFind) || Assets.exists(xmlToFind))
					#else
					if (Assets.exists(Paths.getPath('images/' + json.image + '.xml', TEXT)))
					#end
					{
						spriteType = SPARROW;
						spriteTypeAlt = 'sparrow';
					}

					#if MODS_ALLOWED
					var modJsonToFind:String = Paths.modsJson2(json.image);
					var jsonToFind:String = Paths.getPath('images/' + json.image + '.json', TEXT);
					if (FileSystem.exists(modJsonToFind) || FileSystem.exists(jsonToFind) || Assets.exists(jsonToFind))
					#else
					if (Assets.exists(Paths.getPath('images/' + json.image + '.json', TEXT)))
					#end
					{
						spriteType = JSON;
						spriteTypeAlt = 'json';
					}
					
					#if MODS_ALLOWED
					var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
					var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
					if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
					#else
					if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
					#end
					{
						spriteTypeAlt = 'texture';
					}
				}
				
				if (imageFile != null && spriteType != null && spriteTypeAlt != 'texture')
					frames = Paths.getAtlasFromData(imageFile, spriteType);
				else if(spriteTypeAlt == 'texture')
					frames = AtlasFrameMaker.construct(imageFile);
				
				
				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				
				if(json.arrowSkin != null)
					arrowSkin = json.arrowSkin;

				if(json.arrowStyle != null)
					arrowStyle = json.arrowStyle;

				if(json.splashSkin != null)
					splashSkin = json.splashSkin;


				if(json.isPlayerChar)
					wasPlayer = json.isPlayerChar;


				if (json.player_position != null)
					playerPositionArray = json.player_position;
				else
					playerPositionArray = json.position;

				if (json.playerCamera_position != null)
					playerCameraPosition = json.playerCamera_position;
				else
					playerCameraPosition = json.camera_position;

				positionArray = json.position;
				cameraPosition = json.camera_position; 
				

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;

				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;
				animationsArray = json.animations;
				reloadAnimation();
				//trace('Loaded file to character ' + curCharacter);
		}
		originalFlipX = flipX;
		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();
		
		if(curCharacter == 'pico-speaker')
		{
			skipDance = true;
			loadMappedAnims();
			playAnim("shoot1");
		}
		
		if (isPlayer)
		{

			flipX = !flipX;
			if (!curCharacter.contains('bf') && !wasPlayer)
				swapAnimations();
		}
		else 
		{
			if (curCharacter.contains('bf') || wasPlayer)
				swapAnimations();
		}
	}

	public function reloadAnimation() {
		if(animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;
				if(animIndices != null && animIndices.length > 0) {
					animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				} else {
					animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if(anim.offsets_player != null && anim.offsets_player.length > 1) {
					addOffsetPlayer(anim.anim, anim.offsets_player[0], anim.offsets_player[1]);
				}
				else if(anim.offsets != null && anim.offsets.length > 1 && anim.offsets_player == null) {
					addOffsetPlayer(anim.anim, anim.offsets[0], anim.offsets[1]);
				}

				if(anim.offsets != null && anim.offsets.length > 1) {
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
			}
		} else {
			quickAnimAdd('idle', 'BF idle dance');
		}
	}

	public function swapAnimations()
	{
		if (animation.getByName('singRIGHT') != null)
		{
			var oldRight = animation.getByName('singRIGHT').frames;
			animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
			animation.getByName('singLEFT').frames = oldRight;
		}

		if (animation.getByName('singRIGHT-loop') != null)
		{
			var oldRight = animation.getByName('singRIGHT-loop').frames;
			animation.getByName('singRIGHT-loop').frames = animation.getByName('singLEFT-loop').frames;
			animation.getByName('singLEFT-loop').frames = oldRight;
		}

		if (animation.getByName('singRIGHTmiss') != null)
		{
			var oldMiss = animation.getByName('singRIGHTmiss').frames;
			animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
			animation.getByName('singLEFTmiss').frames = oldMiss;
		}

		if (animation.getByName('singRIGHTmiss-loop') != null)
		{
			var oldMiss = animation.getByName('singRIGHTmiss-loop').frames;
			animation.getByName('singRIGHTmiss-loop').frames = animation.getByName('singLEFTmiss-loop').frames;
			animation.getByName('singLEFTmiss-loop').frames = oldMiss;			
		}

		if (animation.getByName('singRIGHT-alt') != null)
		{
			var oldRight = animation.getByName('singRIGHT-alt').frames;
			animation.getByName('singRIGHT-alt').frames = animation.getByName('singLEFT-alt').frames;
			animation.getByName('singLEFT-alt').frames = oldRight;
		}

		if (animation.getByName('singRIGHT-alt-loop') != null)
		{
			var oldRight = animation.getByName('singRIGHT-alt-loop').frames;
			animation.getByName('singRIGHT-alt-loop').frames = animation.getByName('singLEFT-alt-loop').frames;
			animation.getByName('singLEFT-alt-loop').frames = oldRight;
		}		
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && animation.curAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed * PlayState.instance.playbackRate;
				if(heyTimer <= 0)
				{
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if(curCharacter == 'pico-speaker')
			{
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}

			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;			

			if (isPlayer)
			{
				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
				{
					if(danceIdle)
						playAnim('danceLeft' + idleSuffix, true, false, 10);
					else
						playAnim('idle' + idleSuffix, true, false, 10);
				}				
			}

			animation.finishCallback = function(name:String) {
				if(animation.getByName(name + '-loop') != null)
					playAnim(name + '-loop');
			};
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(animation.getByName('idle' + idleSuffix) != null) {
					playAnim('idle' + idleSuffix);
			}
		}
	}
	
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		//idk this is sort of better
		//if(animation.name == AnimName) 

		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = getOffset(AnimName);
		if (getExistsOffsets(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function getOffset(name:String){
		if(isPlayer)
			return animOffsetsPlayer.get(name);
		else if(animOffsets.exists(name)) 
			return animOffsets.get(name);
		return null;
	}

	public function getExistsOffsets(name:String):Bool {
		if(isPlayer)
			return animOffsetsPlayer.exists(name);
		else
			return animOffsets.exists(name);
	}

	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function addOffsetPlayer(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsetsPlayer[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}