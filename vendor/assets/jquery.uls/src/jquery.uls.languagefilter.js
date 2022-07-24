/**
 * jQuery language filter plugin.
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

/**
 * Usage: $( 'inputbox' ).languagefilter();
 * The values for autocompletion is from the options.languages or options.searchAPI.
 *
 * @param {jQuery} $
 */
( function ( $ ) {
	'use strict';

	var LanguageFilter;

	/**
	 * Check if a prefix is visually prefix of a string
	 *
	 * @param {string} prefix
	 * @param {string} string
	 * @return {boolean}
	 */
	function isVisualPrefix( prefix, string ) {
		// Pre-base vowel signs of Indic languages. A vowel sign is called pre-base if
		// consonant + vowel becomes [vowel][consonant] when rendered. Eg: ക + െ => കെ
		var prebases = 'െേൈൊോൌெேைொோௌେୈୋୌિਿिিেৈোৌෙේෛොෝෞ';
		return prebases.indexOf( string[ prefix.length ] ) <= 0;
	}

	LanguageFilter = function ( element, options ) {
		this.$element = $( element );
		this.options = $.extend( {}, $.fn.languagefilter.defaults, options );
		this.$element.addClass( 'languagefilter' );
		this.resultCount = 0;
		this.$suggestion = this.$element.siblings( '.' + this.$element.data( 'suggestion' ) );
		this.$clear = this.$element.siblings( '.' + this.$element.data( 'clear' ) );
		this.selectedLanguage = null;
		this.init();
		this.listen();
	};

	LanguageFilter.prototype = {
		init: function () {
			this.search();
		},

		listen: function () {
			this.$element.on( 'keydown', this.keypress.bind( this ) );
			this.$element.on( 'input', $.fn.uls.debounce( this.onInputChange.bind( this ), 300 ) );

			if ( this.$clear.length ) {
				this.$clear.on( 'click', this.clear.bind( this ) );
			}

			this.toggleClear();
		},

		onInputChange: function () {
			this.selectedLanguage = null;

			if ( !this.$element.val() ) {
				this.clear();
			} else {
				this.options.lcd.empty();
				this.search();
			}

			this.toggleClear();
		},

		keypress: function ( e ) {
			var suggestion, query;

			switch ( e.keyCode ) {
				case 9: // Tab -> Autocomplete
					suggestion = this.$suggestion.val();

					if ( suggestion && suggestion !== this.$element.val() ) {
						this.$element.val( suggestion );
						e.preventDefault();
						e.stopPropagation();
					}
					break;
				case 13: // Enter
					if ( !this.options.onSelect ) {
						break;
					}

					// Avoid bubbling this 'enter' to background page elements
					e.preventDefault();
					e.stopPropagation();

					query = ( this.$element.val() || '' ).trim().toLowerCase();

					if ( this.selectedLanguage ) {
						// this.selectLanguage will be populated from a matching search
						this.options.onSelect( this.selectedLanguage, e );
					} else if ( this.options.languages[ query ] ) {
						// Search is yet to happen (in timeout delay),
						// but we have a matching language code.
						this.options.onSelect( query, e );
					}

					break;
			}
		},

		/**
		 * Clears the current search removing
		 * clear buttons and suggestions.
		 */
		deactivate: function () {
			this.$element.val( '' );

			if ( !$.fn.uls.Constructor.prototype.isMobile() ) {
				this.$element.trigger( 'focus' );
			}

			this.toggleClear();
			this.autofill();
		},

		/**
		 * Clears the search and shows all languages
		 */
		clear: function () {
			this.deactivate();
			this.search();
		},

		/**
		 * Toggles the visibility of clear icon depending
		 * on whether there is anything to clear.
		 */
		toggleClear: function () {
			if ( !this.$clear.length ) {
				return;
			}

			if ( this.$element.val() ) {
				this.$clear.show();
			} else {
				this.$clear.hide();
			}
		},

		search: function () {
			var languages = Object.keys( this.options.languages ),
				results = [],
				query = ( this.$element.val() || '' ).trim().toLowerCase();

			if ( query === '' ) {
				this.options.lcd.setGroupByRegionOverride( null );
				this.resultHandler( query, languages );
				return;
			}

			this.options.lcd.setGroupByRegionOverride( false );
			// Local search results
			results = languages.filter( function ( langCode ) {
				return this.filter( langCode, query );
			}.bind( this ) );

			// Use the searchAPI if available, assuming that it has superior search results.
			if ( this.options.searchAPI ) {
				this.searchAPI( query )
					.done( this.resultHandler.bind( this ) )
					.fail( this.resultHandler.bind( this, query, results, undefined ) );
			} else {
				this.resultHandler( query, results );
			}
		},

		searchAPI: function ( query ) {
			return $.get( this.options.searchAPI, { search: query } ).then( function ( result ) {
				var autofillLabel,
					results = [];

				// eslint-disable-next-line no-jquery/no-each-util
				$.each( result.languagesearch, function ( apiCode, name ) {
					var code, redirect;

					if ( this.options.languages[ apiCode ] ) {
						code = apiCode;
					} else {
						redirect = $.uls.data.isRedirect( apiCode );
						if ( !redirect || !this.options.languages[ redirect ] ) {
							return;
						}
						code = redirect;
					}

					// Because of the redirect checking above, we might get duplicates.
					// For example if API returns both `sr` and `sr-cyrl`, the former
					// could get mapped to `sr-cyrl` and then we would have it twice.
					// The exact cases when this happens of course depends on what is in
					// options.languages, which might contain redirects such as `sr`. In
					// this case we only show `sr` if no other variants are there.
					// This also protects against broken search APIs returning duplicate
					// results, although that is not happening in practice.
					if ( results.indexOf( code ) === -1 ) {
						autofillLabel = autofillLabel || name;
						results.push( code );
					}
				}.bind( this ) );

				return $.Deferred().resolve( query, results, autofillLabel );
			}.bind( this ) );
		},

		/**
		 * Handler method to be called once search is over.
		 * Based on search result triggers resultsfound or noresults events
		 *
		 * @param {string} query
		 * @param {string[]} results
		 * @param {string} [autofillLabel]
		 */
		resultHandler: function ( query, results, autofillLabel ) {
			if ( results.length === 0 ) {
				this.$suggestion.val( '' );
				this.$element.trigger(
					'noresults.uls',
					{
						query: query,
						ulsPurpose: this.options.ulsPurpose
					}
				);
				return;
			}

			if ( query ) {
				this.selectedLanguage = results[ 0 ];
				this.autofill( results[ 0 ], autofillLabel );
			}

			results.map( this.render.bind( this ) );
			this.$element.trigger( 'resultsfound.uls', [ query, results.length ] );
		},

		autofill: function ( langCode, languageName ) {
			var autonym, userInput, suggestion;

			if ( !this.$suggestion.length ) {
				return;
			}

			if ( !this.$element.val() ) {
				this.$suggestion.val( '' );
				return;
			}

			languageName = languageName || this.options.languages[ langCode ];

			if ( !languageName ) {
				return;
			}

			userInput = this.$element.val();
			suggestion = userInput +
				languageName.slice( userInput.length, languageName.length );

			if ( suggestion.toLowerCase() !== languageName.toLowerCase() ) {
				// see if it was autonym match
				autonym = $.uls.data.getAutonym( langCode ) || '';
				suggestion = userInput + autonym.slice( userInput.length, autonym.length );

				if ( suggestion !== autonym ) {
					// Give up. It may be an ISO/script code match.
					suggestion = '';
				}
			}

			// Make sure that it is a visual prefix.
			if ( !isVisualPrefix( userInput, suggestion ) ) {
				suggestion = '';
			}

			this.$suggestion.val( suggestion );
		},

		render: function ( langCode ) {
			return this.options.lcd.append( langCode );
		},

		escapeRegex: function ( value ) {
			return value.replace( /[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&' );
		},

		/**
		 * A search match happens if any of the following passes:
		 * a) Language name in current user interface language
		 * 'starts with' search string.
		 * b) Language autonym 'starts with' search string.
		 * c) ISO 639 code match with search string.
		 * d) ISO 15924 code for the script match the search string.
		 *
		 * @param {string} langCode
		 * @param {string} searchTerm
		 * @return {boolean}
		 */
		filter: function ( langCode, searchTerm ) {
			// FIXME script is ISO 15924 code. We might need actual name of script.
			var matcher = new RegExp( '^' + this.escapeRegex( searchTerm ), 'i' ),
				languageName = this.options.languages[ langCode ];

			return matcher.test( languageName ) ||
				matcher.test( $.uls.data.getAutonym( langCode ) ) ||
				matcher.test( langCode ) ||
				matcher.test( $.uls.data.getScript( langCode ) );
		}
	};

	$.fn.languagefilter = function ( option ) {
		return this.each( function () {
			var $this = $( this ),
				data = $this.data( 'languagefilter' ),
				options = typeof option === 'object' && option;

			if ( !data ) {
				$this.data( 'languagefilter', ( data = new LanguageFilter( this, options ) ) );
			}

			if ( typeof option === 'string' ) {
				data[ option ]();
			}
		} );
	};

	$.fn.languagefilter.defaults = {
		// LanguageCategoryDisplay
		lcd: undefined,
		// URL to which we append query parameter with the query value
		searchAPI: undefined,
		// What is this ULS used for.
		// Should be set for distinguishing between different instances of ULS
		// in the same application.
		ulsPurpose: '',
		// Object of language tags to language names
		languages: [],
		// Callback function when language is selected
		onSelect: undefined
	};

	$.fn.languagefilter.Constructor = LanguageFilter;

}( jQuery ) );
