package editors;

#if desktop
import Discord.DiscordClient;
#end
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import Stage;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;
import StageData;
import flixel.math.FlxPoint;
import flixel.util.FlxCollision;
import flixel.system.FlxSound;
#if MODS_ALLOWED
import sys.FileSystem;
#end
using StringTools;

class StageDataEditorState extends MusicBeatState {

    var stageGroup:FlxTypedGroup<FlxBasic>;
	var boyfriendLayersGroup:FlxTypedGroup<FlxBasic>;
	var gfLayersGroup:FlxTypedGroup<FlxBasic>;
	var dadLayersGroup:FlxTypedGroup<FlxBasic>;
    var pauseMusic:FlxSound;

    public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

    public var positions:Map<String,FlxPoint> = [
		"boyfriend"=> FlxPoint.get(770, 100),
		"dad"=> FlxPoint.get(100, 100),
		"gf"=> FlxPoint.get(400,130)
	];

    public var camera_position:Map<String,FlxPoint> = [
		"boyfriend"=> FlxPoint.get(0, 0),
		"dad"=> FlxPoint.get(0, 0),
		"gf"=> FlxPoint.get(0, 0),
	];

    public var groups:Map<String,FlxSpriteGroup> = [
		"boyfriend"=> new FlxSpriteGroup(770, 100),
		"dad"=> new FlxSpriteGroup(100, 100),
		"gf"=>  new FlxSpriteGroup(400,130)
	];

    //Stage Data
    var stageData:StageFile;
    

    //Character and Stage
    var stage:Stage;
    public var boyfriend:Character;
    public var gf:Character;
    public var dad:Character;

    //Stage Scripts Shits
    public var luaArray:Array<FunkinStage> = [];
    public var haxeArray:Array<FunkinHaxe> = [];

    var charBF:String = 'bf';
    var charGF:String = 'gf';
    var charDad:String = 'dad';


    var gridBG:FlxSprite;
    var cameraFollowPointer:FlxSprite;

    var layerAdded:Bool = false;
    var noStage:Bool;
    var stageCounter:Int;
    var confirmAdded:Bool = false;

    var UI_box:FlxUITabMenu;
	var UI_stagebox:FlxUITabMenu;

    private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;
    var camFollow:FlxObject;
    var goToPlayState:Bool = true;
    var daStage:String;
    var stageList:Array<String> = [];
    var characterList:Array<String> = [];
    var dumbTexts:FlxTypedGroup<FlxText>;
    var oldMousePosX:Int;
	var oldMousePosY:Int;

    var curChar:Character;
	var curCharIndex:Int = 0;
    var curAnim:Int = 0;
	var curCharString:String;
	var curChars:Array<Character>;
    var curGroups:Array<FlxSpriteGroup>;

    //Stage Flies
    var cameraPositions:Array<FlxPoint>;
    var curCameraPosition:FlxPoint;
    var charsPosition:Array<FlxPoint>;
    var curCharPosition:FlxPoint;
    var charsGroup:Array<FlxSpriteGroup>;
    var curGroup:FlxSpriteGroup;
    public static var songName:String = '';

    private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

    public function new(?daBoyfriend:String = 'bf', ?daOpponent:String = 'dad', ?daGF:String = 'gf', ?daStage:String = 'stage', goToPlayState:Bool = true)
    {
        super();
        this.charBF = daBoyfriend;
        this.charDad = daOpponent;
        this.charGF = daGF;
        this.daStage = daStage;
        this.goToPlayState = goToPlayState;
    }

    override function create()
    {
		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

        gridBG = FlxGridOverlay.create(25, 25);
        add(gridBG);

        stageGroup = new FlxTypedGroup<FlxBasic>();
        add(stageGroup);

        // Characters
		gf = new Character(0, 0, charGF);
        gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
        groups.get('gf').add(gf);
        gfLayersGroup = new FlxTypedGroup<FlxBasic>();
        add(groups.get('gf'));
        add(gfLayersGroup);

        dad = new Character(0, 0, charDad);
        dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];
        groups.get('dad').add(dad);
        add(groups.get('dad'));
        dadLayersGroup = new FlxTypedGroup<FlxBasic>();
        add(dadLayersGroup);

		boyfriend = new Character(0, 0, charBF, true);
        boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
        groups.get('boyfriend').add(boyfriend);
        add(groups.get('boyfriend'));
        boyfriendLayersGroup = new FlxTypedGroup<FlxBasic>();
        add(boyfriendLayersGroup);

        loadStage();

        curChars = [dad, boyfriend, gf];
		curChar = curChars[curCharIndex];

        charsPosition = [positions.get('dad'), positions.get('boyfriend'), positions.get('gf')];
        curCharPosition = charsPosition[curCharIndex];

        curGroups = [groups.get('dad'), groups.get('boyfriend'), groups.get('gf')];
        curGroup = curGroups[curCharIndex];

        cameraPositions = [camera_position.get('dad'), camera_position.get('boyfriend'), camera_position.get('gf')];
        curCameraPosition = cameraPositions[curCharIndex];

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];
        genBoyPos();

        camFollow = new FlxObject(0, 0, 2, 2);
        camFollow.screenCenter();
        add(camFollow);

        var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

        FlxG.camera.follow(camFollow);

        var tabs = [
            {name: 'Settings', label: 'Settings'},
        ];

        UI_box = new FlxUITabMenu(null, tabs, true);
        UI_box.cameras = [camMenu];
        UI_box.resize(250, 120);
        UI_box.x = FlxG.width - 275;
        UI_box.y = 25;
        UI_box.scrollFactor.set();

        var tabs = [
            {name: 'Stage', label: 'Stage'},
        ];

        UI_stagebox = new FlxUITabMenu(null, tabs, true);
        UI_stagebox.cameras = [camMenu];
        UI_stagebox.resize(350, 350);
        UI_stagebox.x = UI_box.x - 100;
        UI_stagebox.y = UI_box.y + UI_box.height;
        UI_stagebox.scrollFactor.set();
        add(UI_stagebox);
        add(UI_box);

        addSettingsUI();
        addStageUI();
        UI_stagebox.selected_tab_id = 'Stage';

        FlxG.mouse.visible = true;
        reloadStageOptions();

        super.create();
    }

    var stageDropDown:FlxUIDropDownMenuCustom;
    var stageNameInputText:FlxUIInputText;
    var check_isPixelStage:FlxUICheckBox;
    var check_isTypingMode:FlxUICheckBox;
    function addSettingsUI() {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

        check_isPixelStage = new FlxUICheckBox(10, 60, null, null, "Pixel Stage", 100);
		check_isPixelStage.checked = stageData.isPixelStage;
		check_isPixelStage.callback = function()
		{
			stageData.isPixelStage = !stageData.isPixelStage;
		};

        stageDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(stage:String)
        {
            daStage = stageList[Std.parseInt(stage)];
            loadStage();
            updatePresence();
            reloadStageDropDown();
        });
        stageDropDown.selectedLabel = daStage;
        reloadStageDropDown();
        blockPressWhileScrolling.push(stageDropDown);

        var reloadStage:FlxButton = new FlxButton(140, 20, "Reload Stage", function()
        {
            loadStage();
            reloadStageDropDown();
        });

        tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 0, 'Stage:'));
		tab_group.add(check_isPixelStage);
		tab_group.add(reloadStage);
		tab_group.add(stageDropDown);
		UI_box.addGroup(tab_group);
    }


    var cameraZoomStepper:FlxUINumericStepper;
    var zoominputtext:FlxUIInputText;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;
    var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
    var cameraSpeedStepper:FlxUINumericStepper;
    var check_hiddenGF:FlxUICheckBox;
    function addStageUI() {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Stage";

        var saveStuff:FlxButton = new FlxButton(240, 20, "Save Stage", function() {
            saveStage();
        });

        cameraZoomStepper = new FlxUINumericStepper(15, saveStuff.y + 20, 0.1, 1, 1, 1.05, 1);
        blockPressWhileTypingOnStepper.push(cameraZoomStepper);

        positionXStepper = new FlxUINumericStepper(15, cameraZoomStepper.y + 30, 10, curCharPosition.x, -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, curCharPosition.y, -9000, 9000, 0);
        blockPressWhileTypingOnStepper.push(positionXStepper);
        blockPressWhileTypingOnStepper.push(positionYStepper);

        positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, curCameraPosition.x, -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, curCameraPosition.y, -9000, 9000, 0);
        blockPressWhileTypingOnStepper.push(positionCameraXStepper);
        blockPressWhileTypingOnStepper.push(positionCameraYStepper);

        cameraSpeedStepper = new FlxUINumericStepper(15, positionCameraYStepper.y + 50, 1, curCameraPosition.x, 0, 9000, 0);
        blockPressWhileTypingOnStepper.push(cameraSpeedStepper);

        check_hiddenGF = new FlxUICheckBox(15, cameraSpeedStepper.y + 60, null, null, "Hide GF", 100);
		check_hiddenGF.checked = !gf.visible;
        if(stageData.hide_girlfriend) check_hiddenGF.checked = !check_hiddenGF.checked;
		check_hiddenGF.callback = function()
		{
			stageData.hide_girlfriend = !stageData.hide_girlfriend;
            gf.visible = !gf.visible;
		};

        tab_group.add(saveStuff);
        tab_group.add(cameraZoomStepper);
        tab_group.add(positionXStepper);
        tab_group.add(positionYStepper);
        tab_group.add(positionCameraXStepper);
        tab_group.add(positionCameraYStepper);
        tab_group.add(cameraSpeedStepper);
        tab_group.add(check_hiddenGF);
        tab_group.add(new FlxText(15, cameraZoomStepper.y - 18, 0, 'Default Cam Zoom:'));
        tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Position Character X/Y:'));
        tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Character Camera X/Y:'));
        tab_group.add(new FlxText(cameraSpeedStepper.x, cameraSpeedStepper.y - 18, 0, 'Camera Speed:'));
        UI_stagebox.addGroup(tab_group);
    }


    /*var player1DropDown:FlxUIDropDownMenuCustom;
    var gfVersionDropDown:FlxUIDropDownMenuCustom;
    var player2DropDown:FlxUIDropDownMenuCustom;
    function addCharactersUI() {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Characters";


        player1DropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
        {
			charBF = characterList[Std.parseInt(character)];
            loadChar('boyfriend', charBF);
            reloadCharacterDropDown(player1DropDown, charBF);
        });
        characterDropDown(player1DropDown, charBF);

        gfVersionDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player1DropDown.y + 60, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
        {
			charGF = characterList[Std.parseInt(character)];
            loadChar('gf', charGF);
            reloadCharacterDropDown(gfVersionDropDown, charGF);
        });
        characterDropDown(gfVersionDropDown, charGF);
        
        player2DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, gfVersionDropDown.y + 60, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
        {
			charDad = characterList[Std.parseInt(character)];
            loadChar('dad', charDad);
            reloadCharacterDropDown(player2DropDown, charDad);
        });
        characterDropDown(player2DropDown, charDad);

		tab_group.add(player2DropDown);
		tab_group.add(gfVersionDropDown);
		tab_group.add(player1DropDown);
		tab_group.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
        UI_stagebox.addGroup(tab_group);
    }

    function characterDropDown(FlxUIDropDown:FlxUIDropDownMenuCustom, daString:String) {
        FlxUIDropDown.selectedLabel = daString;
		reloadCharacterDropDown(FlxUIDropDown, daString);
		blockPressWhileScrolling.push(FlxUIDropDown);
    }

	function reloadCharacterDropDown(FlxUIDropDown:FlxUIDropDownMenuCustom, daString:String) {
		var charsLoaded:Map<String, Bool> = new Map();
		#if MODS_ALLOWED
		characterList = [];
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(!charsLoaded.exists(charToCheck)) {
							characterList.push(charToCheck);
							charsLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

		FlxUIDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		FlxUIDropDown.selectedLabel = daString;
	}

    function loadChar(character:String, newCharacter:String) {
		var characterMap = boyfriendMap;
        var char:Character = boyfriend;
		switch(character) {
			case 'dad':
                if(!dadMap.exists(newCharacter)) {
                    var newChar:Character = new Character(0, 0, newCharacter, char.isPlayer);
                    newChar.x += newChar.positionArray[0];
                    newChar.y += newChar.positionArray[1];
                    groups.get()).add(newChar);
                    newChar.alpha = 0.00001;
                }
                char = dad;
			case 'gf':
				characterMap = gfMap;
                char = gf;
		}


        
        var lastAlpha:Float = char.alpha;
        char.alpha = 0.00001;
        char = characterMap.get(newCharacter);
        char.alpha = lastAlpha;
    }*/

    function updatePresence() {
        #if private
        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Stage Data Editor", "Stage: Unknown");
		#end      
        #else
        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Stage Data Editor", "Stage: " + daStage);
		#end      
        #end
  
    }

    function loadStage() {
        var i:Int = stageGroup.members.length-1;
		while(i >= 0) {
			var memb:FlxBasic = stageGroup.members[i];
			if(memb != null) {
				memb.kill();
				stageGroup.remove(memb);
				memb.destroy();
			}
			--i;
		}

        var g:Int = gfLayersGroup.members.length-1;
        while(g >= 0) {
			var memb:FlxBasic = gfLayersGroup.members[i];
			if(memb != null) {
				memb.kill();
				gfLayersGroup.remove(memb);
				memb.destroy();
			}
			--g;
		}

        var d:Int = dadLayersGroup.members.length-1;
        while(d >= 0) {
			var memb:FlxBasic = dadLayersGroup.members[i];
			if(memb != null) {
				memb.kill();
				dadLayersGroup.remove(memb);
				memb.destroy();
			}
			--d;
		}

        var b:Int = boyfriendLayersGroup.members.length-1;
        while(b >= 0) {
			var memb:FlxBasic = boyfriendLayersGroup.members[i];
			if(memb != null) {
				memb.kill();
				boyfriendLayersGroup.remove(memb);
				memb.destroy();
			}
			--b;
		}

        stageGroup.clear();
        gfLayersGroup.clear();
		dadLayersGroup.clear();
		boyfriendLayersGroup.clear();

        stageData = StageData.getStageFile(daStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,
			
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

        stage = new Stage(daStage);
        stageGroup.add(stage);
        gfLayersGroup.add(stage.layers.get("gf"));
		dadLayersGroup.add(stage.layers.get("dad"));
		boyfriendLayersGroup.add(stage.layers.get("boyfriend"));

        reloadStageOptions();
    }

    function reloadStageOptions() {
		if(UI_stagebox != null) {
			cameraZoomStepper.value = stageData.defaultZoom;
			check_isPixelStage.checked = stageData.isPixelStage;

            if(stageData.camera_speed != null)  cameraSpeedStepper.value = stageData.camera_speed;

            if(stageData.camera_boyfriend != null)
            {
                camera_position.get('boyfriend').x = stageData.camera_boyfriend[0];
                camera_position.get('boyfriend').y = stageData.camera_boyfriend[1];
            }

            if(stageData.camera_opponent != null)
            {
                camera_position.get('dad').x = stageData.camera_opponent[0];
                camera_position.get('dad').y = stageData.camera_opponent[1];
            }

            if(stageData.camera_girlfriend != null)
            {
                camera_position.get('gf').x = stageData.camera_girlfriend[0];
                camera_position.get('gf').y = stageData.camera_girlfriend[1];
            }

            positions.get('boyfriend').x = stageData.boyfriend[0];
            positions.get('boyfriend').y = stageData.boyfriend[1];

            positions.get('dad').x = stageData.opponent[0];
            positions.get('dad').y = stageData.opponent[1];

            positions.get('gf').x = stageData.girlfriend[0];
            positions.get('gf').y = stageData.girlfriend[1];

            groups.get('boyfriend').setPosition(positions.get('boyfriend').x, positions.get('boyfriend').y);
            groups.get('dad').setPosition(positions.get('dad').x, positions.get('dad').y);
            groups.get('gf').setPosition(positions.get('gf').x, positions.get('gf').y);

            genBoyPos();
			updatePresence();
            updatePointerPos();
		}
	}

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
        if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
           if(sender == cameraZoomStepper)
            {
                FlxG.camera.zoom = sender.value;
            }
            else if(sender == positionXStepper)
            {
                curGroup.x = sender.value;
                curCharPosition.x = sender.value;
                updatePointerPos();
                genBoyPos();
            }
            else if(sender == positionYStepper)
            {
                curGroup.y = sender.value;
                curCharPosition.y = sender.value;
                updatePointerPos();
                genBoyPos();
            }
            else if(sender == positionCameraXStepper)
            {
                curCameraPosition.x = sender.value;
                updatePointerPos();
                genBoyPos();
            }
            else if(sender == positionCameraYStepper)
            {
                curCameraPosition.y = sender.value;
                updatePointerPos();
                genBoyPos();
            }            
        }
    }

    function getNextChar()
    {
        ++curCharIndex;
        if (curCharIndex >= curChars.length && curCharIndex >= charsPosition.length)
        {
            curChar = curChars[0];
            curCharPosition = charsPosition[0];
            curCameraPosition = cameraPositions[0];
            curGroup = curGroups[0];
            curCharIndex = 0;
        }
        else
            curChar = curChars[curCharIndex];
            curCharPosition = charsPosition[curCharIndex];
            curCameraPosition = cameraPositions[curCharIndex];
            curGroup = curGroups[curCharIndex];
    }

    function updatePointerPos() {
        //I don't GET THIS IS THING WON'T WORK
        if(curChar == boyfriend)
        {
            cameraFollowPointer.setPosition(curChar.getMidpoint().x - 100, curChar.getMidpoint().y - 100);
            cameraFollowPointer.x -= curChar.playerCameraPosition[0] - curCameraPosition.x;
            cameraFollowPointer.y += curChar.playerCameraPosition[1] + curCameraPosition.y;
        }
        else if(curChar == gf)
        {
            cameraFollowPointer.setPosition(curChar.getMidpoint().x, curChar.getMidpoint().y);
            cameraFollowPointer.x += curChar.cameraPosition[0] + curCameraPosition.x;
            cameraFollowPointer.y += curChar.cameraPosition[1] + curCameraPosition.y;
        }
        else
        {
            cameraFollowPointer.setPosition(curChar.getMidpoint().x + 150, curChar.getMidpoint().y - 100);
            cameraFollowPointer.x += curChar.cameraPosition[0] + curCameraPosition.x;
            cameraFollowPointer.y += curChar.cameraPosition[1] + curCameraPosition.y;
        }
	}

    function genBoyPos()
    {
        var i:Int = dumbTexts.members.length-1;
        while(i >= 0) {
            var memb:FlxText = dumbTexts.members[i];
            if(memb != null) {
                memb.kill();
                dumbTexts.remove(memb);
                memb.destroy();
            }
            --i;
        }
        dumbTexts.clear();

        for (i in 0...12)
        {
            var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
            text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            text.scrollFactor.set();
            text.borderSize = 2;
            dumbTexts.add(text);
            text.cameras = [camHUD];

            if(i > 1)
            {
                text.y += 24;
            }
        }

        for (i in 0...dumbTexts.length)
        {
            switch(i)
            {
                case 0: dumbTexts.members[i].text = 'Boyfriend Positions:';
                case 1: dumbTexts.members[i].text = '[' + groups.get("boyfriend").x + ', ' + groups.get("boyfriend").y + ']';
                case 2: dumbTexts.members[i].text = 'GirlFriend Positions:';
                case 3: dumbTexts.members[i].text = '[' + groups.get("gf").x + ', ' + groups.get("gf").y + ']';
                case 4: dumbTexts.members[i].text = 'Opponent Positions:';
                case 5: dumbTexts.members[i].text = '[' + groups.get("dad").x + ', ' + groups.get("dad").y + ']';
                case 6: dumbTexts.members[i].text = 'Boyfriend Camera Positions:';
                case 7: dumbTexts.members[i].text = '[' + camera_position.get("boyfriend").x  + ', ' +  camera_position.get("boyfriend").y  + ']';
                case 8: dumbTexts.members[i].text = 'Girlfriend Camera Positions:';
                case 9: dumbTexts.members[i].text = '[' + camera_position.get("gf").x  + ', ' +  camera_position.get("gf").y  + ']';
                case 10: dumbTexts.members[i].text = 'Opponent Camera Positions:';
                case 11: dumbTexts.members[i].text = '[' + camera_position.get("dad").x + ', ' +  camera_position.get("dad").y + ']';
            }
        }
    }
    function reloadStageDropDown() 
    {
        var stagesLoaded:Map<String, Bool> = new Map();
        
        #if MODS_ALLOWED
        stageList = [];
        var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Paths.currentModDirectory + '/stages/'), Paths.getPreloadPath('stages/')];
        for (i in 0...directories.length) {
            var directory:String = directories[i];
            if(FileSystem.exists(directory)) {
                for (file in FileSystem.readDirectory(directory)) {
                    var path = haxe.io.Path.join([directory, file]);
                    if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
                        var charToCheck:String = file.substr(0, file.length - 5);
                        if(!stagesLoaded.exists(charToCheck)) {
                            stageList.push(charToCheck);
                            stagesLoaded.set(charToCheck, true);
                        }
                    }
                }
            }
        }
        #else
        stageList = CoolUtil.coolTextFile(Paths.txt('stageList'));
        #end

        stageDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(stageList, true));
        stageDropDown.selectedLabel = daStage;        
    }
    
    var colorSine:Float = 0;
    override function update(elapsed:Float)
    {
		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if(leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}
               
        if (!blockInput) {
            FlxG.sound.muteKeys = TitleState.muteKeys;
            FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
            FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
            
            if (FlxG.keys.justPressed.ENTER) getNextChar();

            if (FlxG.keys.justPressed.ESCAPE) {
                if(goToPlayState) {
                    MusicBeatState.switchState(new PlayState());
                } else {
                    MusicBeatState.switchState(new editors.MasterEditorMenu());
                    FlxG.sound.playMusic(Paths.music('freakyMenu'));
                }
                autoSaveStage();
                FlxG.mouse.visible = false;
                return;
            }

            if (FlxG.keys.justPressed.R) {
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
               
			}
            if (FlxG.keys.pressed.Q || FlxG.keys.pressed.E) {
                cameraZoomStepper.value = FlxG.camera.zoom;
            }


			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

            var controlArray:Array<Bool> = [FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.DOWN, FlxG.keys.justPressed.UP];
			for (i in 0...controlArray.length) {
                if(controlArray[i]) {
                    var holdShift = FlxG.keys.pressed.SHIFT;
                    var multiplier = 1;
                    if (holdShift)
                        multiplier = 10;

                    var arrayVal = 0;
                    if(i > 1) arrayVal = 1;

                    var negaMult:Int = 1;
                    if(i % 2 == 1) negaMult = -1;


                    var postions:Array<Float> = [curCharPosition.x, curCharPosition.y];
                    postions[arrayVal] += negaMult * multiplier;

                    curGroup.x = postions[0];
                    curCharPosition.x = postions[0];

                    curGroup.y = postions[1];
                    curCharPosition.y = postions[1];
                    

                    positionXStepper.value = postions[0]; 
                    positionYStepper.value = postions[1]; 
                    
                    updatePointerPos();
                    genBoyPos();
                }
            }
        }
        super.update(elapsed);
    }

    var _file:FileReference;

    function onSaveComplete(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.notice("Successfully saved file.");            
    }
    
    /**
    * Called when the save file dialog is cancelled.
    */
    function onSaveCancel(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;           
    }
    
    /**
    * Called if there is an error while saving the gameplay recording.
    */
    function onSaveError(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.error("Problem saving file"); 
    }

    function autoSaveStage() {
        FlxG.save.data.autosave = Json.stringify({
            "directory": null,
            "defaultZoom": cameraZoomStepper.value,
            "isPixelStage": check_isPixelStage.checked,
        
            "boyfriend": [positions.get('boyfriend').x, positions.get('boyfriend').y],
            "girlfriend": [positions.get('gf').x, positions.get('gf').y],
            "opponent": [positions.get('dad').x, positions.get('dad').y],
            "hide_girlfriend": check_hiddenGF.checked,

            "camera_boyfriend":[camera_position.get('boyfriend').x, camera_position.get('boyfriend').y],
            "camera_opponent": [camera_position.get('dad').x, camera_position.get('dad').y],
            "camera_girlfriend": [camera_position.get('gf').x, camera_position.get('gf').y],
            "camera_speed": cameraSpeedStepper.value,
		});
		FlxG.save.flush();
    }
    
    function saveStage() {
        var json = {
            "directory": null,
            "defaultZoom": cameraZoomStepper.value,
            "isPixelStage": check_isPixelStage.checked,
        
            "boyfriend": [positions.get('boyfriend').x, positions.get('boyfriend').y],
            "girlfriend": [positions.get('gf').x, positions.get('gf').y],
            "opponent": [positions.get('dad').x, positions.get('dad').y],
            "hide_girlfriend": check_hiddenGF.checked,

            "camera_boyfriend":[camera_position.get('boyfriend').x, camera_position.get('boyfriend').y],
            "camera_opponent": [camera_position.get('dad').x, camera_position.get('dad').y],
            "camera_girlfriend": [camera_position.get('gf').x, camera_position.get('gf').y],
            "camera_speed": cameraSpeedStepper.value,
        };

        var data:String = Json.stringify(json, "\t");
    
        if (data.length > 0)
        {
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data, daStage + ".json");
        }
    }
}