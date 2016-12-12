package meanderer;

/**
 * ...
 * @author Mike Almond | https://github.com/mikedotalmond
 */

import js.Browser;
import js.html.AnchorElement;
import js.html.Location;
import js.phantomjs.WebPage;

using StringTools;

typedef LinkVO = {
	var protocol:String;
	var hostname:String;
	var port:String;
	var pathname:String;
	var search:String;
	var hash:String;
	var href:String;
}

class Util {

	static var maxUniqueWords:Int = 4096;
	public static var uniqueWords(default,null):Array<String> = [];
	
	public static function processTextContent(page:WebPage) {

		var textContent = page.evaluate(function() {
			var txt = '';
			var pList = Browser.document.body.getElementsByTagName('p');
			for (i in 0...pList.length) txt += pList.item(i).textContent + ' ';
			return txt;
		});
		
		if (Type.typeof(textContent) == TNull || textContent.length == 0) return;
		
		// split page text into words
		var words = ~/\W+/gi.split(textContent.trim());
		
		var uCount = 0;
		var newUniqueWords:Array<String> = [];
		var counts:Array<Int> = [];
		
		for (w in words) {
			
			// only care about words of certain lengths
			if (w.length > 3 && w.length < 13) {
				
				w = w.toLowerCase();
				var uIndex = newUniqueWords.indexOf(w);
				
				// keep word if it is new and not already in the main dictionary
				if (uIndex == -1) {
					if (Main.dictionary.indexOf(w) == -1) {
						newUniqueWords.push(w);
						counts.push(1);
					}
				} else {
					counts[uIndex]++;
				}
			}
		}
		
		// remove most common words - less likely to be useful for searches
		var i = newUniqueWords.length-1;
		while (i > 0) {
			if (counts[i] > 4) {
				counts.splice(i, 1);
				newUniqueWords.splice(i, 1);
			}
			i--;
		}
		
		if (newUniqueWords.length > 0) {
			uniqueWords = uniqueWords.concat(newUniqueWords);
			if (uniqueWords.length > maxUniqueWords) {
				// trim earliest entries if size exceeds maxUniqueWords
				uniqueWords.splice(0, uniqueWords.length - maxUniqueWords);
			}
		}
	}

	
	public static function processLinks(page:WebPage, pageLocation:Location, ignoreRelative:Bool):Array<LinkVO> {
		
		var data = page.evaluate(function() {
			var getAnchorValues = function(a:AnchorElement) {
				
				return {
					protocol:a.protocol,
					hostname:a.hostname,
					port	:a.port,
					pathname:a.pathname,
					search	:a.search,
					hash	:a.hash,
					href	:a.getAttribute('href'), //get raw value of href node, to detect '/' relative links
				}
			};
			var anchors = Browser.document.getElementsByTagName('a');
			if (anchors.length == 0) return null;
			
			var out = [for (i in 0...anchors.length) getAnchorValues(cast anchors.item(i))];
			return out;
		});
		
		data = filterLinks(data, ignoreRelative);
		
		return data;
	}
	

	public static function filterLinks(data:Array<LinkVO>, ignoreRelative:Bool=false):Array<LinkVO> {
		
		if (data == null || Type.typeof(data) == TNull || data.length==0) return null;
		
		var m = [];
		var navigatedURLs = Main.navigatedURLs;
		
		var ignore = Main.config.ignoreLinksContaining;
		var allowedExtensions = Main.config.allowedExtensions;
		
		// filter the links
		var filtered = data.filter(function(a:LinkVO) {
			
			// check against the ignore list
			for (i in ignore) {
				if ((a.hostname + a.pathname).indexOf(i) != -1) {
					return false;
				}
			}
			
			var simplified = a.hostname + a.pathname;
			
			// ignore duplicates
			if (m.indexOf(simplified) != -1) return false;
			m.push(simplified);
			
			if (navigatedURLs.indexOf(simplified) != -1) return false; // don't revist past destinations
			
			// does path end in a .fileExtension? check it's likely to be an html page and not just an image, pdf, media file... etc.
			var fileParts = a.pathname.split('.');
			if (fileParts.length > 1) {
				var ext = fileParts[fileParts.length - 1].toLowerCase();
				if (allowedExtensions.indexOf(ext) == -1) {
					//trace('This is (probably) not a link to an html webpage - $simplified');
					return false;
				}
			}
			
			if (ignoreRelative && a.href.indexOf('/') == 0) {
				//log('Ignoring relative link: ${a.href} from ${a.hostname}${a.pathname}');
				return false;
			}
			
			return
				a.hash == '' && // ignore #deeplinks
				a.port == '' && // don't really want anything other than the default browser port (80)
				a.protocol.indexOf('http') == 0 && // don't really want to browse any protocols other than http[s]
				Std.parseInt(a.hostname.split('.')[0]) == null; // ignore IPs / numeric subdomains (likely to be media/cdn/ads/spam)
		});
		
		return filtered.length > 0 ? filtered : null;
	}
	
	
	public static function buildSearchPhrase(minWords:Int, maxWords:Int):String {
		
		if (minWords < 1) minWords = 1;
		if (maxWords < minWords) maxWords = minWords;
		
		var count = minWords + Math.round(Math.random() * (maxWords - minWords));
		var phrase = '';
		
		var dictionary = Main.dictionary.concat(uniqueWords);
		
		while (count-- > 0) {
			phrase += '${randomItemOfItems([Main.dictionary,uniqueWords])}';
			if (count > 0) phrase += ' ';
		}
		
		log('buildSearchPhrase: "$phrase"');
		return phrase.urlEncode();
	}
	

	public static function buildRandomSearchQuery() {
		var conf = Main.config.search;
		var searchURL = randomItem(Main.config.search.urls);
		
		var offset = conf.offsetRange;
		var offsetValue = offset.min + Std.int(Math.random() * Math.random() * (offset.max - offset.min));
		searchURL = searchURL.replace("::offset::", '$offsetValue');
		
		var query = buildSearchPhrase(conf.queryWords.min, conf.queryWords.max);
		return searchURL.replace("::query::", query);
	}
	
	
	public static function randomItem<T>(src:Array<T>):T {
		if (Type.typeof(src) == TNull || src.length == 0) return null;
		return src[Std.int(Math.random() * src.length)];
	}

	/**
	 * Pick an item of type T at random from an Array of Array<T>...
	 */
	public static function randomItemOfItems<T>(src:Array<Array<T>>):T {
		if (Type.typeof(src) == TNull || src.length == 0) return null;
		
		var totalItems = 0;
		for (item in src) totalItems += item.length;
		if (totalItems == 0) return null;
		
		var idx = Std.int(Math.random() * totalItems);
		for (item in src) {
			if (idx < item.length) return item[idx];
			idx -= item.length;
		}
		
		return null;
	}
	

	inline public static function now():Float {
		#if js
		return untyped __js__('Date.now()');
		#else
		return Date.now().getTime();
		#end
	}
	
	
	inline static function log(a:Any) {
		#if debug
		Main.log(a);
		#end
	}
}