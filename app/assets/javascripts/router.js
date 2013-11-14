OSM.Router = function(map, rts) {
  var escapeRegExp  = /[\-{}\[\]+?.,\\\^$|#\s]/g;
  var optionalParam = /\((.*?)\)/g;
  var namedParam    = /(\(\?)?:\w+/g;
  var splatParam    = /\*\w+/g;

  function Route(path, controller) {
    var regexp = new RegExp('^' +
      path.replace(escapeRegExp, '\\$&')
        .replace(optionalParam, '(?:$1)?')
        .replace(namedParam, function(match, optional){
          return optional ? match : '([^\/]+)';
        })
        .replace(splatParam, '(.*?)') + '(?:\\?.*)?$');

    var route = {};

    route.match = function(path) {
      return regexp.test(path);
    };

    route.run = function(action, path) {
      var params = [];

      if (path) {
        params = regexp.exec(path).map(function(param, i) {
          return (i > 0 && param) ? decodeURIComponent(param) : param;
        });
      }

      (controller[action] || $.noop).apply(controller, params);
    };

    return route;
  }

  var routes = [];
  for (var r in rts)
    routes.push(Route(r, rts[r]));

  routes.recognize = function(path) {
    for (var i = 0; i < this.length; i++) {
      if (this[i].match(path)) return this[i];
    }
  };

  var currentPath = window.location.pathname + window.location.search,
    currentRoute = routes.recognize(currentPath),
    currentHash = location.hash || OSM.formatHash(map);

  currentRoute.run('load', currentPath);

  var stateChange;

  map.on('moveend baselayerchange overlaylayerchange', function() {
    var hash = OSM.formatHash(map);
    if (hash === currentHash) return;
    currentHash = hash;
    stateChange(OSM.parseHash(hash), hash);
  });

  $(window).on('hashchange', function() {
    var hash = location.hash;
    if (hash === currentHash) return;
    currentHash = hash;
    var state = OSM.parseHash(hash);
    if (!state) return;
    map.setView(state.center, state.zoom);
    map.updateLayers(state.layers);
    stateChange(state, hash);
  });

  if (window.history && window.history.pushState) {
    stateChange = function(state, hash) {
      window.history.replaceState(state, document.title, hash);
    };

    // Set a non-null initial state, so that the e.originalEvent.state
    // check below works correctly when going back to the initial page.
    stateChange(OSM.parseHash(currentHash), currentPath + currentHash);

    $(window).on('popstate', function(e) {
      if (!e.originalEvent.state) return; // Is it a real popstate event or just a hash change?
      var path = window.location.pathname + window.location.search;
      if (path === currentPath) return;
      currentRoute.run('unload');
      currentPath = path;
      currentRoute = routes.recognize(currentPath);
      currentRoute.run('popstate', currentPath);
      var state = e.originalEvent.state;
      if (state.center) {
        map.setView(state.center, state.zoom, {animate: false});
        map.updateLayers(state.layers);
      }
    });

    return function (url) {
      var path = url.replace(/#.*/, ''),
        route = routes.recognize(path);
      if (!route) return false;
      window.history.pushState(OSM.parseHash(url) || {}, document.title, url);
      currentRoute.run('unload');
      currentPath = path;
      currentRoute = route;
      currentRoute.run('pushstate', currentPath);
      return true;
    }
  } else {
    stateChange = function(state, hash) {
      window.location.replace(hash);
    };

    return function (url) {
      window.location.assign(url);
    }
  }
};
