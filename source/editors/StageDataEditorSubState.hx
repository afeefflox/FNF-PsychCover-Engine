package editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import haxe.Json;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
using StringTools;

class StageDataEditorSubState extends MusicBeatSubstate
{
    var bg:FlxSprite;
	var iconBoyfriend:HealthIcon;
    var iconGF:HealthIcon;
    var iconDad:HealthIcon;

    var characterDad:String = 'dad';
    var characterBF:String = 'bf';
    var characterGF:String = 'gf';
	var stage:String;
    var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
    private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

    public function new()
    {
        super();
        
		FlxG.mouse.visible = true;
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

        loadCharacterList();

        var player1DropDown:FlxUIDropDownMenuCustom = new FlxUIDropDownMenuCustom(200, 180, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			characterBF = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = characterBF;
		blockPressWhileScrolling.push(player1DropDown);
        add(player1DropDown);

		var boyfriendText:Alphabet = new Alphabet(0, player1DropDown.y - 100, 'Boyfriend', true);
		boyfriendText.scaleX = 0.6;
		boyfriendText.scaleY = 0.6;
		boyfriendText.screenCenter(X);
		boyfriendText.x = player1DropDown.x - 90;
		add(boyfriendText);

        iconBoyfriend = new HealthIcon('bf', false);
        iconBoyfriend.x = player1DropDown.x;
        iconBoyfriend.y = player1DropDown.y + 50;
        add(iconBoyfriend);
        
        var player2DropDown:FlxUIDropDownMenuCustom = new FlxUIDropDownMenuCustom(player1DropDown.x + 200, 180, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			characterDad = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = characterDad;
		blockPressWhileScrolling.push(player2DropDown);
        add(player2DropDown);

		var dadText:Alphabet = new Alphabet(player2DropDown.x - 100, player2DropDown.y - 100, 'Opponent', true);
		dadText.scaleX = 0.6;
		dadText.scaleY = 0.6;
		dadText.screenCenter(X);
		dadText.x = player2DropDown.x + 100;
		add(dadText);

        iconDad = new HealthIcon('dad', false);
        iconDad.x = player2DropDown.x;
        iconDad.y = player2DropDown.y + 50;
        add(iconDad);

        var player3DropDown:FlxUIDropDownMenuCustom = new FlxUIDropDownMenuCustom(player2DropDown.x + 200, 180, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			characterGF = characters[Std.parseInt(character)];
			updateHeads();
		});
		player3DropDown.selectedLabel = characterGF;
		blockPressWhileScrolling.push(player3DropDown);
        add(player3DropDown);

		var gfText:Alphabet = new Alphabet(player3DropDown.x - 100, player3DropDown.y - 100, 'Girlfriend', true);
		gfText.scaleX = 0.6;
		gfText.scaleY = 0.6;
		gfText.screenCenter(X);
		gfText.x = player3DropDown.x + 200;
		add(gfText);

        iconGF = new HealthIcon('gf', false);
        iconGF.x = player3DropDown.x;
        iconGF.y = player3DropDown.y + 90;
        add(iconGF);
    }

    function updateHeads() {
        var healthIconP1:String = loadHealthIconFromCharacter(characterBF);
		var healthIconP2:String = loadHealthIconFromCharacter(characterDad);
        var healthIconP3:String = loadHealthIconFromCharacter(characterGF);
        iconGF.changeIcon(healthIconP3);
        iconDad.changeIcon(healthIconP2);
        iconBoyfriend.changeIcon(healthIconP1);
    }

    function loadHealthIconFromCharacter(char:String) {
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end

		var json:Character.CharacterFile = cast Json.parse(rawJson);
		return json.healthicon;
	}

    override function update(elapsed:Float)
    {
        bg.alpha += elapsed * 1.5;
		if(bg.alpha > 0.6) bg.alpha = 0.6;

		var blockInput:Bool = false;
        if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

        if (!blockInput)
        {
            if(FlxG.keys.justPressed.ESCAPE) 
            {
                close();
            }

            if (FlxG.keys.justPressed.ENTER)
            {
                LoadingState.loadAndSwitchState(new StageDataEditorState(characterBF, characterDad, characterGF, Stage.DEFAULT_STAGE, false));
            }

            if(FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER) 
            {
                FlxG.mouse.visible = false;
            }
        }
        super.update(elapsed);
    }

    function loadCharacterList() {
        #if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		#else
		var directories:Array<String> = [Paths.getPreloadPath('characters/')];
		#end

		var tempMap:Map<String, Bool> = new Map<String, Bool>();

		for (i in 0...characters.length) {
			tempMap.set(characters[i], true);
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck)) {
							tempMap.set(charToCheck, true);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end
    }
}