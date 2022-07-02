package;

import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var isWinner:Bool = false;
	private var isEmotionStuff:Bool = false;
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

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:FlxGraphic = Paths.image(name);

			loadGraphic(file); //Load stupidly first for getting the file size
			if(file.width == 450)
			{
				loadGraphic(file, true, Math.floor(width / 3), Math.floor(height)); //Then load it fr
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				iconOffsets[2] = (width - 150) / 2;
				updateHitbox();
	
				animation.add(char, [0, 1, 2], 0, false, isPlayer);
				isWinner = true;
				isEmotionStuff = false;
			}
			else if(file.width == 750)
			{
				loadGraphic(file, true, Math.floor(width / 5), Math.floor(height)); //Then load it fr
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				iconOffsets[2] = (width - 150) / 2;
				iconOffsets[3] = (width - 150) / 2;
				iconOffsets[4] = (width - 150) / 2;
				updateHitbox();
				animation.add(char, [0, 1, 2, 3, 4], 0, false, isPlayer);
				isWinner = false;
				isEmotionStuff = true;
			}
			else
			{
				loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); //Then load it fr
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				updateHitbox();
	
				animation.add(char, [0, 1], 0, false, isPlayer);
				isWinner = false;
				isEmotionStuff = false;
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

	public function updateAnims(health:Float) {
		if(isWinner)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else if (health > 80)
				animation.curAnim.curFrame = 2;
			else
				animation.curAnim.curFrame = 0;
		}
		else if(isEmotionStuff)
		{
			if (health < 20)
				animation.curAnim.curFrame = 1;
			else if (health > 20 && health < 30)
				animation.curAnim.curFrame = 2;
			else if (health > 70 && health < 80)
				animation.curAnim.curFrame = 3;
			else if (health > 80)
				animation.curAnim.curFrame = 4;
			else
				animation.curAnim.curFrame = 0;
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
