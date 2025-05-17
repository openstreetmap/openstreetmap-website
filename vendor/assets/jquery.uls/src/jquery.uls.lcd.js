/**
 * Universal Language Selector
 * Language category display component - Used for showing the search results,
 * grouped by regions, scripts
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

	var noResultsTemplate = '<div class="uls-no-results-view"> \
		<h2 data-i18n="uls-no-results-found" class="uls-no-results-found-title">No results found</h2> \
		<div class="uls-no-results-suggestions"></div> \
		<div class="uls-no-found-more"> \
		<div data-i18n="uls-search-help">You can search by language name, script name, ISO code of language or you can browse by region.</div> \
		</div></div>';

	/**
	 * Language category display
	 *
	 * @param {Element} element The container element to which the languages to be displayed
	 * @param {Object} [options] Configuration object
	 * @cfg {Object} [languages] Selectable languages. Keyed by language code, values are autonyms.
	 * @cfg {string[]} [showRegions] Array of region codes to show. Default is
	 *  [ 'WW', 'AM', 'EU', 'ME', 'AF', 'AS', 'PA' ]
	 * @cfg {number} [itemsPerColumn] Number of languages per column.
	 * @cfg {number} [columns] Number of columns for languages. Default is 4.
	 * @cfg {Function} [languageDecorator] Callback function to be called when a language
	 *  link is prepared - for custom decoration.
	 * @cfg {Function|string[]} [quickList] The languages to display as suggestions for quick
	 *  selection.
	 * @cfg {Function} [clickhandler] Callback when language is selected.
	 * @cfg {jQuery|Function} [noResultsTemplate]
	 */
	function LanguageCategoryDisplay( element, options ) {
		this.$element = $( element );
		this.options = $.extend( {}, $.fn.lcd.defaults, options );
		// Ensure the internal region 'all' is always present
		if ( this.options.showRegions.indexOf( 'all' ) === -1 ) {
			this.options.showRegions.push( 'all' );
		}

		this.$element.addClass( 'uls-lcd' );
		this.regionLanguages = {};
		this.renderTimeout = null;
		this.$cachedQuicklist = null;
		this.groupByRegionOverride = null;

		this.render();
		this.listen();
	}

	LanguageCategoryDisplay.prototype = {
		constructor: LanguageCategoryDisplay,

		/**
		 * Adds language to the language list.
		 *
		 * @param {string} langCode
		 * @param {string} [regionCode]
		 * @return {boolean} Whether the language was known and accepted
		 */
		append: function ( langCode, regionCode ) {
			var i, regions;

			if ( !$.uls.data.languages[ langCode ] ) {
				// Language is unknown or not in the list of languages for this context.
				return false;
			}

			if ( !this.isGroupingByRegionEnabled() ) {
				regions = [ 'all' ];

				// Make sure we do not get duplicates
				if ( this.regionLanguages.all.indexOf( langCode ) > -1 ) {
					return true;
				}
			} else {
				if ( regionCode ) {
					regions = [ regionCode ];
				} else {
					regions = $.uls.data.getRegions( langCode );
				}
			}

			for ( i = 0; i < regions.length; i++ ) {
				if ( this.regionLanguages[ regions[ i ] ] ) {
					this.regionLanguages[ regions[ i ] ].push( langCode );
				}
			}

			// Work around the bad interface, delay rendering until we have got
			// all the languages to speed up performance.
			clearTimeout( this.renderTimeout );
			this.renderTimeout = setTimeout( function () {
				this.renderRegions();
			}.bind( this ), 50 );

			return true;
		},

		/**
		 * Whether we should render languages grouped to geographic regions.
		 *
		 * @return {boolean}
		 */
		isGroupingByRegionEnabled: function () {
			if ( this.groupByRegionOverride !== null ) {
				return this.groupByRegionOverride;
			} else if ( this.options.groupByRegion !== 'auto' ) {
				return this.options.groupByRegion;
			} else {
				return this.options.columns > 1;
			}
		},

		/**
		 * Override the default region grouping setting.
		 * This is to allow LanguageFilter to disable grouping when displaying search results.
		 *
		 * @param {boolean|null} val True to force grouping, false to disable, null
		 * to undo override.
		 */
		setGroupByRegionOverride: function ( val ) {
			this.groupByRegionOverride = val;
		},

		render: function () {
			var $section,
				$quicklist = this.buildQuicklist(),
				regions = [],
				regionNames = {
					// These are fallback text when i18n library not present
					all: 'All languages', // Used if there is quicklist and no region grouping
					WW: 'Worldwide',
					SP: 'Special',
					AM: 'America',
					EU: 'Europe',
					ME: 'Middle East',
					AS: 'Asia',
					AF: 'Africa',
					PA: 'Pacific'
				};

			if ( $quicklist.length ) {
				regions.push( $quicklist );
			} else {
				// We use CSS to hide the header for 'all' when quicklist is NOT present
				this.$element.addClass( 'uls-lcd--no-quicklist' );
			}

			this.options.showRegions.forEach( function ( regionCode ) {
				this.regionLanguages[ regionCode ] = [];

				$section = $( '<div>' )
					.addClass( 'uls-lcd-region-section hide' )
					.attr( 'data-region', regionCode );

				$( '<h3>' )
					.attr( 'data-i18n', 'uls-region-' + regionCode )
					.addClass( 'uls-lcd-region-title' )
					.text( regionNames[ regionCode ] )
					.appendTo( $section );

				regions.push( $section );
			}.bind( this ) );

			this.$element.append( regions );

			this.i18n();
		},

		/**
		 * Renders a region and displays it if it has content.
		 */
		renderRegions: function () {
			var languages,
				lcd = this;

			this.$element.removeClass( 'uls-no-results' );
			this.$element.children( '.uls-lcd-region-section' ).each( function () {
				var $region = $( this ),
					regionCode = $region.data( 'region' );

				if ( $region.is( '.uls-lcd-quicklist' ) ) {
					return;
				}

				$region.children( '.uls-language-block' ).remove();

				languages = lcd.regionLanguages[ regionCode ];
				if ( !languages || languages.length === 0 ) {
					$region.addClass( 'hide' );
					return;
				}

				lcd.renderRegion(
					$region,
					languages,
					lcd.options.itemsPerColumn,
					lcd.options.columns
				);
				$region.removeClass( 'hide' );

				lcd.regionLanguages[ regionCode ] = [];
			} );

		},

		/**
		 * Adds given languages sorted into rows and columns into given element.
		 *
		 * @param {jQuery} $region Element to add language list.
		 * @param {Array} languages List of language codes.
		 * @param {number} itemsPerColumn How many languages fit in a column.
		 * @param {number} columnsPerRow How many columns fit in a row.
		 */
		renderRegion: function ( $region, languages, itemsPerColumn, columnsPerRow ) {
			var columnsClasses, i, lastItem, currentScript, nextScript, force,
				languagesCount = languages.length,
				items = [],
				columns = [],
				rows = [];

			languages = $.uls.data.sortByScriptGroup(
				languages.sort( $.uls.data.sortByAutonym )
			);

			if ( columnsPerRow === 1 ) {
				columnsClasses = 'twelve columns';
			} else if ( columnsPerRow === 2 ) {
				columnsClasses = 'six columns';
			} else {
				columnsClasses = 'three columns';
			}

			if ( this.options.columns === 1 ) {
				// For one-column narrow ULS, just render all the languages
				// in one simple list without separators or script groups
				for ( i = 0; i < languagesCount; i++ ) {
					items.push( this.renderItem( languages[ i ] ) );
				}

				columns.push( $( '<ul>' ).addClass( columnsClasses ).append( items ) );
				rows.push( $( '<div>' ).addClass( 'row uls-language-block' ).append( columns ) );
			} else {
				// For medium and wide ULS, clever column placement
				for ( i = 0; i < languagesCount; i++ ) {
					force = false;
					nextScript = $.uls.data.getScriptGroupOfLanguage( languages[ i + 1 ] );

					lastItem = languagesCount - i === 1;
					// Force column break if script changes and column has more than one
					// row already, but only if grouping by region
					if ( i === 0 || !this.isGroupingByRegionEnabled() ) {
						currentScript = $.uls.data.getScriptGroupOfLanguage( languages[ i ] );
					} else if ( currentScript !== nextScript && items.length > 1 ) {
						force = true;
					}
					currentScript = nextScript;

					items.push( this.renderItem( languages[ i ] ) );

					if ( items.length >= itemsPerColumn || lastItem || force ) {
						columns.push( $( '<ul>' ).addClass( columnsClasses ).append( items ) );
						items = [];
						if ( columns.length >= columnsPerRow || lastItem ) {
							rows.push( $( '<div>' ).addClass( 'row uls-language-block' ).append( columns ) );
							columns = [];
						}
					}
				}
			}

			$region.append( rows );
		},

		/**
		 * Creates dom node representing one item in language list.
		 *
		 * @param {string} code Language code
		 * @return {Element}
		 */
		renderItem: function ( code ) {
			var a, name, autonym, li;

			name = this.options.languages[ code ];
			autonym = $.uls.data.getAutonym( code ) || name || code;

			// Not using jQuery as this is performance hotspot
			li = document.createElement( 'li' );
			li.title = name;
			li.setAttribute( 'data-code', code );

			a = document.createElement( 'a' );
			a.appendChild( document.createTextNode( autonym ) );
			a.className = 'autonym';
			a.lang = code;
			a.dir = $.uls.data.getDir( code );

			li.appendChild( a );
			if ( this.options.languageDecorator ) {
				this.options.languageDecorator( $( a ), code );
			}
			return li;
		},

		i18n: function () {
			this.$element.find( '[data-i18n]' ).i18n();
		},

		/**
		 * Adds quicklist as a region.
		 */
		quicklist: function () {
			this.$element.find( '.uls-lcd-quicklist' ).removeClass( 'hide' );
		},

		buildQuicklist: function () {
			var quickList, $quickListSection, $quickListSectionTitle;

			if ( this.$cachedQuicklist !== null ) {
				return this.$cachedQuicklist;
			}

			if ( typeof this.options.quickList === 'function' ) {
				this.options.quickList = this.options.quickList();
			}

			if ( !this.options.quickList.length ) {
				this.$cachedQuicklist = $( [] );
				return this.$cachedQuicklist;
			}

			// Pick only the first elements, because we don't have room for more
			quickList = this.options.quickList;
			quickList = quickList.slice( 0, 16 );
			quickList.sort( $.uls.data.sortByAutonym );

			$quickListSection = $( '<div>' )
				.addClass( 'uls-lcd-region-section uls-lcd-quicklist' );

			$quickListSectionTitle = $( '<h3>' )
				.attr( 'data-i18n', 'uls-common-languages' )
				.addClass( 'uls-lcd-region-title' )
				.text( 'Suggested languages' ); // This is placeholder text if jquery.i18n not present
			$quickListSection.append( $quickListSectionTitle );

			this.renderRegion(
				$quickListSection,
				quickList,
				this.options.itemsPerColumn,
				this.options.columns
			);

			$quickListSectionTitle.i18n();

			this.$cachedQuicklist = $quickListSection;
			return this.$cachedQuicklist;
		},

		show: function () {
			if ( !this.regionDivs ) {
				this.render();
			}
		},

		/**
		 * Called when a fresh search is started
		 */
		empty: function () {
			this.$element.addClass( 'uls-lcd--no-quicklist' );
			this.$element.find( '.uls-lcd-quicklist' ).addClass( 'hide' );
		},

		focus: function () {
			this.$element.trigger( 'focus' );
		},

		/**
		 * No-results event handler
		 *
		 * @param {Event} event
		 * @param {Object} data Information about the failed search query
		 */
		noResults: function ( event, data ) {
			var $noResults;

			this.$element.addClass( 'uls-no-results' );

			this.$element.find( '.uls-no-results-view' ).remove();

			if ( typeof this.options.noResultsTemplate === 'function' ) {
				$noResults =
					this.options.noResultsTemplate.call( this, data.query );
			} else if ( this.options.noResultsTemplate instanceof jQuery ) {
				$noResults = this.options.noResultsTemplate;
			} else {
				throw new Error( 'noResultsTemplate option must be ' +
					'either jQuery or function returning jQuery' );
			}

			this.$element.append( $noResults.addClass( 'uls-no-results-view' ).i18n() );
		},

		listen: function () {
			var lcd = this;

			if ( this.options.clickhandler ) {
				this.$element.on( 'click', '.row li', function ( event ) {
					lcd.options.clickhandler.call( this, $( this ).data( 'code' ), event );
				} );
			}
		}
	};

	$.fn.lcd = function ( option ) {
		return this.each( function () {
			var $this = $( this ),
				data = $this.data( 'lcd' ),
				options = typeof option === 'object' && option;

			if ( !data ) {
				$this.data( 'lcd', ( data = new LanguageCategoryDisplay( this, options ) ) );
			}

			if ( typeof option === 'string' ) {
				data[ option ]();
			}
		} );
	};

	$.fn.lcd.defaults = {
		// List of languages to show
		languages: [],
		// List of regions to show
		showRegions: [ 'WW', 'AM', 'EU', 'ME', 'AF', 'AS', 'PA' ],
		// Whether to group by region, defaults to true when columns > 1
		groupByRegion: 'auto',
		// How many items per column until new "row" starts
		itemsPerColumn: 8,
		// Number of columns, only 1, 2 and 4 are supported
		columns: 4,
		// Callback function for language item styling
		languageDecorator: undefined,
		// Likely candidates
		quickList: [],
		// Callback function for language selection
		clickhandler: undefined,
		// Callback function when no search results.
		// If overloaded, it can accept the search string as an argument.
		noResultsTemplate: function () {
			var $suggestionsContainer, $suggestions,
				$noResultsTemplate = $( noResultsTemplate );

			$suggestions = this.buildQuicklist().clone();
			$suggestions.removeClass( 'hide' )
				.find( 'h3' )
				.data( 'i18n', 'uls-no-results-suggestion-title' )
				.text( 'You may be interested in:' )
				.i18n();
			$suggestionsContainer = $noResultsTemplate.find( '.uls-no-results-suggestions' );
			$suggestionsContainer.append( $suggestions );
			return $noResultsTemplate;
		}
	};

}( jQuery ) );
