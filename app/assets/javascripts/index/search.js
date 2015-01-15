//= require jquery.simulate
//= require algoliaSearch

OSM.Search = function(map) {
  map.zoomAnimationThreshold = 20;

  $(".search_form input[name=query]")
    .each( function( i, searchInput ){
      OSM.AlgoliaIntegration.bind( searchInput, map );
    } )
    .on("input", function(e) {
      if ($(e.target).val() == "") {
        $(".describe_location").fadeIn(100);
      } else {
        $(".describe_location").fadeOut(100);
      }
    })


  var page = {};

  page.pushstate = page.popstate = function(path) {
    var params = querystring.parse(path.substring(path.indexOf('?') + 1));
    $(".search_form input[name=query]").val(params.query);
    //OSM.loadSidebarContent(path, page.load);
  };

  page.load = function() {
    return map.getState();
  };

  page.unload = function() {
    //markers.clearLayers();
    //$(".search_form input[name=query]").val("");
    //$(".describe_location").fadeIn(100);
  };

  return page;
};

OSM.AlgoliaIntegration = (function sudoMakeMagic(){
  var searchCity = (function initAlgolia(){
    var client = new AlgoliaSearch("XS2XU0OW47", "ef286aa43862d8b04cc8030e499f4813"); // public credentials
    var index  = client.initIndex('worldCities');

    return function searchCity( query ){
      if( query === "" ) return $.Deferred().resolve( {hits: []} ).promise();
      var d = $.Deferred();
      index.search( query, function resolveIntoPromise( success, content ){
        if(success) d.resolve( content );
        else d.reject();
      } );
      return d.promise();
    };
  })();

  var render  = function render( component, nextState ){
    render.do( component, nextState );
  };
  render.do = function( component, nextState ){
    var $out         = component.$resultsList;
    var $searchInput = component.$searchInput;
    var $shadowInput = component.$shadowInput;
    var previousState= component.state;
    var results      = nextState.resultsList;
    var query        = nextState.userInputValue;

    this.fixMenuPosition( component );

    if( results.length < 1 ) {
      $out.addClass( "hidden" );
      $shadowInput.val("");
    }
    else {
      $out.removeClass( "hidden" );
      var cityFound = results[0].city;
      if( cityFound.toLowerCase().indexOf( query.toLowerCase() ) === 0 &&
          nextState.selectedResult === -1) $shadowInput.val( query[0] + cityFound.slice(1) );
      else $shadowInput.val("");
    }

    //User input change
    if( previousState.resultsList !== nextState.resultsList ) {
      if(nextState.resultsList.length > 0){
        if(nextState.resultsList.length > 1) {
          var head = results[0];
          var initBounds = [ [ head._geoloc.lat, head._geoloc.lng ], [ head._geoloc.lat, head._geoloc.lng ] ];
          var bounds = results.reduce( function( current, result ){
            var geo = result._geoloc;
            if( geo.lat < current[0][0] ) current[0][0] = geo.lat;
            if( geo.lng < current[0][1] ) current[0][1] = geo.lng;
            if( geo.lat > current[1][0] ) current[1][0] = geo.lat;
            if( geo.lng > current[1][1] ) current[1][1] = geo.lng;
            return current;
          }, initBounds);
          component.map.fitBounds( bounds );
        }
        var citiesList = results.map( function( hit, i ) {
          return "<li class='city'>" + hit._highlightResult.city.value + ", " + hit.country + "</li>";
        }).join("");
        $out.html( citiesList );
        component.markersLayout.clearLayers()
        results.forEach( function( hit, i ){
          var marker = L.marker([hit._geoloc.lat, hit._geoloc.lng], {icon: getUserIcon( "/assets/marker-grey.png" )});
          component.markersLayout.addLayer(marker);
        });
      }
      else{
        $out.html( "" );
        component.markersLayout.clearLayers()
      }
    }
    //User navigation in the search results
    else {
      if( previousState.selectedResult !== nextState.selectedResult) {
        var nextSelect     = nextState.selectedResult;
        var previousSelect = previousState.selectedResult;
        var nextCity       = nextState.resultsList[ nextState.selectedResult ];

        //Changing selection
        if( previousSelect !== -1 && nextSelect !== -1 ){
          $shadowInput.val( "" );
          $searchInput.val( nextCity.city + ", " + nextCity.country );
          this.unselectMarker(   component, previousState.selectedResult );
          this.unselectMenuItem( component, previousState.selectedResult );
          this.selectMarker(     component, nextState.selectedResult );
          this.selectMenuItem(   component, nextState.selectedResult )
        }
        //Starting selection
        else if( previousSelect === -1 && nextSelect !== -1 ){
          $shadowInput.val( "" );
          $searchInput.val( nextCity.city + ", " + nextCity.country );
          this.selectMarker(     component, nextState.selectedResult );
          this.selectMenuItem(   component, nextState.selectedResult )
        }
        //Ending selection
        else if( previousSelect !== -1 && nextSelect === -1 ){
          $searchInput.val( nextState.userInputValue );
          this.unselectMarker(   component, previousState.selectedResult );
          this.unselectMenuItem( component, previousState.selectedResult );
        }
      }
    }
  };
  render.fixMenuPosition = function fixMenuPosition( component ){
    var searchInputPosition = component.$searchInput.offset();
    var $resultsList = component.$resultsList.css( {
      top   : searchInputPosition.top + component.$searchInput.height() + 10,
      left  : searchInputPosition.left
    } );
  };
  render.unselectMarker = function unselectMarker( component, idx ){
    var marker = component.markersLayout.getLayers()[ idx ];
    marker.setIcon(getUserIcon( "/assets/marker-grey.png" ))
    .setZIndexOffset( 0 );
  };
  render.selectMarker = function selectMarker( component, idx ){
    var marker = component.markersLayout.getLayers()[ idx ];
    marker.setIcon(getUserIcon( "/assets/marker-red.png" ))
    .setZIndexOffset( 1000 );
  };
  render.unselectMenuItem = function unselectMenuItem( component, idx ){
    var menuItem = component.$resultsList.children().eq( idx );
    menuItem.removeClass( "selected" );
  };
  render.selectMenuItem = function selectMenuItem( component, idx ){
    var menuItem = component.$resultsList.children().eq( idx );
    menuItem.addClass( "selected" );
  };

  var specialKeys = [];
  specialKeys[27] = function handleEscape( $searchInput, state ){
    $searchInput.blur();
    var nextState = new AlgoliaIntegrationState( state );
    nextState.resultsList = [];
    $searchInput.val( state.userInputValue );
    return nextState;
  };
  specialKeys[40] = function handleDownArrow( $searchInput, state ){
    var nextState = new AlgoliaIntegrationState( state );
    selectedResult = state.selectedResult + 1;
    if( selectedResult === state.resultsList.length )
      nextState.selectedResult = -1;
    else nextState.selectedResult = selectedResult;
    return nextState;
  };
  specialKeys[38] = function handleUpArrow( $searchInput, state ){
    var nextState = new AlgoliaIntegrationState( state );
    selectedResult = state.selectedResult - 1;
    if( selectedResult < -1 )
      nextState.selectedResult = state.resultsList.length -1;
    else nextState.selectedResult = selectedResult;
    return nextState;
  };
  //Left and right arrow shall not trigger anything
  specialKeys[37] = specialKeys[39] = function noop( $in, state ){ return state;}
  specialKeys[13] = function handleReturn( $searchInput, state, map ){
    if( state.selectedResult === -1 ){ 
      if( state.resultsList.length === 0 ) return state;
      else {
        var currentCity = state.resultsList[ 0 ];
        var nextState = new AlgoliaIntegrationState( state );
        nextState.selectedResult = 0;
        $searchInput.val( currentCity.city + ", " + currentCity.country );
        return nextState;
      }
    }
    else {
      var currentCity = state.resultsList[ state.selectedResult ];
      var center = L.latLng( currentCity._geoloc.lat, currentCity._geoloc.lng );
      map.setView( center, 12, {animate: true}); // 12 seems like an ok value for cities

      var nextState = new AlgoliaIntegrationState( state );
      nextState.userInputValue = currentCity.city + ", " + currentCity.country;
      $searchInput.val( currentCity.city + ", " + currentCity.country );
      setTimeout( function(){ $searchInput.blur() }, 0);
      return nextState;
    }
  };

  var AlgoliaIntegrationState = function AlgoliaIntegrationState( state ){
    state = state || { userInputValue: "", selectedResult: -1, resultsList: []};
    this.userInputValue = state.userInputValue || "";
    this.selectedResult = state.selectedResult === undefined ? -1 : state.selectedResult;
    this.resultsList    = state.resultsList || [];
  };

  var AlgoliaIntegration = function AlgoliaIntegration( searchInput, map ){
    this.map          = map;
    this.$searchInput = $( searchInput );
    this.$shadowInput = this.$searchInput.siblings( ".shadow-input" );

    var $content = $("#content");
    var $resultsList  = $( "<ul class='algolia results hidden'></ul>" );
    $content.append( $resultsList );
    this.$resultsList = $resultsList;

    this.state        = new AlgoliaIntegrationState( {
      userInputValue : this.$searchInput.val()
    } );

    this.markersLayout = L.layerGroup().addTo(map);
  };
  AlgoliaIntegration.bind = function createAndBindAlgolia( searchInput, map ){
    var search       = new AlgoliaIntegration( searchInput, map );
    var $searchInput = search.$searchInput;
    var $resultsList = search.$resultsList;

    search.handleSearchSuccess.bind(search);
    search.handleSearchError.bind(search);

    $searchInput.on( "keyup",   search.keyupHandler.bind(   search ) )
                .on( "keydown", search.keydownHandler.bind( search ) )
                .on( "blur",    search.blurHandler.bind(    search ) )
                .on( "focus",   search.focusHandler.bind(   search ) );

    $resultsList.mouseover(  search.hoverHandler.bind( search ) )
                .mouseleave( search.leaveHandler.bind( search ) )
                .mousedown(  search.clickHandler.bind( search ) );

    return search;
  };
  AlgoliaIntegration.prototype = {
    constructor : AlgoliaIntegration,
    keyupHandler: function( e ){
      if( specialKeys[e.keyCode] !== undefined ){
        var specialKeyHandler = specialKeys[e.keyCode];
        var nextState = specialKeyHandler( this.$searchInput, this.state, this.map);
        render( this, nextState );
        this.state = nextState;

      }
      else {
        var query = this.$searchInput.val();
        var self  = this;
        searchCity( query ).then( this.handleSearchSuccess,
                                  this.handleSearchError )
                           .then( function renderAndUpdateState( nextState ) {
                             render( self, nextState );
                             self.state = nextState;
                           });
      }
    },
    keydownHandler: function( e ){
      if( specialKeys[e.keyCode] ) return;
      this.$shadowInput.val("");
    },
    blurHandler: function( e ){
      var nextState = new AlgoliaIntegrationState( this.state );
      nextState.resultsList = [];
      nextState.selectedResult = -1;
      render( this, nextState );
      this.state = nextState;
    },
    focusHandler: function( e ) {
      var query = this.$searchInput.val();
      if( query === "" ) return ;

      var self  = this;
      searchCity( query ).then( this.handleSearchSuccess,
                                this.handleSearchError )
                         .then( function renderAndUpdateState( nextState ) {
                           render( self, nextState );
                           self.state = nextState;
                         });
    },
    hoverHandler: function( e ) {
      var selectedElement = e.target;
      var position = Array.prototype.indexOf.call( this.$resultsList.children(), selectedElement );

      var nextState = new AlgoliaIntegrationState( this.state );
      nextState.selectedResult = position;
      render( this, nextState );
      this.state = nextState;
    },
    leaveHandler: function( e ){
      var nextState = new AlgoliaIntegrationState( this.state );
      nextState.selectedResult = -1;
      render( this, nextState );
      this.state = nextState;
    },
    clickHandler: function( e ){
      var selectedElement = e.target;
      var position = Array.prototype.indexOf.call( this.$resultsList.children(), selectedElement );

      var nextState = new AlgoliaIntegrationState( this.state );
      nextState.selectedResult = position;
      nextState = specialKeys[13]( this.$searchInput, nextState, this.map );
      render( this, nextState );
      this.state = nextState;
    },
    handleSearchSuccess : function( results ){
      var nextState = new AlgoliaIntegrationState( this.state );
      nextState.userInputValue = results.query;
      nextState.resultsList = results.hits;
      return nextState;
    },
    handleSearchError   : function(){
      var nextState = new AlgoliaIntegrationState( this.state );
      nextState.resultsList = [];
      return nextState;
    }
  };
  return AlgoliaIntegration;
})();
