package;

import flixel.FlxSprite;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isAnimated:Bool = false;
	private var isPlayer:Bool = false;
	public var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old');
		else changeIcon('bf');
	}

	public var iconOffsets:Array<Float> = [0, 0];
	var spriteType = "bitmapData";
	public function changeIcon(char:String) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face';

			#if MODS_ALLOWED
			var modXmlToFind:String = Paths.modsXml(name);
			var xmlToFind:String = Paths.getPath('images/' + name + '.xml', TEXT);
			if (FileSystem.exists(modXmlToFind) || FileSystem.exists(xmlToFind) || Assets.exists(xmlToFind))
			#else
			if (Assets.exists(Paths.getPath('images/' + name + '.xml', TEXT)))
			#end
			{
				spriteType = "sparrow";
			}

			#if MODS_ALLOWED
			var modImageToFind:String = Paths.modsImages(name + '-3');
			var imageToFind:String = Paths.getPath('images/' + name + '-3' + '.png', IMAGE);
			if (FileSystem.exists(modImageToFind) || FileSystem.exists(imageToFind) || Assets.exists(imageToFind))
			#else
			if (Assets.exists(Paths.getPath('images/' + name + '-3' + '.png', IMAGE)))
			#end
			{
				spriteType = "icon3";
			}

			switch (spriteType){
				case "bitmapData":
					var file:Dynamic = Paths.image(name);
					loadGraphic(file); //Load stupidly first for getting the file size
					loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); //Then load it fr
					iconOffsets[0] = (width - 150) / 2;
					iconOffsets[1] = (width - 150) / 2;
					updateHitbox();
		
					animation.add(char, [0, 1], 0, false, isPlayer);
				case "icon3":
					var file:Dynamic = Paths.image(name + '-3');
					loadGraphic(file); //Load stupidly first for getting the file size
					loadGraphic(file, true, Math.floor(width / 3), Math.floor(height)); //Then load it fr
					iconOffsets[0] = (width - 150) / 2;
					iconOffsets[1] = (width - 150) / 2;
					iconOffsets[2] = (width - 150) / 2;
					animation.add(char, [0, 1, 2], 0, false, isPlayer);
					updateHitbox();
				case "sparrow":
					frames = Paths.getSparrowAtlas(name);
					animation.addByPrefix(char, 'icon', 24, true, isPlayer);
			}

			animation.play(char);
			this.char = char;

			antialiasing = ClientPrefs.globalAntialiasing;
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}

	public dynamic function updateAnim(health:Float){ // Dynamic to prevent having like 20 if statements
		if(spriteType == 'icon3')
		{
			if (health < 20) {
				animation.curAnim.curFrame = 1;
			} else if (health > 80) {
				animation.curAnim.curFrame = 2;
			} else {
				animation.curAnim.curFrame = 0;
			}
		}
		else
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else
				animation.curAnim.curFrame = 0;
		}

	}
}