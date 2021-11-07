package;

#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flash.system.Capabilities;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import openfl.Lib;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;

#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	#if (haxe >= "4.0.0")
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	#else
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, Dynamic>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	#end
	var hand:FlxSprite;
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var canHitPendulum:Bool = false;
	public var hitPendulum:Bool = false;
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	var isDownscroll:Bool = false;
	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;
	private static var resetSpriteCache:Bool = false;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	var whiteHandDone:Bool = false;

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var maxHealth:Float = 0;
	public var combo:Int = 0;

	public var celebiLayer:FlxTypedGroup<FlxSprite>;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = false;
	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;

	var missingnoOcean:FlxSprite;

	var botplaySine:Float = 0;
	var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;

	var trance:Float = 0;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var cameraCentered:Bool = false;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var foreground:BGSprite;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;
	var psyshockParticle:Character;
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var ghostMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var showCountdown:Bool = true;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var isMonoDead:Bool = false;
	private var luaArray:Array<FunkinLua> = [];

	//Achievement shit
	var keysPressed:Array<Bool> = [false, false, false, false];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	var pendulum:Pendulum;
	var tranceThing:FlxSprite;
	var tranceDeathScreen:FlxSprite;
	var pendulumShadow:FlxTypedGroup<FlxSprite>;

	var tranceActive:Bool = false;
	var tranceDrain:Bool = false;
	var tranceSound:FlxSound;
	var tranceCanKill:Bool = true;
	var pendulumDrain:Bool = true;
	var psyshockCooldown:Int = 80;
	var psyshocking:Bool = false;
	var keyboardTimer:Int = 8;
	var keyboard:FlxSprite;
	var skippedFirstPendulum:Bool = false;

	var unowning:Bool = false;

	override public function create()
	{
		#if MODS_ALLOWED
		Paths.destroyLoadedImages(resetSpriteCache);
		#end
		resetSpriteCache = false;
		isDownscroll = ClientPrefs.downScroll;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		practiceMode = false;
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');
		//set smallest rating I suppose
		smallestRating = ratingIndexArray[0];

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = '' + CoolUtil.difficultyStuff[storyDifficulty][0];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: Hypno's Lullaby";
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = PlayState.SONG.stage;
		trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case 'left-unchecked' | 'safety-lullaby' | 'sporting':
					curStage = 'alley';
				case 'monochrome':
					curStage = 'lost';
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
			case 'lost':
				// lmfao
			case 'alley':
				var consistentPosition:Array<Float> = [-300, -600];
				var resizeBG:Float = 0.7;
				defaultCamZoom = 0.7;

				var background:BGSprite = new BGSprite('hypno/Hypno bg background', consistentPosition[0], consistentPosition[1]);
				background.setGraphicSize(Std.int(background.width * resizeBG));
				background.updateHitbox();
				add(background);

				var midGround:BGSprite = new BGSprite('hypno/Hypno bg midground', consistentPosition[0], consistentPosition[1]);
				midGround.setGraphicSize(Std.int(midGround.width * resizeBG));
				midGround.updateHitbox();
				add(midGround);

				foreground = new BGSprite('hypno/Hypno bg foreground', consistentPosition[0], consistentPosition[1]);
				foreground.setGraphicSize(Std.int(foreground.width * resizeBG));
				foreground.updateHitbox();
			case 'missingno':
				defaultCamZoom = 0.6;
				isPixelStage = true;
				showCountdown = false;

				var resizeBG:Float = 6;
				var consistentPosition:Array<Float> = [-670, -240];

				var background:FlxSprite = new FlxSprite(consistentPosition[0] + 30, consistentPosition[1]);

				background.frames = Paths.getSparrowAtlas('missingno/bg', 'shared');
				background.animation.addByPrefix('idle', 'sky', 24, true);
				background.animation.play('idle');
				background.scale.set(resizeBG, resizeBG);
				background.updateHitbox();
				background.scrollFactor.set(0.3, 0.3);
				add(background);

				missingnoOcean = new FlxSprite(consistentPosition[0], consistentPosition[1]);
				missingnoOcean.frames = Paths.getSparrowAtlas('missingno/BG_Assets', 'shared');
				missingnoOcean.animation.addByPrefix('idle', 'Bg Ocean', 24, true);
				missingnoOcean.animation.play('idle');
				missingnoOcean.scale.set(resizeBG, resizeBG);
				missingnoOcean.updateHitbox();
				missingnoOcean.scrollFactor.set(0.4, 0.4);
				add(missingnoOcean);

				var ground:FlxSprite = new FlxSprite(consistentPosition[0], consistentPosition[1]);
				ground.frames = Paths.getSparrowAtlas('missingno/BG_Assets', 'shared');
				ground.animation.addByPrefix('idle', 'Bg Wave', 24, true);
				ground.animation.play('idle');
				ground.scale.set(resizeBG, resizeBG);
				ground.updateHitbox();
				add(ground);
		}

		add(gfGroup);
		celebiLayer = new FlxTypedGroup<FlxSprite>();
		add(celebiLayer);
		add(dadGroup);
		hand = new FlxSprite();
		hand.frames = Paths.getSparrowAtlas('hypno/White_Hand', 'shared');
		hand.animation.addByPrefix('appear', 'White Hand FInished', 24, false);
		hand.animation.play('appear');
		hand.alpha = 0;
		add(hand);
		add(boyfriendGroup);

		if(curStage == 'alley') {
			add(foreground);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		var camPos:FlxPoint;
		if (SONG.player2 != 'gold') {
			hand.setPosition(boyfriend.x + 500, boyfriend.y - 120);
			boyfriendGroup.add(boyfriend);

			camPos = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);
			camPos.x += boyfriend.cameraPosition[0];
			camPos.y += boyfriend.cameraPosition[1];
		} else
			camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		switch (curStage) {
			case 'missingno':
				camPos.x = 510;
				camPos.y = 358;

				dad.y -= 140;
				dad.x -= 50;
				dad.visible = false;
		}
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(isDownscroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 20, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = !ClientPrefs.hideTime;
		if(isDownscroll) timeTxt.y = FlxG.height - 45;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = !ClientPrefs.hideTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = !ClientPrefs.hideTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys()) {
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad)) {
				luaArray.push(new FunkinLua(luaToLoad));
			}
		}
		for (event in eventPushedMap.keys()) {
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad)) {
				luaArray.push(new FunkinLua(luaToLoad));
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(isDownscroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2) - iconP1.offsetY;
		iconP1.visible = !ClientPrefs.hideHud;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2) - iconP2.offsetY;
		iconP2.visible = !ClientPrefs.hideHud;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(isDownscroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		updateTime = true;

		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'data/' + Paths.formatToSongPath(SONG.song) + '/script.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (dad.curCharacter != 'gold') {
			if (isStoryMode && !seenCutscene)
			{
				switch (daSong)
				{
					case 'safety-lullaby':
						inCutscene = true;
						var doof:DialogueStart = new DialogueStart(this);
						doof.scrollFactor.set();
						add(doof);
						doof.cameras = [camHUD];
					default:
						startCountdown();
				}
				seenCutscene = true;
			} else {
				startCountdown();
			}
		} else {
			// IM DEAD
			showCountdown = false;

			FlxG.sound.play(Paths.sound('ImDead' + FlxG.random.int(1, 7), 'shared'), 1);
			// okay now fade in
			//dad.playAnim('fadeIn', true);
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				startCountdown();
			});
		}

		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
		super.create();

		pendulum = new Pendulum();

		if (SONG.player2 == 'hypno') {
			pendulumShadow = new FlxTypedGroup<FlxSprite>();

			pendulum.frames = Paths.getSparrowAtlas('hypno/Pendelum', 'shared');
			pendulum.animation.addByPrefix('idle', 'Pendelum instance 1', 24, true);
			pendulum.animation.play('idle');
			pendulum.antialiasing = true; // fuck you ASH

			pendulum.scale.set(1.3, 1.3);
			pendulum.updateHitbox();
			pendulum.origin.set(65, 0);
			pendulum.angle = -9;
			add(pendulumShadow);
			add(pendulum);

			tranceActive = true;


		} else if (SONG.player2 == 'hypno-two') {
			pendulumShadow = new FlxTypedGroup<FlxSprite>();

			pendulum.frames = Paths.getSparrowAtlas('hypno/Pendelum_Phase2', 'shared');
			pendulum.animation.addByPrefix('idle', 'Pendelum Phase 2', 24, true);
			pendulum.animation.play('idle');
			pendulum.updateHitbox();
			pendulum.origin.set(65, 0);
			pendulum.cameras = [camHUD];
			pendulum.x = FlxG.width / 4;
			pendulum.y = 0;
			pendulum.antialiasing = true; // fuck you again
			add(pendulumShadow);
			add(pendulum);

			tranceActive = true;
		}
		if (ClientPrefs.pussyMode) {
			if (tranceActive) {
				tranceActive = false;
				remove(pendulum);
			}
		}
		keyboard = new FlxSprite();
		keyboard.frames = Paths.getSparrowAtlas('hypno/Extras', 'shared');
		keyboard.animation.addByIndices('idle', 'Spacebar', [11, 12, 13, 14 ,15 ,16 ,17, 18], '', 24, false);
		keyboard.animation.addByIndices('press', 'Spacebar', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], '', 24, false);
		keyboard.animation.play('idle');
		keyboard.cameras = [camHUD];
		keyboard.screenCenter(X);
		keyboard.y = 400;
		keyboard.alpha = 0;
		add(keyboard);

		if (ClientPrefs.hellMode || ClientPrefs.pussyMode) {
			remove(keyboard);
		}
		tranceThing = new FlxSprite();
		tranceThing.frames = Paths.getSparrowAtlas('hypno/StaticHypno', 'shared');
		tranceThing.animation.addByPrefix('idle', 'StaticHypno', (ClientPrefs.photosensitive) ? 0 : 24, true);
		tranceThing.animation.play('idle');
		tranceThing.cameras = [camHUD];
		tranceThing.setGraphicSize(FlxG.width, FlxG.height);
		tranceThing.updateHitbox();
		add(tranceThing);
		tranceThing.alpha = 0;

		tranceDeathScreen = new FlxSprite();
		tranceDeathScreen.frames = Paths.getSparrowAtlas('hypno/StaticHypno_highopacity', 'shared');
		tranceDeathScreen.animation.addByPrefix('idle', 'StaticHypno', 24, true);
		tranceDeathScreen.animation.play('idle');
		tranceDeathScreen.cameras = [camHUD];
		tranceDeathScreen.setGraphicSize(FlxG.width, FlxG.height);
		tranceDeathScreen.updateHitbox();
		add(tranceDeathScreen);
		tranceDeathScreen.alpha = 0;

		psyshockParticle = new Character(0, 0, 'hypno');
		psyshockParticle.playAnim("psyshock particle", true);
		psyshockParticle.alpha = 0;
		add(psyshockParticle);

		if (!ClientPrefs.photosensitive)
			camHUD.flash(FlxColor.fromString('0xFFFFAFC1'), 0.1, null, true);
		FlxG.sound.play(Paths.sound('Psyshock', 'shared'), 0);
		tranceSound = FlxG.sound.play(Paths.sound('TranceStatic', 'shared'), 0, true);


		switch (SONG.song.toLowerCase()) {
			case 'monochrome':
				healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBar.alpha = 0;
				timeBarBG.alpha = 0;
				timeTxt.alpha = 0;
				dad.visible = false;

				// jumpscare
				jumpScare = new FlxSprite().loadGraphic(Paths.image('lostSilver/Gold_Jumpscare'));
				jumpScare.setGraphicSize(Std.int(FlxG.width * jumpscareSizeInterval), Std.int(FlxG.height * jumpscareSizeInterval));
				jumpScare.updateHitbox();
				jumpScare.screenCenter();
				add(jumpScare);

				jumpScare.setGraphicSize(Std.int(FlxG.width * jumpscareSizeInterval), Std.int(FlxG.height * jumpscareSizeInterval));
				jumpScare.updateHitbox();
				jumpScare.screenCenter();

				jumpScare.visible = false;
				jumpScare.cameras = [camHUD];
				if (ClientPrefs.hellMode)	{
					pendulumShadow = new FlxTypedGroup<FlxSprite>();

					pendulum.frames = Paths.getSparrowAtlas('hypno/Pendelum_Phase2', 'shared');
					pendulum.animation.addByPrefix('idle', 'Pendelum Phase 2', 24, true);
					pendulum.animation.play('idle');
					pendulum.updateHitbox();
					pendulum.origin.set(65, 0);
					pendulum.cameras = [camHUD];
					pendulum.x = FlxG.width / 4;
					pendulum.y = 0;
					pendulum.antialiasing = true; // fuck you again
					add(pendulumShadow);
					add(pendulum);

					tranceActive = true;
				}
			case 'missingno':
				iconP2.alpha = 0;
				camFollow.x = 510;
				camFollow.y = 358;
		}

	}

	var jumpScare:FlxSprite;

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});
		luaDebugGroup.add(new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.alreadyLoaded = false;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.alreadyLoaded = false;
				}

			case 2:
				if(!gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					newGf.alreadyLoaded = false;
				}
		}
	}
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				if(endingSong) {
					endSong();
				} else {
					startCountdown();
				}
			}
			return;
		} else {
			FlxG.log.warn('Couldnt find video file: ' + fileName);
		}
		#end
		if(endingSong) {
			endSong();
		} else {
			startCountdown();
		}
	}

	var dialogueCount:Int = 0;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();
			if(endingSong) {
				doof.finishThing = endSong;
			} else {
				doof.finishThing = startCountdown;
			}
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras = [camHUD];
			add(doof);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countDownSprites:Array<FlxSprite> = [];

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			var enemyAlpha:Float = 1;
			var playerAlpha:Float = 1;
			if (SONG.song.toLowerCase() == 'monochrome') {
				enemyAlpha = 0;
				playerAlpha = 0;
			}
			generateStaticArrows(0, enemyAlpha);
			generateStaticArrows(1, playerAlpha);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}
			dad.animation.play('fadeIn', true);
			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);

			var swagCounter:Int = 0;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (dad.curCharacter != 'gold') {
					if(tmr.loopsLeft % 2 == 0) {
						if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
							boyfriend.dance();
						if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned && !psyshocking)
							dad.dance();
					}
					else if(dad.danceIdle && dad.animation.curAnim != null && !dad.stunned && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing") && !psyshocking)
						dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				if (showCountdown) {
					switch (swagCounter)
					{
						case 0:
							FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						case 1:
							var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
							ready.scrollFactor.set();
							ready.updateHitbox();

							if (PlayState.isPixelStage)
								ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

							ready.screenCenter();
							ready.antialiasing = antialias;
							add(ready);
							countDownSprites.push(ready);
							FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									countDownSprites.remove(ready);
									remove(ready);
									ready.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						case 2:
							var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
							set.scrollFactor.set();

							if (PlayState.isPixelStage)
								set.setGraphicSize(Std.int(set.width * daPixelZoom));

							set.screenCenter();
							set.antialiasing = antialias;
							add(set);
							countDownSprites.push(set);
							FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									countDownSprites.remove(set);
									remove(set);
									set.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						case 3:
							var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
							go.scrollFactor.set();

							if (PlayState.isPixelStage)
								go.setGraphicSize(Std.int(go.width * daPixelZoom));

							go.updateHitbox();

							go.screenCenter();
							go.antialiasing = antialias;
							add(go);
							countDownSprites.push(go);
							FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									countDownSprites.remove(go);
									remove(go);
									go.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						case 4:
					}
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = 1 * note.multAlpha;
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				if (generatedMusic)
				{
					notes.sort(FlxSort.byY, isDownscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
				}

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function pendulumSwing() {
		if (ClientPrefs.hellMode) {
			pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle + 30}, Conductor.stepCrochet * 2 / 1000, {ease: FlxEase.quadOut, onComplete: function (twn:FlxTween) {
				pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle - 30}, Conductor.stepCrochet * 2 / 1000, {ease: FlxEase.quadIn, onComplete: function (twn:FlxTween) {
					pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle - 30}, Conductor.stepCrochet * 2 / 1000, {ease: FlxEase.quadOut, onComplete: function (twn:FlxTween) {
						pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle + 30}, Conductor.stepCrochet * 2 / 1000, {ease: FlxEase.quadIn, onComplete: function (twn:FlxTween) {
							pendulumSwing();
						}});
					}});
				}});
			}});
		} else {
			pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle + 30}, Conductor.stepCrochet * 4 / 1000, {ease: FlxEase.quadOut, onComplete: function (twn:FlxTween) {
				pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle - 30}, Conductor.stepCrochet * 4 / 1000, {ease: FlxEase.quadIn, onComplete: function (twn:FlxTween) {
					pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle - 30}, Conductor.stepCrochet * 4 / 1000, {ease: FlxEase.quadOut, onComplete: function (twn:FlxTween) {
						pendulum.daTween = FlxTween.tween(pendulum, {angle: pendulum.angle + 30}, Conductor.stepCrochet * 4 / 1000, {ease: FlxEase.quadIn, onComplete: function (twn:FlxTween) {
							pendulumSwing();
						}});
					}});
				}});
			}});
		}
	}
	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if (SONG.song.toLowerCase() == 'monochrome') {
			dad.animation.play('fadeIn', true);
			dad.visible = true;

			//healthBar.alpha = 0.4;
			//healthBarBG.alpha = 0.4;
			//iconP1.alpha = 0;
			//iconP2.alpha = 0.4;
			//scoreTxt.alpha = 0.4;
		}

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			tranceSound.pause();
		} else {
			if (tranceActive) {
				pendulumSwing();
				FlxTween.tween(keyboard, {alpha: 1}, Conductor.stepCrochet * 2 / 1000, {ease: FlxEase.quadOut});
			}

		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		if (SONG.song.toLowerCase() != 'monochrome') {
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<SwagSection> = Song.loadFromJson('events', songName).notes;
			for (section in eventsData)
			{
				for (songNotes in section.sectionNotes)
				{
					if(songNotes[1] < 0) {
						eventNotes.push([songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
						eventPushed(songNotes);
					}
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);

					var gottaHitNote:Bool = section.mustHitSection;

					if (songNotes[1] > 3)
					{
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(SONG.speed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);

							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
						}
					}

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else {}

					if(!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
				} else { //Event Notes
					eventNotes.push([songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
					eventPushed(songNotes);
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch(event[2]) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event[3].toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(event[3]);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event[4];
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event[2])) {
			eventPushedMap.set(event[2], true);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[2]]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event[2]) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		var earlyTime1:Float = eventNoteEarlyTrigger(Obj1);
		var earlyTime2:Float = eventNoteEarlyTrigger(Obj2);
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - earlyTime1, Obj2[0] - earlyTime2);
	}

	private function generateStaticArrows(player:Int, theAlpha:Float):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: theAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			} else {
				babyArrow.alpha = theAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			pendulum.daTween.cancel();
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				tranceSound.pause();
			}


			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			var chars:Array<Character> = [boyfriend, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			var chars:Array<Character> = [boyfriend, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (isMonoDead) {
			Conductor.songPosition = 0;
			return;
		}
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
		tranceSound.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;
	var camResize:Float = 0;

	function startUnown(timer:Int = 15, word:String = ''):Void {
		if (!ClientPrefs.pussyMode) {
			canPause = false;
			unowning = true;
			persistentUpdate = true;
			persistentDraw = true;
			var realTimer = timer;
			var unownState = new UnownSubState(realTimer, word);
			unownState.win = wonUnown;
			unownState.lose = die;
			unownState.cameras = [camHUD];
			FlxG.autoPause = false;
			openSubState(unownState);
		}
	}

	public function wonUnown():Void {
		canPause = true;
		unowning = false;
	}

	function doTheHand() {
		hand.alpha = 1;
		hand.animation.play('appear', true);
		hand.animation.finishCallback = function (name:String) {
			hand.alpha = 0;
		};
	}

	var dadY:Float;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			default:
		}

		if(!inCutscene) {
			/// sorry ash dont look at these values theyre painful
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
				FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom + resizeCamera, FlxG.camera.zoom, 0.95);
		}

		super.update(elapsed);

		scoreTxt.text = 'Score: ' + songScore + ' | Combo Breaks: ' + songMisses + ' | Accuracy: ';
		if(ratingString != '?' && !cpuControlled) {
			scoreTxt.text += '' + ((Math.floor(ratingPercent * 10000) / 100)) + '%';
		} else if (cpuControlled)
			scoreTxt.text += 'fucking cheater!';
		if (songMisses <= 0)
			scoreTxt.text += ratingString;

		if(cpuControlled) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		botplayTxt.visible = cpuControlled;

		#if debug
		if (FlxG.keys.justPressed.X)
			missingnoThing();
		#end

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				var thePauseSubstate:PauseSubState = new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y);
				PauseSubState.transCamera = camOther;
				openSubState(thePauseSubstate);
				if (SONG.song.toLowerCase() == 'missingno' && curBeat < 59)
					PauseSubState.levelInfo.text = '???';

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.justPressed.SEVEN && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.initialWidth, iconP1.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.initialWidth, iconP2.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset) - iconP1.offsetX;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset) - iconP2.offsetX;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (iconP2.char != 'hypno2') {
			if (healthBar.percent > 80)
				iconP2.animation.curAnim.curFrame = 1;
			else
				iconP2.animation.curAnim.curFrame = 0;
		}


		if (FlxG.keys.justPressed.EIGHT && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (dad != null) {
			if (!Math.isNaN(dadY) && dad.curCharacter == 'missingno') {
				dad.y = dadY + ((Math.sin((Conductor.songPosition / 16000) * (180 / Math.PI))) * 5);
			} else
				dadY = dad.y;
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom + resizeCamera, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (controls.RESET && !inCutscene && !endingSong && !unowning)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();


		if (isMonoDead) {
			if (controls.ACCEPT)
				MusicBeatState.resetState();
			//trace(dad.animation.curAnim.curFrame);
		}

		var pendulumOffset:Array<Int> = [];
		if (dad.curCharacter == 'hypno') {
			switch (dad.animation.name) {
				case 'idle':
					switch (dad.animation.curAnim.curFrame) {
						case 0 | 1:
							pendulumOffset[0] = 814;
							pendulumOffset[1] = 264;
						case 2 | 3:
							pendulumOffset[0] = 813;
							pendulumOffset[1] = 270;
						case 4:
							pendulumOffset[0] = 813;
							pendulumOffset[1] = 266;
						case 5:
							pendulumOffset[0] = 813;
							pendulumOffset[1] = 263;
						case 6:
							pendulumOffset[0] = 814;
							pendulumOffset[1] = 255;
						case 7:
							pendulumOffset[0] = 811;
							pendulumOffset[1] = 251;
						case 8 | 9:
							pendulumOffset[0] = 809;
							pendulumOffset[1] = 249;
						case 10 | 11 | 12 | 13 | 14:
							pendulumOffset[0] = 808;
							pendulumOffset[1] = 248;
					}
				case 'singLEFT':
					switch (dad.animation.curAnim.curFrame) {
						case 0:
							pendulumOffset[0] = 775;
							pendulumOffset[1] = 336;
						case 1:
							pendulumOffset[0] = 790;
							pendulumOffset[1] = 351;
						case 2:
							pendulumOffset[0] = 826;
							pendulumOffset[1] = 366;
						case 3 | 4:
							pendulumOffset[0] = 830;
							pendulumOffset[1] = 378;
						case 5 | 6:
							pendulumOffset[0] = 831;
							pendulumOffset[1] = 393;
						case 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17:
							pendulumOffset[0] = 832;
							pendulumOffset[1] = 396;
					}
				case 'singRIGHT':
					switch (dad.animation.curAnim.curFrame) {
						case 0 | 1 | 2:
							pendulumOffset[0] = 866;
							pendulumOffset[1] = 609;
						case 3:
							pendulumOffset[0] = 858;
							pendulumOffset[1] = 612;
						case 4:
							pendulumOffset[0] = 881;
							pendulumOffset[1] = 610;
						case 5:
							pendulumOffset[0] = 901;
							pendulumOffset[1] = 597;
						case 6:
							pendulumOffset[0] = 903;
							pendulumOffset[1] = 590;
						case 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17:
							pendulumOffset[0] = 908;
							pendulumOffset[1] = 586;
					}
				case 'singUP':
					switch (dad.animation.curAnim.curFrame) {
						case 0:
							pendulumOffset[0] = 638;
							pendulumOffset[1] = -300;
						case 1:
							pendulumOffset[0] = 675;
							pendulumOffset[1] = -267;
						case 2:
							pendulumOffset[0] = 681;
							pendulumOffset[1] = -257;
						case 3:
							pendulumOffset[0] = 694;
							pendulumOffset[1] = -249;
						case 4:
							pendulumOffset[0] = 696;
							pendulumOffset[1] = -241;
						case 5:
							pendulumOffset[0] = 705;
							pendulumOffset[1] = -237;
						case 6 | 7:
							pendulumOffset[0] = 709;
							pendulumOffset[1] = -236;
						case 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17:
							pendulumOffset[0] = 711;
							pendulumOffset[1] = -234;
					}
				case 'singDOWN':
					switch (dad.animation.curAnim.curFrame) {
						case 0:
							pendulumOffset[0] = 700;
							pendulumOffset[1] = 222;
						case 1:
							pendulumOffset[0] = 705;
							pendulumOffset[1] = 237;
						case 2:
							pendulumOffset[0] = 692;
							pendulumOffset[1] = 220;
						case 3 | 4:
							pendulumOffset[0] = 687;
							pendulumOffset[1] = 213;
						case 5:
							pendulumOffset[0] = 690;
							pendulumOffset[1] = 220;
						case 6:
							pendulumOffset[0] = 689;
							pendulumOffset[1] = 227;
						case 7:
							pendulumOffset[0] = 680;
							pendulumOffset[1] = 242;
						case 8:
							pendulumOffset[0] = 679;
							pendulumOffset[1] = 243;
						case 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17:
							pendulumOffset[0] = 673;
							pendulumOffset[1] = 253;
					}
				case 'psyshock':
					switch (dad.animation.curAnim.curFrame) {
						case 0:
							pendulumOffset[0] = 737;
							pendulumOffset[1] = 386;
						case 1:
							pendulumOffset[0] = 713;
							pendulumOffset[1] = 396;
						case 2:
							pendulumOffset[0] = 706;
							pendulumOffset[1] = 394;
						case 3 :
							pendulumOffset[0] = 708;
							pendulumOffset[1] = 392;
						case 4 | 5:
							pendulumOffset[0] = 709;
							pendulumOffset[1] = 391;
						case 6:
							pendulumOffset[0] = 709;
							pendulumOffset[1] = 405;
						case 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17:
							pendulumOffset[0] = 703;
							pendulumOffset[1] = 416;
					}
			}
			pendulum.x = dad.x + pendulumOffset[0];
			pendulum.y = dad.y + pendulumOffset[1];
		} else pendulum.screenCenter(X);

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if(roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				dunceNote.downscrollNote = isDownscroll;
				if (missingnoStarted && dunceNote.isSustainNote != true)
					dunceNote.downscrollNote = FlxG.random.bool(50);
				else if (missingnoStarted && dunceNote.isSustainNote)
					dunceNote.downscrollNote = dunceNote.prevNote.downscrollNote;
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			pendulumDrain = true;
			notes.forEachAlive(function(daNote:Note)
			{
				if(!daNote.mustPress && ClientPrefs.middleScroll)
				{
					daNote.active = true;
					daNote.visible = false;
				}
				else if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				if (daNote.canBeHit && daNote.mustPress && !ClientPrefs.hellMode)
					pendulumDrain = false;

				// i am so fucking sorry for this if condition
				var strumX:Float = 0;
				var strumY:Float = 0;
				var strumAngle:Float = 0;
				var strumAlpha:Float = 0;
				if(daNote.mustPress) {
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
					strumAngle = playerStrums.members[daNote.noteData].angle;
					strumAlpha = playerStrums.members[daNote.noteData].alpha;
				} else {
					strumX = opponentStrums.members[daNote.noteData].x;
					strumY = opponentStrums.members[daNote.noteData].y;
					strumAngle = opponentStrums.members[daNote.noteData].angle;
					strumAlpha = opponentStrums.members[daNote.noteData].alpha;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				var center:Float = strumY + Note.swagWidth / 2;

				if(daNote.copyAngle) {
					daNote.angle = strumAngle;
				}
				if(daNote.copyAlpha) {
					daNote.alpha = strumAlpha;
				}

				// set the notes x and y
				var downscrollMultiplier = 1;
				if (daNote.downscrollNote)
					downscrollMultiplier = -1;

				var psuedoY:Float = (downscrollMultiplier *
					-((Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2))));
				var psuedoX = 0;

				var persistentAngle:Float = 0;
				if (reverseXY)
					persistentAngle = 90;
				daNote.angle = persistentAngle;

				//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
				if (daNote.downscrollNote) {
					if (daNote.animation.curAnim.name.endsWith('end')) {
						psuedoY += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
						psuedoY -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
						if(PlayState.isPixelStage) {
							psuedoY += 8;
						} else {
							psuedoY -= 19;
						}
					}
				}

				daNote.y = strumY
					+ (Math.cos(flixel.math.FlxAngle.asRadians(persistentAngle)) * psuedoY)
					+ (Math.sin(flixel.math.FlxAngle.asRadians(persistentAngle)) * psuedoX);
				// painful math equation
				daNote.x = strumX
					+ (Math.cos(flixel.math.FlxAngle.asRadians(persistentAngle)) * psuedoX)
					+ (Math.sin(flixel.math.FlxAngle.asRadians(persistentAngle)) * psuedoY);

				/*
				var psuedoX:Float;
				var psuedoY:Float;
				if(daNote.copyX) {
					psuedoX = strumX;
				}
				*/

				if (!reverseXY) {
					if(daNote.copyY) {
						if (daNote.downscrollNote) {
							if (daNote.isSustainNote) {
								if(daNote.mustPress || !daNote.ignoreNote)
								{
									if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
										&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
									{
										var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
										swagRect.height = (center - daNote.y) / daNote.scale.y;
										swagRect.y = daNote.frameHeight - swagRect.height;

										daNote.clipRect = swagRect;
									}
								}
							}
						} else if (!daNote.downscrollNote) {
							if(daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.isSustainNote
									&& daNote.y + daNote.offset.y * daNote.scale.y <= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}
					}
				} else {
					if (daNote.isSustainNote) {
						if(daNote.mustPress || !daNote.ignoreNote)
						{
							if(daNote.x - daNote.offset.x * daNote.scale.x + daNote.height >= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.x) / daNote.scale.x;
								swagRect.x = daNote.frameHeight - swagRect.width;

								daNote.clipRect = swagRect;
							}
						}
					}
					else {
						if(daNote.mustPress || !daNote.ignoreNote)
						{
							if (daNote.isSustainNote
								&& daNote.x + daNote.offset.x * daNote.scale.x <= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.x = (center - daNote.x) / daNote.scale.x;
								swagRect.width -= swagRect.x;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				//*/

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					if (Paths.formatToSongPath(SONG.song) != 'tutorial')
						camZooming = true;

					if(daNote.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = 0.6;
					} else if(!daNote.noAnimation) {
						var altAnim:String = "";

						if (SONG.notes[Math.floor(curStep / 16)] != null)
						{
							if (SONG.notes[Math.floor(curStep / 16)].altAnim || daNote.noteType == 'Alt Animation') {
								altAnim = '-alt';
							}
						}

						var animToPlay:String = '';
						switch (Math.abs(daNote.noteData))
						{
							case 0:
								animToPlay = 'singLEFT';
							case 1:
								animToPlay = 'singDOWN';
							case 2:
								animToPlay = 'singUP';
							case 3:
								animToPlay = 'singRIGHT';
						}
						if (!psyshocking)
							dad.playAnim(animToPlay + altAnim, true);
						dad.holdTimer = 0;
					}

					if (SONG.needsVoices)
						vocals.volume = 1;

					var time:Float = 0.15;
					if(daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
						time += 0.15;
					}
					StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)) % 4, time);
					daNote.hitByOpponent = true;

					callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);

					if (!daNote.isSustainNote)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));
				var doKill:Bool;
				if (!reverseXY) {
					doKill = daNote.y < -daNote.height;
					if(daNote.downscrollNote)
						doKill = daNote.y > FlxG.height;
				} else {
					doKill = daNote.x < -daNote.width;
					if(daNote.downscrollNote)
						doKill = daNote.x > FlxG.width;
				}

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});

			if (tranceActive) {
				// the elapsed/(1/120) is to keep it the same across all framerates
				
				trance -= 0.0015*(elapsed/(1/120)) / ((!pendulumDrain) ? reducedDrain : 1);

				tranceThing.alpha = trance / 2;
				if (trance > 1) {
					tranceSound.volume = trance - 1;
				} else {
					tranceSound.volume = 0;
				}

				if (trance > 2) {
					trance = 2;
					if (tranceCanKill)
						die();
				}
				if (trance < -0.25)
					trance = -0.25;

				if (trance >= 0.8) {
					if (trance >= 1.6)
						boyfriend.idleSuffix = '-alt2';
					else
						boyfriend.idleSuffix = '-alt';
				} else {
					boyfriend.idleSuffix = '';
				}
				if (FlxG.keys.justPressed.SPACE && !inCutscene) {
					if (canHitPendulum) {
						canHitPendulum = false;
						hitPendulum = true;
						winPendulum();
					} else {
						losePendulum(true);
					}
				}
			}
		}
		checkEventNote();

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE && !unowning) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				trance = 0;
				health = 2;
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', PlayState.cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		#end
	}

	var isDead:Bool = false;

	public function die():Void {
		if (SONG.song.toLowerCase() == 'monochrome') {
			boyfriend.stunned = true;
			deathCounter++;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			isDead = true;
			isMonoDead = true;
			dad.debugMode = true;
			dad.playAnim('fadeOut', true);
			dad.animation.finishCallback = function (name:String) {
				remove(dad);
			}

			FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function (twn:FlxTween) {
				healthBar.visible = false;
				healthBarBG.visible = false;
				scoreTxt.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
			}});
			FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
			FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
			FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
			FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
			for (i in playerStrums) {
				FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
			}

		} else {
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				switch (boyfriend.curCharacter) {
					case 'gf':
						openSubState(new GFGameoverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y, this));
					default:
						if (boyfriend.curCharacter == 'bf-pixel') {
							GameOverSubstate.characterName = 'bf-pixel-dead';
							GameOverSubstate.loopSoundName = 'MissingnoDeath';
							GameOverSubstate.endSoundName = 'MissingnoDone';
						}
						openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y, this));
				}

				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;

			}
		}
	}
	function doDeathCheck() {
		if (health <= maxHealth && !practiceMode && !isDead)
		{
			die();
			return true;
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var early:Float = eventNoteEarlyTrigger(eventNotes[0]);
			var leStrumTime:Float = eventNotes[0][0];
			if(Conductor.songPosition < leStrumTime - early) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0][3] != null)
				value1 = eventNotes[0][3];

			var value2:String = '';
			if(eventNotes[0][4] != null)
				value2 = eventNotes[0][4];

			triggerEventNote(eventNotes[0][2], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 0;
				switch(value1.toLowerCase().trim()) {
					default:
						value = 0;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value == 0) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Center Camera':
				cameraCentered = !cameraCentered;

			case 'Jumpscare':
				jumpscare(Std.parseFloat(value1), Std.parseFloat(value2));

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							if(!boyfriend.alreadyLoaded) {
								boyfriend.alpha = 1;
								boyfriend.alreadyLoaded = true;
							}
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);

							if(!dad.alreadyLoaded) {
								dad.alpha = 1;
								dad.alreadyLoaded = true;
							}
							dad.visible = true;
							iconP2.changeIcon(dad.healthIcon);
						}
				}
				reloadHealthBarColors();

			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();
			case 'Psyshock':
				psyshock();
			case 'Fakeshock':
				fakeshock();
			case 'Unown':
				startUnown(Std.parseInt(value1), value2);
			case 'Celebi':
				doCelebi(Std.parseFloat(value1));
			case 'Missingno':
				missingnoThing();

		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	var missingnoStarted:Bool = false;
	var reverseXY:Bool = false;

	// I fucking hate math
	final bullshitArray:Array<Int> = [-2, -1, 1, 2];

	function missingnoThing() {
		for (i in opponentStrums)
			i.alpha = 0;
		if (!ClientPrefs.pussyMode) {

			if (ClientPrefs.hellMode) {
				FlxG.fullscreen = false;
				Lib.application.window.move(FlxG.random.int(0, Std.int(Capabilities.screenResolutionX - FlxG.width)), FlxG.random.int(0, Std.int(Capabilities.screenResolutionY - FlxG.height)));
				// shubs algorithm lmfao
				missingnoStarted = true;
				//reverseXY = FlxG.random.bool(50);
				var shove:Int;
				if (!reverseXY)
					shove = FlxG.random.int(100, Std.int(FlxG.width / 4));
				else
					shove = FlxG.random.int(100, Std.int(FlxG.height / 4));

				var placementX:Float;
				var placementY:Float;
				for (i in 0...playerStrums.length) {
					var displacement:Float = FlxG.random.int(50, 100) * FlxG.random.float(-1, 1);
					placementY = displacement;
					placementX = ((shove / 1.5) * bullshitArray[i]);
					if (reverseXY)
						playerStrums.members[i].setPosition(
							((FlxG.width / 2) - (playerStrums.members[i].width / 2)) + placementY,
							((FlxG.height / 2) - (playerStrums.members[i].height / 2)) + placementX
						);
					else
						playerStrums.members[i].setPosition(
							((FlxG.width / 2) - (playerStrums.members[i].width / 2)) + placementX,
							((FlxG.height / 2) - (playerStrums.members[i].height / 2)) + placementY
						);
				}

			} else
			{
				// ash algorithm
				isDownscroll = FlxG.random.bool(50);
				notes.forEach(function(note:Note){note.downscrollNote = isDownscroll;});
				for (i in 0...playerStrums.length) {
					if (i == 0) {
						playerStrums.members[i].x = FlxG.random.int(100, Std.int(FlxG.width / 3));
						if (isDownscroll)
							playerStrums.members[i].y = FlxG.random.int(Std.int(FlxG.height / 2), FlxG.height - 100);
						else
							playerStrums.members[i].y = FlxG.random.int(0, 300);

					} else {
						var futurex = FlxG.random.int(Std.int(playerStrums.members[i - 1].x) + 80, Std.int(playerStrums.members[i - 1].x) + 400);
						if (futurex > FlxG.width - 100)
							futurex = FlxG.width - 100;
						playerStrums.members[i].x = futurex;

						playerStrums.members[i].y = FlxG.random.int(Std.int(playerStrums.members[0].y - 50), Std.int(playerStrums.members[0].y + 50));
					}
				}
			}

		}
	}

	var jumpscareSizeInterval:Float = 1.625;

	function jumpscare(chance:Float, duration:Float) {
		// jumpscare
		if (!ClientPrefs.photosensitive) {
			var outOfTen:Float = Std.random(10);
			if (outOfTen <= ((!Math.isNaN(chance)) ? chance : 4)) {
				jumpScare.visible = true;
				camHUD.shake(0.0125 * (jumpscareSizeInterval / 2), (((!Math.isNaN(duration)) ? duration : 1) * Conductor.stepCrochet) / 1000,
					function(){
						jumpScare.visible = false;
						jumpscareSizeInterval += 0.125;
						jumpScare.setGraphicSize(Std.int(FlxG.width * jumpscareSizeInterval), Std.int(FlxG.height * jumpscareSizeInterval));
						jumpScare.updateHitbox();
						jumpScare.screenCenter();
					}, true
				);
			}
		}
	}

	function doCelebi(newMax:Float):Void {
		if (!ClientPrefs.pussyMode) {
			maxHealth = newMax;
			remove(healthBar);
			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8) - Std.int(healthBar.width * (maxHealth / 2)) , Std.int(healthBarBG.height - 8), this,
				'health', maxHealth, 2);
			healthBar.scrollFactor.set();
			healthBar.visible = !ClientPrefs.hideHud;
			remove(iconP1);
			remove(iconP2);
			add(healthBar);
			add(iconP1);
			add(iconP2);
			healthBar.cameras = [camHUD];
			reloadHealthBarColors();

			var celebi:FlxSprite = new FlxSprite(0 + FlxG.random.int(-150, -300), 0 + FlxG.random.int(-200, 200));
			celebi.frames = Paths.getSparrowAtlas('lostSilver/Celebi_Assets', 'shared');
			celebi.animation.addByPrefix('spawn', 'Celebi Spawn Full', 24, false);
			celebi.animation.addByIndices('reverseSpawn', 'Celebi Spawn Full', [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0],'', 24, false);
			celebi.animation.addByPrefix('idle', 'Celebi Idle', 24, false);
			celebi.animation.play('spawn');
			celebi.animation.finishCallback = function (name:String) {
				celebi.animation.play('idle');
				var note:FlxSprite = new FlxSprite(celebi.x + FlxG.random.int(70, 100), celebi.y + FlxG.random.int(-50, 50));
				note.frames = Paths.getSparrowAtlas('lostSilver/Note_asset', 'shared');
				note.animation.addByPrefix('spawn', 'Note Full', 24, false);
				note.animation.play('spawn');
				note.animation.finishCallback = function (name:String) {
					remove(note);
				};
				add(note);
				FlxTween.tween(note, {x: note.x + FlxG.random.int(100, 190), y:FlxG.random.int(-80, 140)}, (Conductor.stepCrochet * 8 / 1000), {ease: FlxEase.quadOut});
				celebi.animation.finishCallback = null;

				if (ClientPrefs.hellMode)	{
					for (i in 0...3) {
						var note:FlxSprite = new FlxSprite(celebi.x + FlxG.random.int(70, 100), celebi.y + FlxG.random.int(-50, 50));
						note.frames = Paths.getSparrowAtlas('lostSilver/Note_asset', 'shared');
						note.animation.addByPrefix('spawn', 'Note Full', 24, false);
						note.animation.play('spawn');
						note.animation.finishCallback = function (name:String) {
							remove(note);
						};
						add(note);
						FlxTween.tween(note, {x: note.x + FlxG.random.int(100, 190), y:FlxG.random.int(-80, 140)}, (Conductor.stepCrochet * 8 / 1000), {ease: FlxEase.quadOut});
						celebi.animation.finishCallback = null;
					}
				}
			};
			celebiLayer.add(celebi);



			new FlxTimer().start(Conductor.stepCrochet * 8 / 1000, function(tmr:FlxTimer)
			{
				var note:FlxSprite = new FlxSprite(celebi.x + FlxG.random.int(70, 100), celebi.y + FlxG.random.int(-50, 50));
				note.frames = Paths.getSparrowAtlas('lostSilver/Note_asset', 'shared');
				note.animation.addByPrefix('spawn', 'Note Full', 24, false);
				note.animation.play('spawn');
				note.animation.finishCallback = function (name:String) {
					remove(note);
				};
				add(note);
				FlxTween.tween(note, {x: note.x + FlxG.random.int(100, 190), y:FlxG.random.int(-80, 140)}, (Conductor.stepCrochet * 8 / 1000), {ease: FlxEase.quadOut});

				if (ClientPrefs.hellMode)	{
					for (i in 0...3) {
						var note:FlxSprite = new FlxSprite(celebi.x + FlxG.random.int(70, 100), celebi.y + FlxG.random.int(-50, 50));
						note.frames = Paths.getSparrowAtlas('lostSilver/Note_asset', 'shared');
						note.animation.addByPrefix('spawn', 'Note Full', 24, false);
						note.animation.play('spawn');
						note.animation.finishCallback = function (name:String) {
							remove(note);
						};
						add(note);
						FlxTween.tween(note, {x: note.x + FlxG.random.int(100, 190), y:FlxG.random.int(-80, 140)}, (Conductor.stepCrochet * 8 / 1000), {ease: FlxEase.quadOut});
						celebi.animation.finishCallback = null;
					}
				}

			});

			new FlxTimer().start(Conductor.stepCrochet * 16 / 1000, function(tmr:FlxTimer)
			{
				celebi.animation.play('reverseSpawn', true);
				celebi.animation.finishCallback = function (name:String) {
					celebiLayer.remove(celebi);
				};
			});
		}

	}
	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	var resizeCamera:Float = 0;
	public function moveCamera(isDad:Bool) {
		if (cameraCentered) {
			resizeCamera = -0.3;
			camFollow.x = (((dad.getMidpoint().x + 150 + dad.cameraPosition[0]) + (boyfriend.getMidpoint().x - 100 + boyfriend.cameraPosition[0])) / 2);
		} else {
			resizeCamera = 0;
			if(isDad) {
				camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				camFollow.x += dad.cameraPosition[0];
				camFollow.y += dad.cameraPosition[1];
				tweenCamIn();
			} else {
				camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

				switch (curStage)
				{
					case 'limo':
						camFollow.x = boyfriend.getMidpoint().x - 300;
					case 'mall':
						camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'school' | 'schoolEvil':
						camFollow.x = boyfriend.getMidpoint().x - 200;
						camFollow.y = boyfriend.getMidpoint().y - 200;
				}
				camFollow.x -= boyfriend.cameraPosition[0];
				camFollow.y += boyfriend.cameraPosition[1];

				if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1) {
					cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
						function (twn:FlxTween) {
							cameraTwn = null;
						}
					});
				}
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		tranceSound.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.0475;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.0475;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		if (!usedPractice) {
			//trash ass code but its 1 am and I fucked up
			if (ClientPrefs.hellMode) {
				if (FlxG.save.data.beatenHell == null)
					FlxG.save.data.beatenHell = [];
				if (!FlxG.save.data.beatenHell.contains(SONG.song))
					FlxG.save.data.beatenHell.push(SONG.song);

				if (FlxG.save.data.beatenHell.length >= 4)
					FlxG.save.data.hellBeat = true;
			} else {
				if (FlxG.save.data.beatenNormal == null)
					FlxG.save.data.beatenNormal = [];
				if (!FlxG.save.data.beatenNormal.contains(SONG.song))
					FlxG.save.data.beatenNormal.push(SONG.song);

				if (FlxG.save.data.beatenNormal.length >= 4)
					FlxG.save.data.normalBeat = true;
			}
			FlxG.save.flush();
		}

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if ((Paths.formatToSongPath(SONG.song) == "left-unchecked")) {
					switchState(new LostSilverCutscene());
				} else {
					if (storyPlaylist.length <= 0)
						{
							FlxG.sound.playMusic(Paths.music('HYPNO_MENU'));

							cancelFadeTween();
							CustomFadeTransition.nextCamera = camOther;
							if(FlxTransitionableState.skipNextTransIn) {
								CustomFadeTransition.nextCamera = null;
							}
							MusicBeatState.switchState(new MainMenuState());

							// if ()
							if(!usedPractice) {
								if (SONG.validScore)
									Highscore.saveWeekScore('hypno', campaignScore, storyDifficulty);
							}
							usedPractice = false;
							changedDifficulty = false;
							cpuControlled = false;
						}
						else
						{
							var difficulty:String = '' + CoolUtil.difficultyStuff[storyDifficulty][1];

							trace('LOADING NEXT SONG');
							trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

							var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "safety-lullaby");
							if (winterHorrorlandNext)
							{
								var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
									-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
								blackShit.scrollFactor.set();
								add(blackShit);
								camHUD.visible = false;

								FlxG.sound.play(Paths.sound('transitionSplatter'));
							}

							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;

							prevCamFollow = camFollow;
							prevCamFollowPos = camFollowPos;

							PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
							FlxG.sound.music.stop();

							if(winterHorrorlandNext) {
								new FlxTimer().start(1.5, function(tmr:FlxTimer) {
									cancelFadeTween();
									//resetSpriteCache = true;
									LoadingState.loadAndSwitchState(new PlayState());
								});
							} else {
								cancelFadeTween();
								//resetSpriteCache = true;
								LoadingState.loadAndSwitchState(new PlayState());
							}
						}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('HYPNO_MENU'));
				usedPractice = false;
				changedDifficulty = false;
				cpuControlled = false;
			}
			transitioning = true;
		}
	}

	public function switchState(stateTo:FlxState) {
		/* for a future update :P
		if (endingSong && ClientPrefs.hellMode && (Paths.formatToSongPath(SONG.song) == "left-unchecked") && (FlxG.save.data.hasUnlockedFuck == false || FlxG.save.data.hasUnlockedFuck == null)) {
			MusicBeatState.switchState(new HellState(stateTo));
		} else
		*/
			MusicBeatState.switchState(stateTo);
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var ratingIndexArray:Array<String> = ["sick", "good", "bad", "shit"];
	public var returnArray:Array<String> = [" [SFC]", " [GFC]", " [FC]", ""];
	public var smallestRating:String;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + 8);

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;
		var healthMultiplier:Float = 1;

		ratingString = '';
		var daRating:String = "sick";
		if (noteDiff > 120)
		{
			daRating = 'shit';
			score = -50;
			healthMultiplier = -1;
			songMisses++;
			combo = 0;
		}
		else if (noteDiff > 100)
		{
			daRating = 'bad';
			score = 100;
			healthMultiplier = 0.1;
		}
		else if (noteDiff > 50)
		{
			daRating = 'good';
			score = 200;
			healthMultiplier = 0.5;
		}

		health += note.hitHealth * healthMultiplier;

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if (songMisses <= 0) {
			if (ratingIndexArray.indexOf(daRating) > ratingIndexArray.indexOf(smallestRating))
				smallestRating = daRating;
			ratingString = returnArray[ratingIndexArray.indexOf(smallestRating)];
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			RecalculateRating();
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.1;
			scoreTxt.scale.y = 1.1;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;

		var upP = controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;
		var downP = controls.NOTE_DOWN_P;
		var leftP = controls.NOTE_LEFT_P;

		var upR = controls.NOTE_UP_R;
		var rightR = controls.NOTE_RIGHT_R;
		var downR = controls.NOTE_DOWN_R;
		var leftR = controls.NOTE_LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
		var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if ((controlHoldArray.contains(true) || controlArray.contains(true)) && !endingSong) {
				var canMiss:Bool = !ClientPrefs.ghostTapping;
				if (controlArray.contains(true)) {
					for (i in 0...controlArray.length) {
						// heavily based on my own code LOL if it aint broke dont fix it
						var pressNotes:Array<Note> = [];
						var notesDatas:Array<Int> = [];
						var notesStopped:Bool = false;

						var sortedNotesList:Array<Note> = [];
						notes.forEachAlive(function(daNote:Note)
							{
								if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate
								&& !daNote.wasGoodHit && daNote.noteData == i) {
									sortedNotesList.push(daNote);
									notesDatas.push(daNote.noteData);
								}
							});
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0) {
							for (epicNote in sortedNotesList)
							{
								for (doubleNote in pressNotes) {
									if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 10) {
										doubleNote.kill();
										notes.remove(doubleNote, true);
										doubleNote.destroy();
									} else
										notesStopped = true;
								}

								// eee jack detection before was not super good
								if (controlArray[epicNote.noteData] && !notesStopped) {
									goodNoteHit(epicNote);
									pressNotes.push(epicNote);
								}

							}
						}
						else if (canMiss)
							ghostMiss(controlArray[i], i, true);

						// I dunno what you need this for but here you go
						//									- Shubs

						// Shubs, this is for the "Just the Two of Us" achievement lol
						//									- Shadow Mario

						// WE'RE COMMUNICATION THROUGH SOURCE CODES
						//									- Shubs
						if (!keysPressed[i] && controlArray[i])
							keysPressed[i] = true;
					}
				}

				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			} else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		playerStrums.forEach(function(spr:StrumNote)
		{
			if (controlArray[spr.ID]) {
				if (spr.animation.curAnim.name != 'confirm') {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			}

			if(controlReleaseArray[spr.ID]) {
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		});
	}

	function ghostMiss(statement:Bool = false, direction:Int = 0, ?ghostMiss:Bool = false) {
		if (statement) {
			noteMissPress(direction, ghostMiss);
			callOnLuas('noteMissPress', [direction]);
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		health -= daNote.missHealth; //For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		combo = 0;
		vocals.volume = 0;
		RecalculateRating();

		var animToPlay:String = '';
		switch (Math.abs(daNote.noteData) % 4)
		{
			case 0:
				animToPlay = 'singLEFTmiss';
			case 1:
				animToPlay = 'singDOWNmiss';
			case 2:
				animToPlay = 'singUPmiss';
			case 3:
				animToPlay = 'singRIGHTmiss';
		}

		var daAlt = '';
		if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

		boyfriend.playAnim(animToPlay + daAlt, true);
		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1, ?ghostMiss:Bool = false):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.04;
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				if(ghostMiss) ghostMisses++;
				songMisses++;
			}
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			switch (direction)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}
			vocals.volume = 0;
		}
	}

	var camDisplaceX:Float = 0;
	var camDisplaceY:Float = 0;


	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = '';
				switch (Std.int(Math.abs(note.noteData)))
				{
					case 0:
						animToPlay = 'singLEFT';
					case 1:
						animToPlay = 'singDOWN';
					case 2:
						animToPlay = 'singUP';
					case 3:
						animToPlay = 'singRIGHT';
				}

				boyfriend.playAnim(animToPlay + daAlt, true);
				boyfriend.holdTimer = 0;

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];
		super.destroy();
	}

	public function cancelFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	function winPendulum() {
		trance -= 0.02;
		var shadow:FlxSprite = pendulum.clone();
		shadow.scale.set(pendulum.scale.x, pendulum.scale.y);
		shadow.updateHitbox();
		shadow.setPosition(pendulum.x, pendulum.y);
		shadow.cameras = pendulum.cameras;
		shadow.origin.set(pendulum.origin.x, pendulum.origin.y);
		shadow.angle = pendulum.angle;
		shadow.antialiasing = true;
		pendulumShadow.add(shadow);
		shadow.alpha = 0.5;
		FlxTween.tween(shadow, {alpha: 0}, Conductor.stepCrochet / 1000, {ease: FlxEase.linear, startDelay: Conductor.stepCrochet / 1000, onComplete: function (twn:FlxTween) {
			pendulumShadow.remove(shadow);
		}});
		trace('GOOD');
	}

	var reducedDrain:Float = 4;

	function losePendulum(forced:Bool = false) {

		trance += 0.2 / ((!forced && !pendulumDrain) ? reducedDrain : 1);
		trace("BAD");
	}

	function fakeshock() {
		psyshockParticle.setPosition(dad.x, dad.y);
		psyshockParticle.playAnim("psyshock particle", true);
		psyshockParticle.alpha = 1;
		psyshockParticle.animation.finishCallback = function (lol:String) {
			psyshockParticle.alpha = 0;
		};
		tranceDeathScreen.alpha += 0.1;
		tranceCanKill = false;
		FlxG.sound.play(Paths.sound('Psyshock', 'shared'), 1);
		if (!ClientPrefs.photosensitive)
			camHUD.flash(FlxColor.fromString('0xFFFFAFC1'), 1, null, true);
	}

	function psyshock() {
		if (!ClientPrefs.pussyMode) {
			//var psyshockParticle = new Character(0, 0, 'hypno');
			psyshockParticle.setPosition(dad.x, dad.y);
			//add(psyshockParticle);
			psyshockParticle.playAnim("psyshock particle", true);
			psyshockParticle.alpha = 1;

			psyshockParticle.animation.finishCallback = function (lol:String) {
				psyshockParticle.alpha = 0;
			};

			trance += (0.45 / ((!pendulumDrain) ? (reducedDrain / 2) : 1));

			FlxG.sound.play(Paths.sound('Psyshock', 'shared'), 1);
			if (!ClientPrefs.photosensitive)
				camHUD.flash(FlxColor.fromString('0xFFFFAFC1'), 1, null, true);
		}
	}
	override function stepHit()
	{
		super.stepHit();
		if (tranceActive) {
			if (psyshockCooldown <= 0) {

				psyshock();

				if (dad.curCharacter == 'hypno') {
					dad.playAnim('psyshock', true);
					psyshocking = true;
					new FlxTimer().start(Conductor.stepCrochet * 4 / 1000, function(tmr:FlxTimer)
					{
						psyshocking = false;
					});
					psyshockCooldown = FlxG.random.int(70, 150);
				} else
					psyshockCooldown = FlxG.random.int(60, 90);
			} else {
				psyshockCooldown--;
			}
		}
		if (tranceActive) {
			if (ClientPrefs.hellMode) {
				switch (curStep % 8) {
					case 3 | 7:
						canHitPendulum = true;
					case 5 | 1:
						canHitPendulum = false;
						if (!hitPendulum) {
							if (skippedFirstPendulum)
								losePendulum();
							else
								skippedFirstPendulum = true;
						} else {
							hitPendulum = false;
						}
					case 4 | 0:
						keyboard.animation.play('press', true);
				}
			} else {
				switch (curStep % 16) {
					case 7 | 15:
						canHitPendulum = true;
						//pendulum.color = FlxColor.GREEN;
					case 10 | 2:
						canHitPendulum = false;
						if (!hitPendulum) {
							if (skippedFirstPendulum)
								losePendulum();
							else
								skippedFirstPendulum = true;
						} else {

							hitPendulum = false;


						}

						//pendulum.color = FlxColor.RED;
					case 8 | 0:
						keyboard.animation.play('press', true);
					case 9 | 1:
						keyboard.animation.play('idle', true);
						if (keyboardTimer > 0) {
							keyboardTimer--;
						} else {
							FlxTween.tween(keyboard, {alpha: 0}, Conductor.stepCrochet * 4 / 1000, {ease: FlxEase.linear});
						}
				}
			}
		}
		switch (boyfriend.curCharacter) {
			case 'gf':
				if (!whiteHandDone) {
					if (FlxG.random.int(0, 10000) == 5) {
						doTheHand();
						whiteHandDone = true;
					}
				}
		}
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	function resetPendulum() {
		pendulum.daTween.cancel();

		if (SONG.player2 == 'hypno')
			pendulum.angle = -9;
		else
			pendulum.angle = 0;
		pendulumSwing();
	}
	override function beatHit()
	{
		super.beatHit();
		if (ClientPrefs.fuckMode && curBeat % 16 == 0)
			missingnoThing();
		if (tranceActive) {
			if (!pendulum.daTween.active) {
				if (SONG.player2 == 'hypno')
					pendulum.angle = -9;
				else
					pendulum.angle = 0;
				pendulumSwing();
			}
		}
		if (ClientPrefs.hellMode) {
			if (curBeat % 2 == 0)
				resetPendulum();
		} else {
			if (curBeat % 4 == 0)
				resetPendulum();
		}
		switch (SONG.song.toLowerCase()) {
			case 'missingno':
				switch (curBeat) {
					case 59:
						dad.debugMode = true;
						dad.playAnim('intro', true);
						dad.visible = true;
						FlxG.sound.play(Paths.sound('missingnospawn', 'shared'));
						dad.animation.finishCallback = function (name:String) {
							dad.debugMode = false;
							dad.animation.finishCallback = null;
						};
						FlxTween.tween(iconP2, {alpha: 1}, 1, {ease: FlxEase.linear});
					case 267:
						for (i in opponentStrums) {
							FlxTween.tween(i, {alpha: 0}, 0.7, {ease: FlxEase.linear});
						}
					case 64:
						defaultCamZoom = 0.8;
					case 192 | 96 | 128 | 176 | 224 | 416 | 464 | 496:
						if (ClientPrefs.hellMode)
							startUnown(16);
					case 264:
						if (ClientPrefs.hellMode)
							startUnown(8);
					case 320:
						if (ClientPrefs.hellMode)
							startUnown(32, '?????????????????????????????????????????????????????????????????????????????????????????');
					case 56:
						if (ClientPrefs.hellMode)
							startUnown(8, 'missingno');
				}
			case 'monochrome':
				switch (curBeat) {
					case 28:
						FlxTween.tween(healthBar, {alpha: 0.4}, 3, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 0.4}, 3, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0.4}, 3, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 1}, 3, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 1}, 3, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0.7}, 3, {ease: FlxEase.linear});
						}
					case 392:
						dad.debugMode = true;
						dad.playAnim('fadeOut', true);
						FlxTween.tween(healthBar, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(healthBarBG, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP1, {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.linear});
						for (i in playerStrums) {
							FlxTween.tween(i, {alpha: 0}, 1, {ease: FlxEase.linear});
						}
					case 224:
						/*if (ClientPrefs.hellMode)
							startUnown(16, 'abcdefghijklmnopqrstuvwxyz');
						else
							startUnown(8);*/
					case 232:
						/*if (!ClientPrefs.hellMode)
							startUnown(8);*/
				}
		}
		if(lastBeatHit >= curBeat) {
			trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, isDownscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if(curBeat % 2 == 0) {
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned && !psyshocking)
			{
				dad.dance();
			}
		} else if(dad.danceIdle && dad.animation.curAnim.name != null && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned && !psyshocking) {
			dad.dance();
		}

		switch (curStage) {
			default:
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingString:String;
	public var ratingPercent:Float;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('ghostMisses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop) {
			ratingPercent = songScore / ((songHits + songMisses - ghostMisses) * 350);
			if(!Math.isNaN(ratingPercent) && ratingPercent < 0) ratingPercent = 0;

			if(Math.isNaN(ratingPercent)) {
				ratingString = '?';
			} else if(ratingPercent >= 1) {
				ratingPercent = 1;
			}

			setOnLuas('rating', ratingPercent);
			setOnLuas('ratingName', ratingString);
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String>):String {
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName)) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode && !cpuControlled) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice && !cpuControlled) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 20 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}

class Pendulum extends FlxSprite
{
	public var daTween:FlxTween;
	public function new()
	{
		super();
		daTween = FlxTween.tween(this, {x: this.x}, 0.001, {});
	}
}
