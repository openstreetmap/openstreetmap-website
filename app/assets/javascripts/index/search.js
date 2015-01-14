//= require jquery.simulate
//= require algoliaSearch

OSM.Search = function(map) {
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

  $("#sidebar_content")
    .on("click", ".search_more a", clickSearchMore)
    .on("click", ".search_results_entry a.set_position", clickSearchResult)
    .on("mouseover", "p.search_results_entry:has(a.set_position)", showSearchResult)
    .on("mouseout", "p.search_results_entry:has(a.set_position)", hideSearchResult)
    .on("mousedown", "p.search_results_entry:has(a.set_position)", function () {
      var moved = false;
      $(this).one("click", function (e) {
        if (!moved && !$(e.target).is('a')) {
          $(this).find("a.set_position").simulate("click", e);
        }
      }).one("mousemove", function () {
        moved = true;
      });
    });

  function clickSearchMore(e) {
    e.preventDefault();
    e.stopPropagation();

    var div = $(this).parents(".search_more");

    $(this).hide();
    div.find(".loader").show();

    $.get($(this).attr("href"), function(data) {
      div.replaceWith(data);
    });
  }

  function showSearchResult(e) {
    var marker = $(this).data("marker");

    if (!marker) {
      var data = $(this).find("a.set_position").data();

      marker = L.marker([data.lat, data.lon], {icon: getUserIcon()});

      $(this).data("marker", marker);
    }

    markers.addLayer(marker);

    $(this).closest("li").addClass("selected");
  }

  function hideSearchResult(e) {
    var marker = $(this).data("marker");

    if (marker) {
      markers.removeLayer(marker);
    }

    $(this).closest("li").removeClass("selected");
  }

  function clickSearchResult(e) {
    var data = $(this).data(),
      center = L.latLng(data.lat, data.lon);

    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      map.fitBounds([[data.minLat, data.minLon], [data.maxLat, data.maxLon]]);
    } else {
      map.setView(center, data.zoom);
    }

    // Let clicks to object browser links propagate.
    if (data.type && data.id) return;

    e.preventDefault();
    e.stopPropagation();
  }

  var markers = L.layerGroup().addTo(map);

  var page = {};

  page.pushstate = page.popstate = function(path) {
    var params = querystring.parse(path.substring(path.indexOf('?') + 1));
    $(".search_form input[name=query]").val(params.query);
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function() {
    $(".search_results_entry").each(function() {
      var entry = $(this);
      $.ajax({
        url: entry.data("href"),
        method: 'GET',
        data: {
          zoom: map.getZoom(),
          minlon: map.getBounds().getWest(),
          minlat: map.getBounds().getSouth(),
          maxlon: map.getBounds().getEast(),
          maxlat: map.getBounds().getNorth()
        },
        success: function(html) {
          entry.html(html);
        }
      });
    });

    return map.getState();
  };

  page.unload = function() {
    markers.clearLayers();
    $(".search_form input[name=query]").val("");
    $(".describe_location").fadeIn(100);
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

  var render  = function render( $out, $shadowInput, state ){
    var results = state.resultsList;
    var query   = state.userInputValue;

    if( results.length === 0) {
      $out.addClass( "hidden" );
      $shadowInput.val("");
    }
    else {
      $out.removeClass( "hidden" );
      var cityFound = results[0].city;
      if( cityFound.toLowerCase().indexOf( query.toLowerCase() ) === 0) $shadowInput.val( query[0] + cityFound.slice(1) );
      else $shadowInput.val("");
    }

    var citiesList = results.reduce( function( str, hit ) {
      return str + "<li class='city'>" + hit.city + "</li>";
    }, "");

    $out.html( citiesList );
  };
  var getOrCreateResultList = function getOrCreateResultList( $searchField ){
    var $resultList = $searchField.parent().find( ".algolia.results" );
    if( $resultList.length === 0 ){
      var $newResultList = $( "<ul class='algolia results'></ul>" );
      $searchField.parent().append( $newResultList );
      return $newResultList;
    }
    else {
      return $resultList;
    }
  };

  var specialKeys = [];
  specialKeys[27] = function handleEscape( $searchInput, state ){
    $searchInput.blur();
    var nextState = new AlgoliaIntegrationState( state );
    nextState.resultsList = [];
    return nextState;
  };
  specialKeys[40] = function handleDownArrow( $searchInput, state ){
    var nextState = new AlgoliaIntegrationState( state );

  };

  var AlgoliaIntegrationState = function AlgoliaIntegrationState( state ){
    state = state || { userInputValue: "", selectedItem: -1, resultsList: []};
    this.userInputValue = state.userInputValue || "";
    this.selectedResult = state.selectedItem === undefined ? -1 : state.selectedItem;
    this.resultsList    = state.resultsList || [];
  };

  var AlgoliaIntegration = function AlgoliaIntegration( searchInput, map ){
    this.$searchInput = $( searchInput );
    this.$shadowInput = this.$searchInput.siblings(".shadow-input");
    this.state        = new AlgoliaIntegrationState( {
      userInputValue : this.$searchInput.val()
    } );
  };
  AlgoliaIntegration.bind = function createAndBindAlgolia( searchInput, map ){
    var search = new AlgoliaIntegration( searchInput );
    var $searchInput = search.$searchInput;

    search.handleSearchSuccess.bind(search);
    search.handleSearchError.bind(search);

    $searchInput.on( "keyup",   search.keyupHandler.bind( search, map ) )
                .on( "keydown", search.keydownHandler.bind( search, map ) )
                .on( "blur",    search.blurHandler.bind( search, map ) )

    return search;
  };
  AlgoliaIntegration.prototype = {
    constructor : AlgoliaIntegration,
    keyupHandler: function( map, e ){
      var $searchInput = this.$searchInput;
      var $shadowInput = this.$shadowInput;
      var $output      = getOrCreateResultList( $searchInput );

      if( specialKeys[e.keyCode] !== undefined ){
        var specialKeyHandler = specialKeys[e.keyCode];
        this.state = specialKeyHandler( $searchInput, this.state );
        render( $output, $shadowInput, this.state );
      }
      else {
        var query = $searchInput.val();
        var self  = this;
        searchCity( query ).then( this.handleSearchSuccess,
                                  this.handleSearchError )
                           .then( function( state ) {
                             self.state = state;
                             render( $output, $shadowInput, state );
                           });
      }
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
    },
    keydownHandler: function( map, e ){
      var $shadowInput = this.$shadowInput;
      $shadowInput.val("");
    },
    blurHandler: function( map, e ){
      var $searchInput = this.$searchInput;
      var $output      = getOrCreateResultList( $searchInput );
      var $shadowInput = this.$shadowInput;
      $shadowInput.val("");
      $output.html("").addClass("hidden");
    }
  };
  return AlgoliaIntegration;
})();
