# Meanderer

A random surfer.

---

Meanderer is a configurable tool that directs [PhantomJS](http://phantomjs.org/) to randomly browse the internet using a dictionary and some search engines. The word-list was adapted from the [RiTaJS](https://github.com/dhowe/RiTaJS) dictionary.


### Usage
- Install PhantomJS, 
- Optionally, install Python 3.x
- Download or clone this repository
- Enter the meanderer directory and either use `python runner.py` or directly run `phantomjs bin/meanderer.js`

The reason for the 'runner' is to handle when PhantomJS exits unexpectedly (i.e. it [crashes](https://github.com/ariya/phantomjs/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20crash)) and the process ends. The runner starts the phantomjs meanderer instance, passing along any arguments and echoing the output back to the command line. If/when PhantomJS crashes, the runner will start it again.

By default, some basic information is sent to the output while running. Pass the `-quiet` flag when launching to prevent that.


### Config
Various settings can be configured via a [JSON file](config/conf.json). 

I encourage you to look at the type definitions for the [Config](src/meanderer/Config.hx) for more information on each of the properties in the file. For example, if you want to keep a record of what it's doing, enable the url logging: `config.logging.enabled` and/or enable screenshot capture: `config.capture.enabled`.

You can specify an alternate location for the configuration JSON file when starting it: `-config path/to/config.json`


### Requirements
This should work anywhere that PhantomJS runs, and it works nicely on the Raspberry Pi. 

Although there are no official builds of PhantomJS for the Raspberry Pi, it can be built from source if you have a few hours to kill. Or, if you prefer, there are some pre-built [PhantomJS binaries from fg2it](https://github.com/fg2it/phantomjs-on-raspberry), so you don't have to bother building it yourself. Download the version that applies to your Pi and follow the instructions there to get it installed and running. Use `phantomjs --version` to verify the installation.


### Build
Uses [Haxe](https://haxe.org) and the phantomjs haxelib.

- `haxelib install phantomjs`
- `haxe build.hxml`

Note: I chose to use Python (requires Python 3) as the default target for the runner since Python is available on many systems, but if you prefer,
building for c++ will make an executable command line application that does the same job on your system of choice.

---

# Why?
Adding noise to your internet connection history.

The UK government recently approved the [Investigatory Powers Bill](https://theintercept.com/2016/11/22/ipbill-uk-surveillance-snowden-parliament-approved/)
and, among other things, internet service providers will now have to keep records of your browsing history for a year and make that information available to a [large
number](https://yiu.co.uk/blog/who-can-view-my-internet-history/) of government departments.

Along with various [new powers](http://www.theregister.co.uk/2016/12/06/parallel_construction_lies_in_english_courts), with the IP Bill the government are retroactively making the last 10+ years of [illegal bulk-data collection](http://www.theregister.co.uk/2016/10/17/court_finds_gchq_and_mi5_engaged_in_illegal_bulk_data_collection/) by the UK's security services, legal. Sadly, as well as being a invasion of privacy for every citizen, it is unlikely to have any real benefit. [Mass surveillance](https://www.privacyinternational.org/node/52) is often invoked as an essential tool to fight terrorism. But there is precious little evidence for this style of 'collect it all' surveillance succeeding in [preventing terrorism](https://theintercept.com/2015/11/17/u-s-mass-surveillance-has-no-record-of-thwarting-large-terror-attacks-regardless-of-snowden-leaks/), or being a [useful tool](https://digg.com/2015/why-mass-surveillance-cant-wont-and-never-has-stopped-a-terrorist) to do so.

This project aims to highlight some of these issues, and add a bit more noise to your browsing history.

[#DontSpyOnUs](https://twitter.com/hashtag/DontSpyOnUs)