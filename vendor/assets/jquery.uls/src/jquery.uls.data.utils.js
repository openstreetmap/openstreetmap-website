/**
 * Utility functions for querying language data.
 *
 * Copyright (C) 2012 Alolita Sharma, Amir Aharoni, Arun Ganesh, Brandon Harris,
 * Niklas Laxström, Pau Giner, Santhosh Thottingal, Siebrand Mazeland and other
 * contributors. See CREDITS for a list.
 *
 * UniversalLanguageSelector is dual licensed GPLv2 or later and MIT. You don't
 * have to do anything special to choose one license or the other and you don't
 * have to notify anyone which license you are using. You are free to use
 * UniversalLanguageSelector in commercial projects as long as the copyright
 * header is left intact. See files GPL-LICENSE and MIT-LICENSE for details.
 *
 * @file
 * @license GNU General Public Licence 2.0 or later
 * @license MIT License
 */

( function ( $ ) {
	'use strict';

	/**
	 * Is this language a redirect to another language?
	 *
	 * @param {string} language Language code
	 * @return {string|boolean} Target language code if it's a redirect or false if it's not
	 */
	$.uls.data.isRedirect = function ( language ) {
		return ( $.uls.data.languages[ language ] !== undefined &&
			$.uls.data.languages[ language ].length === 1 ) ?
			$.uls.data.languages[ language ][ 0 ] : false;
	};

	/**
	 * Returns the script of the language.
	 *
	 * @param {string} language Language code
	 * @return {string}
	 */
	$.uls.data.getScript = function ( language ) {
		var target = $.uls.data.isRedirect( language );

		if ( target ) {
			return $.uls.data.getScript( target );
		}

		if ( !$.uls.data.languages[ language ] ) {
			// Undetermined
			return 'Zyyy';
		}

		return $.uls.data.languages[ language ][ 0 ];
	};

	/**
	 * Returns the regions in which a language is spoken.
	 *
	 * @param {string} language Language code
	 * @return {string|string[]}
	 */
	$.uls.data.getRegions = function ( language ) {
		var target = $.uls.data.isRedirect( language );

		if ( target ) {
			return $.uls.data.getRegions( target );
		}

		return ( $.uls.data.languages[ language ] && $.uls.data.languages[ language ][ 1 ] ) || 'UNKNOWN';
	};

	/**
	 * Returns the autonym of the language.
	 *
	 * @param {string} language Language code
	 * @return {string}
	 */
	$.uls.data.getAutonym = function ( language ) {
		var target = $.uls.data.isRedirect( language );

		if ( target ) {
			return $.uls.data.getAutonym( target );
		}

		return ( $.uls.data.languages[ language ] &&
			$.uls.data.languages[ language ][ 2 ] ) || language;
	};

	/**
	 * Returns all language codes and corresponding autonyms
	 *
	 * @return {string[]}
	 */
	$.uls.data.getAutonyms = function () {
		var language,
			autonymsByCode = {};

		for ( language in $.uls.data.languages ) {
			if ( $.uls.data.isRedirect( language ) ) {
				continue;
			}

			autonymsByCode[ language ] = $.uls.data.getAutonym( language );
		}

		return autonymsByCode;
	};

	/**
	 * Returns all languages written in script.
	 *
	 * @param {string} script string
	 * @return {string[]} languages codes
	 */
	$.uls.data.getLanguagesInScript = function ( script ) {
		return $.uls.data.getLanguagesInScripts( [ script ] );
	};

	/**
	 * Returns all languages written in the given scripts.
	 *
	 * @param {string[]} scripts
	 * @return {string[]} languages codes
	 */
	$.uls.data.getLanguagesInScripts = function ( scripts ) {
		var language, i,
			languagesInScripts = [];

		for ( language in $.uls.data.languages ) {
			if ( $.uls.data.isRedirect( language ) ) {
				continue;
			}

			for ( i = 0; i < scripts.length; i++ ) {
				if ( scripts[ i ] === $.uls.data.getScript( language ) ) {
					languagesInScripts.push( language );
					break;
				}
			}
		}

		return languagesInScripts;
	};

	/**
	 * Returns an associative array of languages in a region,
	 * grouped by script group.
	 *
	 * @param {string} region Region code
	 * @return {Object}
	 */
	$.uls.data.getLanguagesByScriptGroupInRegion = function ( region ) {
		return $.uls.data.getLanguagesByScriptGroupInRegions( [ region ] );
	};

	/**
	 * Get the given list of languages grouped by script.
	 *
	 * @param {string[]} languages Array of language codes to group
	 * @return {string[]} Array of language codes
	 */
	$.uls.data.getLanguagesByScriptGroup = function ( languages ) {
		var languagesByScriptGroup = {},
			language, languageIndex, resolvedRedirect, langScriptGroup;

		for ( languageIndex = 0; languageIndex < languages.length; languageIndex++ ) {
			language = languages[ languageIndex ];
			resolvedRedirect = $.uls.data.isRedirect( language ) || language;
			langScriptGroup = $.uls.data.getScriptGroupOfLanguage( resolvedRedirect );
			if ( !languagesByScriptGroup[ langScriptGroup ] ) {
				languagesByScriptGroup[ langScriptGroup ] = [];
			}
			languagesByScriptGroup[ langScriptGroup ].push( language );
		}
		return languagesByScriptGroup;
	};

	/**
	 * Returns an associative array of languages in several regions,
	 * grouped by script group.
	 *
	 * @param {string[]} regions region codes
	 * @return {Object}
	 */
	$.uls.data.getLanguagesByScriptGroupInRegions = function ( regions ) {
		var language, i, scriptGroup,
			languagesByScriptGroupInRegions = {};

		for ( language in $.uls.data.languages ) {
			if ( $.uls.data.isRedirect( language ) ) {
				continue;
			}

			for ( i = 0; i < regions.length; i++ ) {
				if ( $.uls.data.getRegions( language ).indexOf( regions[ i ] ) !== -1 ) {
					scriptGroup = $.uls.data.getScriptGroupOfLanguage( language );

					if ( languagesByScriptGroupInRegions[ scriptGroup ] === undefined ) {
						languagesByScriptGroupInRegions[ scriptGroup ] = [];
					}

					languagesByScriptGroupInRegions[ scriptGroup ].push( language );
					break;
				}
			}
		}

		return languagesByScriptGroupInRegions;
	};

	/**
	 * Returns the script group of a script or 'Other' if it doesn't
	 * belong to any group.
	 *
	 * @param {string} script Script code
	 * @return {string} script group name
	 */
	$.uls.data.getGroupOfScript = function ( script ) {
		var scriptGroup;

		for ( scriptGroup in $.uls.data.scriptgroups ) {
			if ( $.uls.data.scriptgroups[ scriptGroup ].indexOf( script ) !== -1 ) {
				return scriptGroup;
			}
		}

		return 'Other';
	};

	/**
	 * Returns the script group of a language.
	 *
	 * @param {string} language Language code
	 * @return {string} script group name
	 */
	$.uls.data.getScriptGroupOfLanguage = function ( language ) {
		return $.uls.data.getGroupOfScript( $.uls.data.getScript( language ) );
	};

	/**
	 * Return the list of languages sorted by script groups.
	 *
	 * @param {string[]} languages Array of language codes to sort
	 * @return {string[]} Array of language codes
	 */
	$.uls.data.sortByScriptGroup = function ( languages ) {
		var groupedLanguages, scriptGroups, i,
			allLanguages = [];

		groupedLanguages = $.uls.data.getLanguagesByScriptGroup( languages );
		scriptGroups = Object.keys( groupedLanguages ).sort();

		for ( i = 0; i < scriptGroups.length; i++ ) {
			allLanguages = allLanguages.concat( groupedLanguages[ scriptGroups[ i ] ] );
		}

		return allLanguages;
	};

	/**
	 * A callback for sorting languages by autonym.
	 * Can be used as an argument to a sort function.
	 *
	 * @param {string} a Language code
	 * @param {string} b Language code
	 * @return {number}
	 */
	$.uls.data.sortByAutonym = function ( a, b ) {
		var autonymA = $.uls.data.getAutonym( a ) || a,
			autonymB = $.uls.data.getAutonym( b ) || b;

		return ( autonymA.toLowerCase() < autonymB.toLowerCase() ) ? -1 : 1;
	};

	/**
	 * Check if a language is right-to-left.
	 *
	 * @param {string} language Language code
	 * @return {boolean}
	 */
	$.uls.data.isRtl = function ( language ) {
		return $.uls.data.rtlscripts.indexOf( $.uls.data.getScript( language ) ) !== -1;
	};

	/**
	 * Return the direction of the language
	 *
	 * @param {string} language Language code
	 * @return {string}
	 */
	$.uls.data.getDir = function ( language ) {
		return $.uls.data.isRtl( language ) ? 'rtl' : 'ltr';
	};

	/**
	 * Returns the languages spoken in a territory.
	 *
	 * @param {string} territory Territory code
	 * @return {string[]} list of language codes
	 */
	$.uls.data.getLanguagesInTerritory = function ( territory ) {
		return $.uls.data.territories[ territory ] || [];
	};

	/**
	 * Adds a language in run time and sets its options as provided.
	 * If the target option is provided, the language is defined as a redirect.
	 * Other possible options are script, regions and autonym.
	 *
	 * @param {string} code New language code.
	 * @param {Object} options Language properties.
	 */
	$.uls.data.addLanguage = function ( code, options ) {
		if ( options.target ) {
			$.uls.data.languages[ code ] = [ options.target ];
		} else {
			$.uls.data.languages[ code ] = [ options.script, options.regions, options.autonym ];
		}
	};

	/**
	 * Removes a language from the langdb in run time.
	 *
	 * @param {string} code Language code to delete.
	 * @return {boolean} true if the language was removed, false otherwise.
	 */
	$.uls.data.deleteLanguage = function ( code ) {
		if ( $.uls.data.languages[ code ] ) {
			delete $.uls.data.languages[ code ];

			return true;
		}

		return false;
	};
}( jQuery ) );
