package meanderer;

/**
 * Meanderer
 * 
 * @author Mike Almond | https://github.com/mikedotalmond
 */

import haxe.Json;
import js.phantomjs.FileSystem;
import js.phantomjs.Phantom;
import js.phantomjs.PhantomTools;
import js.phantomjs.System;

using StringTools;

class Main {
	
	public static var config(default, null):Config;
	public static var uaStrings(default, null):Array<String>;
	public static var dictionary(default, null):Array<String>;
	static public var quiet(default,null):Bool;
	
	static public var navigatedURLs(default,null):Array<String> = [];	
	
	static var maxURLHistory:Int = 4096;
	static var agents:Array<Meanderer>;
	
	
	static function main() {
		
		if (PhantomTools.noPhantom()) return; // exit if not in phantom scope
		
		var args = System.args;
		var confFile = 'config/conf.json';
		var n = args.length;
		var i = 1;
		while (i < n){
			switch(args[i]){
				case '-quiet':
					quiet = true;
				case '-config':
					i++;
					if (n > i) confFile = args[i].trim();
					else help();
					
				case '-help': help();
				default: help();					
			}
			i++;
		}
		
		log('Meanderer - A random surfer.');
		
		if (!FileSystem.exists(confFile)){
			log('File Error: Can\'t read the config json at: $confFile');
			help();
		}
		
		config = Json.parse(FileSystem.read(confFile));
		
		if (loadData()) {
			setupLogs();
			agents = [for (i in 0...config.meandererCount) Meanderer.create()];
		}
	}
	
	
	static function help() {
		log('Usage: phantomjs bin/meanderer.js [-config path/to/config.json] [-quiet]');
		log('If not specified, config path defaults to config/conf.json');
		Phantom.exit();
	}
	
	
	static function setupLogs() {
		if (config.logging.enabled) {			
			var logFile = '${config.logging.location}/urls.log';
			if (!FileSystem.exists(logFile)) FileSystem.write(logFile, 'sessionTime,time,url\n', 'w');
			
			var errorFile = '${config.logging.location}/error.log';
			if (!FileSystem.exists(errorFile)) FileSystem.write(errorFile, '', 'w');
		}
	}
	
	
	static function loadData() {
		
		if (!FileSystem.exists(config.userAgentsFile)){
			log('File Error: Can\'t find userAgents file at "${config.userAgentsFile}"');
			log('Check the userAgentsFile property in the config json');
			help();
			return false;
		}
		
		if (!FileSystem.exists(config.dictionaryFile)){
			log('File Error: Can\'t find dictionary file at "${config.dictionaryFile}"');
			log('Check the dictionaryFile property in the config json');
			help();
			return false;
		}
		
		uaStrings = FileSystem.read(config.userAgentsFile).split('\r').filter(function(ua) return ua.trim().length > 0);
		log('Loaded ${uaStrings.length} userAgent strings.');
		
		dictionary = Json.parse(FileSystem.read(config.dictionaryFile));
		log('Loaded ${dictionary.length} dictionary words.');
		
		return true;
	}
	
	
	public static function kill(agent:Meanderer, repopulate:Bool=true){
		var i = agents.length;
		while (i-- > 0){
			
			if (agents[i].id == agent.id){
				agent.reset();
				agent = null;
				
				if (repopulate) {
					agents[i] = Meanderer.create();
				} else {
					agents.splice(i, 1);
				}
				
				break;
			}
		}
	}
	
	
	public static function log(a:Any){
		if (!quiet) trace(a);
	}
	
	
	public static function logError(a:Any){
		if (config.logging.enabled) {
			FileSystem.write('${config.logging.location}/error.log', '${Util.now()} ${a}\n','a');
		}
		#if debug 
		if (!quiet) trace(a);
		#end
	}
	
	
	public static function logURL(url:String, m:Meanderer) {
		if (config.logging.enabled) {
			FileSystem.write('${config.logging.location}/urls.log', '${m.sessionTime},${Util.now()},${url}\n','a');
		}
		#if debug
		if (!quiet) trace(url);
		#end
	}
	
	
	public static function addURL(url:String) {
		if (visitedURL(url)) return;
		
		navigatedURLs.push(url);
		if (navigatedURLs.length == maxURLHistory) navigatedURLs.shift();
	}
	
	
	public static inline function visitedURL(url:String):Bool {
		return navigatedURLs.indexOf(url) != -1;
	}
}