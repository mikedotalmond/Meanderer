package meanderer;

/**
 * @author Mike Almond | https://github.com/mikedotalmond
 * 
 * typedefs for the config json file
 * @see config/conf.json
 */

typedef Config = {
	
	/**
	 * Define custom userAgent strings for PhantomJS to use while browsing. One is selected at random per session.
	 * Text file with entries separated by new lines. Example included has data for current versions of Chrome and Firefox on Windows.
	 */
	var userAgentsFile:String; // file path
	
	
	/**
	 * Dictionary file - A JSON Array<String>
	 * The dictionary words are used to build search queries.
	 */
	var dictionaryFile:String; // file path
	
	
	/**
	 * Number of meanderers (phantomjs pages) to run at any one time. 
	 * Think of as number of tabs open in browser, each doing its own thing.
	 * 
	 * Recommend keeping this fairly low, especially if screenshot capture is enabled;
	 * phantomjs seems to like crashing if it tries to save many images at once.
	 */
	var meandererCount:Int;
	
	
	/**
	 * Time (in seconds) to wait between page load and next page request.
	 * Be wary of requesting too often with too little wait time - you're likely to get a
	 * temporary ban on search engines if spamming them with requests.
	 * 
	 * A value is selected randomly from the range specified by the min and max.	
	 */
	var interval:{min:Int, max:Int}; 
	
	
	/**
	 * Time (in seconds) to wait before aborting a page load.
	 */
	var loadStallTimeout:Int; // 
	
	
	/**
	 * Will log visited URLs and in-page JS errors when enabled. 
	 * Log files (urls.log and error.log) are created at the specified `location`
	 */
	var logging:{enabled:Bool, location:String};
	
	
	/**
	 * Capture screenshots of loaded pages
	 */
	var capture:{
		enabled:Bool,
		location:String, // file save path		
		options:{// see http://phantomjs.org/api/webpage/method/render.html
			format:String, // jpeg/png
			quality:Int // 0-100
		},
		viewport:{width:Float, height:Float}
	};
	
	
	/**
	 * Search query settings
	 */
	var search:{
		/**
		 * Search engines to use when starting a new session.
		 * '::query::' marks the location of the dictionary-based query
		 * '::offset::' marks where an optional result offset (pagination of search results) is injected. Uses the search.offsetRange property.
		 * 
		 *  Example: "https://encrypted.google.com/#q=::query::&hl=en&start=::offset::"
		 */
		urls:Array<String>,
		
		/**
		 * The number of words to use to build a search query.
		 * Values are selected randomly between the specified min and max.	
		 */
		queryWords:{min:Int, max:Int},
		
		/**
		 * Offset value for search queries
		 * A value is selected randomly from the range specified by the min and max.
		 */
		offsetRange:{min:Int, max:Int}
	};
	
	
	/**
	 * Only links ending with these file types will be allowed when selecting the next page to load.
	 * Applied when filtering links on a loaded page.
	 */
	var allowedExtensions:Array<String>;
	
	
	/**
	 * Links containing these strings will be ignored when selecting the next page to load.
	 * Applied when filtering links on a loaded page.
	 */
	var ignoreLinksContaining:Array<String>;
}