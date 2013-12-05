/*
  OSM.Router implements pushState-based navigation for the main page and
  other pages that use a sidebar+map based layout (export, search results,
  history, and browse pages).

  For browsers without pushState, it falls back to full page loads, which all
  of the above pages support.

  The router is initialized with a set of routes: a mapping of URL path templates
  to route controller objects. Path templates can contain placeholders
  (`/note/:id`) and optional segments (`/:type/:id(/history)`).

  Route controller objects can define four methods that are called at defined
  times during routing:

     * The `load` method is called by the router when a path which matches the
       route's path template is loaded via a normal full page load. It is passed
       as arguments the URL path plus any matching arguments for placeholders
       in the path template.

     * The `pushstate` method is called when a page which matches the route's path
       template is loaded via pushState. It is passed the same arguments as `load`.

     * The `popstate` method is called when returning to a previously
       pushState-loaded page via popstate (i.e. browser back/forward buttons).

     * The `unload` method is called on the exiting route controller when navigating
       via pushState or popstate to another route.

   Note that while `load` is not called by the router for pushState-based loads,
   it's frequently useful for route controllers to call it manually inside their
   definition of the `pushstate` and `popstate` methods.

   An instance of OSM.Router is assigned to `OSM.router`. To navigate to a new page
   via pushState (with automatic full-page load fallback), call `OSM.router.route`:

       OSM.router.route('/way/1234');

   If `route` is passed a path that matches one of the path templates, it performs
   the appropriate actions and returns true. Otherwise it returns false.

   OSM.Router also handles updating the hash portion of the URL containing transient
   map state such as the position and zoom level. Some route controllers may wish to
   temporarily suppress updating the hash (for example, to omit the hash on pages
   such as `/way/1234` unless the map is moved). This can be done by calling
   `OSM.router.moveListenerOff` and `OSM.router.moveListenerOn`.
 */
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

      return (controller[action] || $.noop).apply(controller, params);
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

  var currentPath = window.location.pathname.replace(/(.)\/$/, '$1') + window.location.search,
    currentRoute = routes.recognize(currentPath),
    currentHash = location.hash || OSM.formatHash(map);

  var router = {};

  if (window.history && window.history.pushState) {
    $(window).on('popstate', function(e) {
      if (!e.originalEvent.state) return; // Is it a real popstate event or just a hash change?
      var path = window.location.pathname + window.location.search;
      if (path === currentPath) return;
      currentRoute.run('unload');
      currentPath = path;
      currentRoute = routes.recognize(currentPath);
      currentRoute.run('popstate', currentPath);
      map.setState(e.originalEvent.state, {animate: false});
    });

    router.route = function (url) {
      var path = url.replace(/#.*/, ''),
        route = routes.recognize(path);
      if (!route) return false;
      window.history.pushState(OSM.parseHash(url), document.title, url);
      currentRoute.run('unload');
      currentPath = path;
      currentRoute = route;
      currentRoute.run('pushstate', currentPath);
      return true;
    };

    router.stateChange = function(state) {
      if (state.center) {
        window.history.replaceState(state, document.title, OSM.formatHash(state));
      } else {
        window.history.replaceState(state, document.title, window.location);
      }
    };
  } else {
    router.route = function (url) {
      window.location.assign(url);
    };

    router.stateChange = function(state) {
      if (state.center) window.location.replace(OSM.formatHash(state));
    };
  }

  router.updateHash = function() {
    var hash = OSM.formatHash(map);
    if (hash === currentHash) return;
    currentHash = hash;
    router.stateChange(OSM.parseHash(hash));
  };

  router.hashUpdated = function() {
    var hash = location.hash;
    if (hash === currentHash) return;
    currentHash = hash;
    var state = OSM.parseHash(hash);
    map.setState(state);
    router.stateChange(state, hash);
  };

  router.moveListenerOn = function() {
    map.on('moveend', router.updateHash);
  };

  router.moveListenerOff = function() {
    map.off('moveend', router.updateHash);
  };

  router.load = function() {
    var loadState = currentRoute.run('load', currentPath);
    router.stateChange(loadState || {});
  };

  router.setCurrentPath = function (path) {
    currentPath = path;
    currentRoute = routes.recognize(currentPath);
  };

  map.on('moveend baselayerchange overlaylayerchange', router.updateHash);
  $(window).on('hashchange', router.hashUpdated);

  return router;
};
