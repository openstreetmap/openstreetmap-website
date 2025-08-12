/*
  OSM.Router implements pushState-based navigation for the main page and
  other pages that use a sidebar+map based layout (export, search results,
  history, and browse pages).

  For browsers without pushState, it falls back to full page loads, which all
  of the above pages support.

  The router is initialized with a set of routes: a mapping of URL path templates
  to route controller objects. Path templates can contain
    placeholders (`/note/:id`),
    scoped placeholders (`/type:node way relation/:id`) and
    optional segments (`/:type/:id(/history)`).

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
   such as `/way/1234` unless the map is moved). This can be done by using
   `OSM.router.withoutMoveListener` to run a block of code that may update
   move the map without the hash changing.
 */
OSM.Router = function (map, rts) {
  const escapeRegExp = /[-{}[\]+?.,\\^$|#\s]/g;
  const optionalParam = /\((.*?)\)/g;
  const enumParam = /\w+:([^/]+)/g;
  const namedParam = /(\(\?)?:\w+/g;
  const splatParam = /\*\w+/g;

  function Route(path, controller) {
    const regexp = new RegExp(
      "^" +
      path
        .replace(escapeRegExp, "\\$&")
        .replace(optionalParam, "(?:$1)?")
        .replace(enumParam, (match, options) => "(" + options.replaceAll("\\ ", "|") + ")")
        .replace(namedParam, (match, optional) => optional ? match : "([^/]+)")
        .replace(splatParam, "(.*?)") +
      "(?:\\?.*)?$"
    );

    const route = {};

    route.match = function (path) {
      return regexp.test(path);
    };

    route.run = function (action, path, ...args) {
      let params = [];

      if (path) {
        params = regexp.exec(path).map(function (param, i) {
          return (i > 0 && param) ? decodeURIComponent(param) : param;
        });
      }

      return controller[action]?.(...params, ...args);
    };

    return route;
  }

  const routes = Object.entries(rts)
    .map(([path, controller]) => new Route(path, controller(map)));

  routes.recognize = function (path) {
    for (const route of this) {
      if (route.match(path)) return route;
    }
  };

  let currentPath = location.pathname.replace(/(.)\/$/, "$1") + location.search,
      currentRoute = routes.recognize(currentPath),
      currentHash = location.hash || OSM.formatHash(map);

  const router = {};

  function updateSecondaryNav() {
    $("header nav.secondary > ul > li > a").each(function () {
      const active = $(this).attr("href") === location.pathname;

      $(this)
        .toggleClass("text-secondary", !active)
        .toggleClass("text-secondary-emphasis", active);
    });
  }

  $(window).on("popstate", function (e) {
    if (!e.originalEvent.state) return; // Is it a real popstate event or just a hash change?
    const path = location.pathname + location.search,
          route = routes.recognize(path);
    if (path === currentPath) return;
    currentRoute.run("unload", null, route === currentRoute);
    currentPath = path;
    currentRoute = route;
    currentRoute.run("popstate", currentPath);
    updateSecondaryNav();
    map.setState(e.originalEvent.state, { animate: false });
  });

  router.route = function (url) {
    const path = url.replace(/#.*/, ""),
          route = routes.recognize(path);
    if (!route) return false;
    currentRoute.run("unload", null, route === currentRoute);
    const state = OSM.parseHash(url);
    map.setState(state);
    window.history.pushState(state, document.title, url);
    currentPath = path;
    currentRoute = route;
    currentRoute.run("pushstate", currentPath);
    updateSecondaryNav();
    return true;
  };

  router.replace = function (url) {
    window.history.replaceState(OSM.parseHash(url), document.title, url);
  };

  router.stateChange = function (state) {
    const url = state.center ? OSM.formatHash(state) : location;
    window.history.replaceState(state, document.title, url);
  };

  router.updateHash = function () {
    const hash = OSM.formatHash(map);
    if (hash === currentHash) return;
    currentHash = hash;
    router.stateChange(OSM.parseHash(hash));
  };

  router.hashUpdated = function () {
    const hash = location.hash;
    if (hash === currentHash) return;
    currentHash = hash;
    const state = OSM.parseHash(hash);
    map.setState(state);
    router.stateChange(state, hash);
  };

  router.withoutMoveListener = function (callback) {
    function disableMoveListener() {
      map.off("moveend", router.updateHash);
      map.once("moveend", function () {
        map.on("moveend", router.updateHash);
      });
    }

    map.once("movestart", disableMoveListener);
    callback();
    map.off("movestart", disableMoveListener);
  };

  router.load = function () {
    const loadState = currentRoute.run("load", currentPath);
    router.stateChange(loadState || {});
  };

  router.setCurrentPath = function (path) {
    currentPath = path;
    currentRoute = routes.recognize(currentPath);
  };

  router.click = function (event, href) {
    const eventOptions = {};
    for (const key in event) eventOptions[key] = event[key];
    const clickEvent = new (event.constructor)("click", eventOptions);
    const link = document.createElement("a");
    link.href = href;
    document.body.appendChild(link);
    link.dispatchEvent(clickEvent);
    document.body.removeChild(link);
  };

  map.on("moveend baselayerchange overlayadd overlayremove", router.updateHash);
  $(window).on("hashchange", router.hashUpdated);

  return router;
};
