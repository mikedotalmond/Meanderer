package runner;

/**
 * Meanderer Runner - little script to start the phantomjs Meanderer process and keep running when phantomjs inevitably crashes.
 * 
 * @author Mike Almond | https://github.com/mikedotalmond
 */

import haxe.io.Eof;
import sys.io.Process;

using StringTools;

class Main {
	
	static var quiet:Bool = false;
	static var configFile:String = 'config/conf.json';
	
	static function main() {
		
		log('Meanderer Runner');
		
		var args = Sys.args();
		var n = args.length;
		var i = 0;
		while (i < n){
			switch(args[i]){
				case '-quiet':
					quiet = true;
			
				case '-config':
					i++;
					if (n > i) configFile = args[i].trim();
					else help();
				
				case '-help': help();
				default: help();
			}
			i++;
		}
		
		var canRecover = true;
		var m = createMeandererProcess();
		var id = m.getPid();
		
		while (true){
			
			try {
				
				var msg = m.stdout.readLine();
				log(msg);
				
				// if ioerror - can't load some part of the config/data. exit.
				if (msg.indexOf('File Error:') == 0) canRecover = false;
				
			} catch (err:Eof){
				
				var code = m.exitCode();
				log('Meanderer phantomjs process (pid:${id}) exited with code: ${code}');
				m.close();
				
				if (canRecover){
					// phantomjs exited (crashed), start again
					m = createMeandererProcess();
					id = m.getPid();
				} else {
					Sys.exit(code);
				}
			}
		}
	}
	
	
	static private function help() {
		log('Usage: python runner.py [-config path/to/config] [-quiet]');
		Sys.exit(0);
	}

	
	static function createMeandererProcess(){
		var args = [
			'bin/meanderer.js',
			'-config', configFile,
		];
		
		if (quiet) args.push('-quiet');
		
		log('Starting phantomjs process...');
		
		return new Process('phantomjs', args);
	}
	
	
	static function log(message:Any){
		if (!quiet) Sys.println(message);
	}
}