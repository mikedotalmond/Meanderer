package meanderer;

/**
 * Meanderer
 * 
 * @author Mike Almond | https://github.com/mikedotalmond
 */

import haxe.Timer;
import js.Browser;
import js.html.Location;
import js.phantomjs.FileSystem;
import js.phantomjs.WebPage;

import meanderer.Util;

class Meanderer {
	
	static var ID:Int = 0;
	
	var page:WebPage;
	var pageLocation:Location;
	var isSearch:Bool;
	var currentURL:String;
	
	var loadStart:Float; 
	var loadTimer:Int =-1; // timeout id - so delayed actions can be cancelled
	var sessionUA:String; // User agent string used for this session
	
	public var id(default, null):Int = -1;
	public var sessionTime(default, null):Float; // time the session was started
	
	
	public static function create(){
		return new Meanderer(ID++);
	}
	
	function new(id:Int){
		this.id = id;
		
		sessionTime = Util.now();
		sessionUA = Util.randomItem(Main.uaStrings);
		
		var viewport = Main.config.capture.viewport;
		log('New session. userAgent: $sessionUA');
		
		createPage();
		isSearch = true;
		openPage(Util.buildRandomSearchQuery());
	}
	
	
	function createPage() {
		page = WebPage.create();
		page.onError = onPageError;
		page.onLoadStarted = pageLoadStarted;
		page.onLoadFinished = cast pageLoaded;
		page.settings.userAgent = sessionUA;
		if (Main.config.capture.enabled) page.viewportSize = Main.config.capture.viewport;
	}
	
	
	function openPage(url:String) {
		
		clearTimeout(loadTimer);
		loadTimer = -1; loadStart = -1;
		
		info('openPage: $url');
		currentURL = url;
		
		Main.addURL(url);
		Main.logURL(url, this);
		
		stallTimer();
		page.open(url);
	}
	
	
	function stallTimer() {
		clearTimeout(loadTimer);
		loadTimer = setTimeout(onLoadStalled, Main.config.loadStallTimeout * 1000);
	}
	
	
	function onLoadStalled(){
		info('Page load stalled. Restarting.');
		Main.kill(this);
	}
	
	
	// log js errors on loaded page
	function onPageError(message:String, stacktrace:Array<{file:String, line:String}>){
		error('pageError - ${currentURL} - $message');
		//log(stacktrace);
	}
	
	
	function pageLoadStarted(){
		log('page onLoadStarted');
		stallTimer();
		loadStart = Util.now();
	}
	
	
	function pageLoaded(status:String, ?tries:Int=0) {
		
		clearTimeout(loadTimer);
		loadTimer =-1;
		
		if (status == 'success'){
			
			var readyState = page.evaluate(function() return Browser.document.readyState);
			log('readyState:' + readyState); // wait for 'complete'
			
			if (readyState != 'complete'){
				if (tries <= Main.config.loadStallTimeout){
					loadTimer = setTimeout(pageLoaded.bind('success', tries + 1), 1000);
				} else {
					info('Page load stalled while waiting for readyState. Restarting.');
					Main.kill(this);
				}
				return;
			}
			
			// wait a bit more for any further rendering to complete
			loadTimer = setTimeout(processPage, 2000);
			
		} else {
			info('Could not load page. Status:$status. Restarting');
			Main.kill(this);
		}
	}
	
	
	function processPage() {
		
		var time = Util.now();
		
		info('Page ready, ${time - loadStart}ms after load-start.');
		log('isSearch :$isSearch');
		
		// read document location of currently loaded page
		pageLocation = page.evaluate(function() return Browser.document.location);
		
		// get links from page
		var links = Util.processLinks(page, pageLocation, isSearch);
		
		// get unique words from page - used to help create search terms when a new search is needed
		Util.processTextContent(page);
		
		if (links == null || links.length == 0){
			log('No links on current page');
		}else{
			log('Got ${links.length} links');
		}
		
		var conf = Main.config;
		var capture = conf.capture;
		
		if (capture.enabled) {
			log('${time} Rendering');
			page.render('${capture.location}/${sessionTime}/${time}_${pageLocation.hostname}.${capture.options.format}', capture.options);
		}
		
		reset();
		
		// wait time, seconds
		var wait = conf.interval.min + Std.int(Math.random() * conf.interval.max);
		if (wait < 1) wait = 1;
		
		var next = getNextURL(pageLocation, links);
		
		info('Next load in ${wait} seconds: "$next"');
		
		loadTimer = setTimeout(function(){
			createPage();
			openPage(next);
		}, wait * 1000);
	}
	
	
	function getNextURL(current:Location, pageLinks:Array<LinkVO>) {
		
		isSearch = false;
		
		var url = null;
		var lnk = Util.randomItem(pageLinks);
		if(lnk != null) url = lnk.protocol + '//' + lnk.hostname + lnk.pathname;
		
		if (url == null || Main.visitedURL(url)){
			log('No usable URL - New search');
			url = Util.buildRandomSearchQuery();
			isSearch = true;
		}
		
		return url;
	}
	
	
	public function reset(){
		clearTimeout(loadTimer);
		loadTimer =-1;
		try {
			page.onError = null;
			page.onLoadFinished = null;
			page.onLoadStarted = null;
			page.close();
			page.release();
			page = null;
		} catch(err:Dynamic){
			error(err);
		}
	}
	

	inline function error(a:Any) Main.logError('[$id] $a');
	inline function info(a:Any) Main.log('[$id] $a');
	inline function log(a:Any) {
		#if debug
		info(a);
		#end
	}
	
	inline static function clearTimeout(id:Int) Browser.window.clearTimeout(id);
	inline static function setTimeout(fn:haxe.Constraints.Function, timeout:Int = 0):Int return Browser.window.setTimeout(fn, timeout);
}