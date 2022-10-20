package;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import openfl.events.IOErrorEvent;
import openfl.events.ErrorEvent;
import flixel.util.FlxColor;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import openfl.system.System;
#if sys
import sys.io.Process;
import sys.Http;
import sys.io.FileOutput;
import sys.FileSystem;
import sys.io.File;
#end
#if cpp
import cpp.vm.Thread;
#end
import openfl.events.Event;
import openfl.events.ProgressEvent;
import flixel.ui.FlxBar;
import flixel.FlxG;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLStream;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import flixel.group.FlxSpriteGroup;

using StringTools;

class DownloadState extends MusicBeatState
{
    public var fileList:Array<String> = [];
	public var baseURL:String;
	public var downloadedFiles:Int = 0;
	public var percentLabel:FlxText;
	public var currentFileLabel:FlxText;
	public var totalFiles:Int = 0;
    public var isError:Bool = false;
    public var loadBar:FlxSprite;
    var char:Character;

    public function new(baseURL:String = "http://raw.githubusercontent.com/afeefflox/FNF-PsychCover-Engine/main/", fileList:Array<String>) 
	{
		super();
		this.baseURL = baseURL;
		this.fileList = fileList;
		totalFiles = fileList.length;
	}

    var currentLoadedStream:URLLoader = null;
	var currentFile:String;

    function done() {
		downloadedFiles++;
		percentLabel.text = '${Math.floor(downloadedFiles / totalFiles * 100)}%';
        char.playAnim('hey');
		if (fileList.length > 0) {
			doFile();
		} else {
			applyUpdate();
		}
	}

    function downloadFile()
    {
        oldBytesLoaded = 0;
		var f = fileList.shift();
		currentFile = f;
		if (f == null) {
			applyUpdate();
			return;
		};
		if (FileSystem.exists('./_cache/$f') && FileSystem.stat('./_cache/$f').size > 0) { // prevents redownloading of the entire thing after it failed
			done();
			return;
		}
		var downloadStream = new URLLoader();
		currentLoadedStream = downloadStream;
		downloadStream.dataFormat = BINARY;

        var request = new URLRequest('$baseURL/$f'.replace(" ", "%20"));
		var good = true;
		var label1 = '(${totalFiles - fileList.length}/${totalFiles})';
		var label2 = '( - / - )';
		var maxLength:Int = Std.int(Math.max(label1.length, label2.length));
		while(label1.length < maxLength) label1 = " " + label1;
		while(label2.length < maxLength) label2 += " ";
		currentFileLabel.text = 'Downloading File: $f\n$label1 | $label2';

        downloadStream.addEventListener(IOErrorEvent.IO_ERROR, function(e) {
            if (e.text.contains("404")) {
				
				trace('File not found: $f');
				done();
            }
        });

        downloadStream.addEventListener(Event.COMPLETE, function(e) {
            var array = [];
			var dir = [for (k => e in (array = f.replace("\\", "/").split("/"))) if (k < array.length - 1) e].join("/");
			FileSystem.createDirectory('./_cache/$dir');
			var fileOutput:FileOutput = File.write('./_cache/$f', true);

			var data:ByteArray = new ByteArray();
			downloadStream.data.readBytes(data, 0, downloadStream.data.length - downloadStream.data.position);
			fileOutput.writeBytes(data, 0, data.length);
			fileOutput.flush();

			fileOutput.close();
			done();
        });

        downloadStream.addEventListener(ProgressEvent.PROGRESS, function(e) {
			var label1 = '(${totalFiles - fileList.length}/${totalFiles})';
			var label2 = '(${CoolUtil.getSizeLabel(Std.int(e.bytesLoaded))} / ${CoolUtil.getSizeLabel(Std.int(e.bytesTotal))})';
			
			var ll = CoolUtil.getSizeLabel(Std.int((e.bytesLoaded - oldBytesLoaded) / (t - oldTime)));
			percentLabel.text = '${[for(i in 0...ll.length) " "].join("")}     ${Math.floor(((downloadedFiles / totalFiles) + (e.bytesLoaded / e.bytesTotal / totalFiles)) * 100)}% (${ll}/s)';
			var maxLength:Int = Std.int(Math.max(label1.length, label2.length));
			while(label1.length < maxLength) label1 = " " + label1;
			while(label2.length < maxLength) label2 += " ";
			currentFileLabel.text = 'Downloading File: $f\n$label1 | $label2';
			
			oldTime = t;
			oldBytesLoaded = e.bytesLoaded;
		});

        downloadStream.load(request);
    }

    public function applyUpdate() {
		File.copy('Psych Cover Engine.exe', 'temp.exe');
		new Process('start /B temp.exe update', null);
		System.exit(0);
	}

    public override function create() {
        var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d);
		add(bg);


        char = new Character(370, 100, 'bf', true);
        char.x += char.positionArray[0];
		char.y += char.positionArray[1];
        add(char);

        loadBar  = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xffff16d2);
		loadBar.screenCenter(X);
		loadBar.antialiasing = ClientPrefs.globalAntialiasing;
		add(loadBar);

        super.create();
		FlxG.autoPause = false;
        doFile();
    }

    public override function update(elapsed:Float) {
        loadBar.scale.x += 0.5 * (fileList.length - loadBar.scale.x);
        super.update(elapsed);
    }
}

