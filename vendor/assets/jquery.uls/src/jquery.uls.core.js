/**
 * Universal Language Selector
 * ULS core component.
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

	var template, ULS;

	// Region numbers in id attributes also appear in the langdb.
	template = '<div class="grid uls-menu"> \
			<div id="search" class="row uls-search"> \
				<div class="uls-search-wrapper"> \
					<label class="uls-search-label" for="uls-languagefilter"></label>\
					<div class="uls-search-input-wrapper">\
						<span class="uls-languagefilter-clear"></span>\
						<input type="text" class="uls-filterinput uls-filtersuggestion"\
							disabled="true" autocomplete="off">\
						<input type="text" class="uls-filterinput uls-languagefilter"\
							maxlength="40"\
							data-clear="uls-languagefilter-clear"\
							data-suggestion="uls-filtersuggestion"\
							placeholder="Search for a language" autocomplete="off">\
					</div>\
				</div>\
			</div>\
			<div class="row uls-language-list"></div>\
			<div class="row" id="uls-settings-block"></div>\
		</div>';

	/**
	 * ULS Public class definition
	 *
	 * @param {Element} element
	 * @param {Object} options
	 */
	ULS = function ( element, options ) {
		var code;
		this.$element = $( element );
		this.options = $.extend( {}, $.fn.uls.defaults, options );
		this.$menu = $( template );
		this.languages = this.options.languages;

		for ( code in this.languages ) {
			if ( $.uls.data.languages[ code ] === undefined ) {
				// Language is unknown to ULS.
				delete this.languages[ code ];
			}
		}

		this.left = this.options.left;
		this.top = this.options.top;
		this.shown = false;
		this.initialized = false;
		this.shouldRecreate = false;
		this.menuWidth = this.getMenuWidth();

		this.$languageFilter = this.$menu.find( '.uls-languagefilter' );
		this.$resultsView = this.$menu.find( '.uls-language-list' );

		this.render();
		this.listen();
		this.ready();
	};

	ULS.prototype = {
		constructor: ULS,

		/**
		 * A "hook" that runs after the ULS constructor.
		 * At this point it is not guaranteed that the ULS has its dimensions
		 * and that the languages lists are initialized.
		 *
		 * To use it, pass a function as the onReady parameter
		 * in the options when initializing ULS.
		 */
		ready: function () {
			if ( this.options.onReady ) {
				this.options.onReady.call( this );
			}
		},

		/**
		 * A "hook" that runs after the ULS panel becomes visible
		 * by using the show method.
		 *
		 * To use it, pass a function as the onVisible parameter
		 * in the options when initializing ULS.
		 */
		visible: function () {
			if ( this.options.onVisible ) {
				this.options.onVisible.call( this );
			}
		},

		/**
		 * Calculate the position of ULS
		 * Returns an object with top and left properties.
		 *
		 * @return {Object}
		 */
		position: function () {
			var pos,
				top = this.top,
				left = this.left;

			if ( this.options.onPosition ) {
				return this.options.onPosition.call( this );
			}

			// Default implementation (middle of the screen under the trigger)
			if ( top === undefined ) {
				pos = $.extend( {}, this.$element.offset(), {
					height: this.$element[ 0 ].offsetHeight
				} );
				top = pos.top + pos.height;
			}

			if ( left === undefined ) {
				left = $( window ).width() / 2 - this.$menu.outerWidth() / 2;
			}

			return {
				top: top,
				left: left
			};
		},

		/**
		 * Show the ULS window
		 */
		show: function () {
			var widthClasses = {
				wide: 'uls-wide',
				medium: 'uls-medium',
				narrow: 'uls-narrow'
			};

			this.$menu.addClass( widthClasses[ this.menuWidth ] );

			if ( !this.initialized ) {
				$( document.body ).prepend( this.$menu );
				this.i18n();
				this.initialized = true;
			}

			this.$menu.css( this.position() );
			this.$menu.show();
			this.$menu.scrollIntoView();
			this.shown = true;

			if ( !this.isMobile() ) {
				this.$languageFilter.trigger( 'focus' );
			}

			this.visible();
		},

		i18n: function () {
			if ( $.i18n ) {
				this.$menu.find( '[data-i18n]' ).i18n();
				this.$languageFilter.prop( 'placeholder', $.i18n( 'uls-search-placeholder' ) );
			}
		},

		/**
		 * Hide the ULS window
		 */
		hide: function () {
			this.$menu.hide();
			this.shown = false;

			this.$menu.removeClass( 'uls-wide uls-medium uls-narrow' );

			if ( this.shouldRecreate ) {
				this.recreateLanguageFilter();
			}

			if ( this.options.onCancel ) {
				this.options.onCancel.call( this );
			}
		},

		/**
		 * Render the UI elements.
		 * Does nothing by default. Can be used for customization.
		 */
		render: function () {
			// Rendering stuff here
		},

		/**
		 * Callback for results found context.
		 */
		success: function () {
			this.$resultsView.show();
		},

		createLanguageFilter: function () {
			var lcd, languagesCount,
				columnsOptions = {
					wide: 4,
					medium: 2,
					narrow: 1
				};

			languagesCount = Object.keys( this.options.languages ).length;
			lcd = this.$resultsView.lcd( {
				languages: this.languages,
				columns: columnsOptions[ this.menuWidth ],

				quickList: languagesCount > 12 ? this.options.quickList : [],
				clickhandler: this.select.bind( this ),
				showRegions: this.options.showRegions,
				languageDecorator: this.options.languageDecorator,
				noResultsTemplate: this.options.noResultsTemplate,
				itemsPerColumn: this.options.itemsPerColumn,
				groupByRegion: this.options.groupByRegion
			} ).data( 'lcd' );

			this.$languageFilter.languagefilter( {
				lcd: lcd,
				languages: this.languages,
				ulsPurpose: this.options.ulsPurpose,
				searchAPI: this.options.searchAPI,
				onSelect: this.select.bind( this )
			} );

			this.$languageFilter.on( 'noresults.uls', lcd.noResults.bind( lcd ) );
		},

		recreateLanguageFilter: function () {
			this.$resultsView.removeData( 'lcd' );
			this.$resultsView.empty();
			this.$languageFilter.removeData( 'languagefilter' );
			this.createLanguageFilter();

			this.shouldRecreate = false;
		},

		/**
		 * Bind the UI elements with their event listeners
		 */
		listen: function () {
			// Register all event listeners to the ULS here.
			this.$element.on( 'click', this.click.bind( this ) );

			// Don't do anything if pressing on empty space in the ULS
			this.$menu.on( 'click', function ( e ) {
				e.stopPropagation();
			} );

			// Handle key press events on the menu
			this.$menu.on( 'keydown', this.keypress.bind( this ) );

			this.createLanguageFilter();

			this.$languageFilter.on( 'resultsfound.uls', this.success.bind( this ) );

			$( document.body ).on( 'click', this.cancel.bind( this ) );
			$( window ).on( 'resize', $.fn.uls.debounce( this.resize.bind( this ), 250 ) );
		},

		resize: function () {
			var menuWidth = this.getMenuWidth();

			if ( this.menuWidth === menuWidth ) {
				return;
			}

			this.menuWidth = menuWidth;
			this.shouldRecreate = true;
			if ( !this.shown ) {
				this.recreateLanguageFilter();
			}
		},

		/**
		 * On select handler for search results
		 *
		 * @param {string} langCode
		 * @param {Object} event The jQuery click event
		 */
		select: function ( langCode, event ) {
			this.hide();
			if ( this.options.onSelect ) {
				this.options.onSelect.call( this, langCode, event );
			}
		},

		/**
		 * On cancel handler for the uls menu
		 *
		 * @param {Event} e
		 */
		cancel: function ( e ) {
			if ( e && ( this.$element.is( e.target ) ||
				$.contains( this.$element[ 0 ], e.target ) ) ) {
				return;
			}

			this.hide();
		},

		keypress: function ( e ) {
			if ( !this.shown ) {
				return;
			}

			if ( e.keyCode === 27 ) { // escape
				this.cancel();
				e.preventDefault();
				e.stopPropagation();
			}
		},

		click: function () {
			if ( this.shown ) {
				this.hide();
			} else {
				this.show();
			}
		},

		/**
		 * Get the panel menu width parameter
		 *
		 * @return {string}
		 */
		getMenuWidth: function () {
			var languagesCount,
				screenWidth = document.documentElement.clientWidth;

			if ( this.options.menuWidth ) {
				return this.options.menuWidth;
			}

			languagesCount = Object.keys( this.options.languages ).length;

			if ( screenWidth > 900 && languagesCount >= 48 ) {
				return 'wide';
			}

			if ( screenWidth > 500 && languagesCount >= 24 ) {
				return 'medium';
			}

			return 'narrow';
		},

		isMobile: function () {
			return navigator.userAgent.match( /(iPhone|iPod|iPad|Android|BlackBerry)/ );
		}
	};

	/* ULS PLUGIN DEFINITION
	 * =========================== */

	$.fn.uls = function ( option ) {
		return this.each( function () {
			var $this = $( this ),
				data = $this.data( 'uls' ),
				options = typeof option === 'object' && option;

			if ( !data ) {
				$this.data( 'uls', ( data = new ULS( this, options ) ) );
			}

			if ( typeof option === 'string' ) {
				data[ option ]();
			}
		} );
	};

	$.fn.uls.defaults = {
		// DEPRECATED: CSS top position for the dialog
		top: undefined,
		// DEPRECATED: CSS left position for the dialog
		left: undefined,
		// Callback function when user selects a language
		onSelect: undefined,
		// Callback function when the dialog is closed without selecting a language
		onCancel: undefined,
		// Callback function when ULS has initialized
		onReady: undefined,
		// Callback function when ULS dialog is shown
		onVisible: undefined,
		// Callback function when ULS dialog is ready to be shown
		onPosition: undefined,
		// Languages to be used for ULS, default is all languages
		languages: $.uls.data.getAutonyms(),
		// The options are wide (4 columns), medium (2 columns), and narrow (1 column).
		// If not specified, it will be set automatically.
		menuWidth: undefined,
		// What is this ULS used for.
		// Should be set for distinguishing between different instances of ULS
		// in the same application.
		ulsPurpose: '',
		// Used by LCD
		quickList: [],
		// Used by LCD
		showRegions: undefined,
		// Used by LCD
		languageDecorator: undefined,
		// Used by LCD
		noResultsTemplate: undefined,
		// Used by LCD
		itemsPerColumn: undefined,
		// Used by LCD
		groupByRegion: undefined,
		// Used by LanguageFilter
		searchAPI: undefined
	};

	// Define a dummy i18n function, if jquery.i18n not integrated.
	if ( !$.fn.i18n ) {
		$.fn.i18n = function () {};
	}

	/**
	 * Creates and returns a new debounced version of the passed function,
	 * which will postpone its execution, until after wait milliseconds have elapsed
	 * since the last time it was invoked.
	 *
	 * @param {Function} fn Function to be debounced.
	 * @param {number} wait Wait interval in milliseconds.
	 * @param {boolean} [immediate] Trigger the function on the leading edge of the wait interval,
	 * instead of the trailing edge.
	 * @return {Function} Debounced function.
	 */
	$.fn.uls.debounce = function ( fn, wait, immediate ) {
		var timeout;

		return function () {
			var callNow, self = this,
				later = function () {
					timeout = null;
					if ( !immediate ) {
						fn.apply( self, arguments );
					}
				};

			callNow = immediate && !timeout;
			clearTimeout( timeout );
			timeout = setTimeout( later, wait || 100 );

			if ( callNow ) {
				fn.apply( self, arguments );
			}
		};
	};

	/*
	 * Simple scrollIntoView plugin.
	 * Scrolls the element to the viewport smoothly if it is not already.
	 */
	$.fn.scrollIntoView = function () {
		return this.each( function () {
			var scrollPosition,
				$window = $( window ),
				windowHeight = $window.height(),
				windowTop = $window.scrollTop(),
				windowBottom = windowTop + windowHeight,
				$element = $( this ),
				panelHeight = $element.height(),
				panelTop = $element.offset().top,
				panelBottom = panelTop + panelHeight;

			if ( ( panelTop < windowTop ) || ( panelBottom > windowBottom ) ) {
				if ( windowTop > panelTop ) {
					scrollPosition = panelTop;
				} else {
					scrollPosition = panelBottom - windowHeight;
				}
				// eslint-disable-next-line no-jquery/no-global-selector
				$( 'html, body' ).stop().animate( {
					scrollTop: scrollPosition
				}, 500 );
			}
		} );
	};

	$.fn.uls.Constructor = ULS;
}( jQuery ) );
