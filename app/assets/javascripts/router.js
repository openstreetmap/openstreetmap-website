OSM.Router = function(rts) {
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
    currentRoute = routes.recognize(currentPath);

  currentRoute.run('load', currentPath);

  if (window.history && window.history.pushState) {
    $(window).on('popstate', function() {
      var path = window.location.pathname + window.location.search;
      if (path === currentPath) return;
      currentRoute.run('unload');
      currentPath = path;
      currentRoute = routes.recognize(currentPath);
      currentRoute.run('popstate', currentPath);
    });

    return function (url) {
      var path = url.replace(/#.*/, ''),
        route = routes.recognize(path);
      if (!route) return false;
      window.history.pushState({}, document.title, url);
      currentRoute.run('unload');
      currentPath = path;
      currentRoute = route;
      currentRoute.run('pushstate', currentPath);
      return true;
    }
  } else {
    return function (url) {
      window.location.assign(url);
    }
  }
};
