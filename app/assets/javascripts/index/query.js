OSM.Query = function (map) {
  var url = OSM.OVERPASS_URL,
      credentials = OSM.OVERPASS_CREDENTIALS,
      queryButton = $(".control-query .control-button"),
      uninterestingTags = ["source", "source_ref", "source:ref", "history", "attribution", "created_by", "tiger:county", "tiger:tlid", "tiger:upload_uuid", "KSJ2:curve_id", "KSJ2:lat", "KSJ2:lon", "KSJ2:coordinate", "KSJ2:filename", "note:ja"],
      marker;

  var featureStyle = {
    color: "#FF6200",
    weight: 4,
    opacity: 1,
    fillOpacity: 0.5,
    interactive: false
  };

  queryButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if (queryButton.hasClass("active")) {
      disableQueryMode();
    } else if (!queryButton.hasClass("disabled")) {
      enableQueryMode();
    }
  }).on("disabled", function () {
    if (queryButton.hasClass("active")) {
      map.off("click", clickHandler);
      $(map.getContainer()).removeClass("query-active").addClass("query-disabled");
      $(this).tooltip("show");
    }
  }).on("enabled", function () {
    if (queryButton.hasClass("active")) {
      map.on("click", clickHandler);
      $(map.getContainer()).removeClass("query-disabled").addClass("query-active");
      $(this).tooltip("hide");
    }
  });

  function showResultGeometry() {
    var geometry = $(this).data("geometry");
    if (geometry) map.addLayer(geometry);
    $(this).addClass("selected");
  }

  function hideResultGeometry() {
    var geometry = $(this).data("geometry");
    if (geometry) map.removeLayer(geometry);
    $(this).removeClass("selected");
  }

  $("#sidebar_content")
    .on("mouseover", ".query-results a", showResultGeometry)
    .on("mouseout", ".query-results a", hideResultGeometry);

  function interestingFeature(feature) {
    if (feature.tags) {
      for (var key in feature.tags) {
        if (uninterestingTags.indexOf(key) < 0) {
          return true;
        }
      }
    }

    return false;
  }

  function featurePrefix(feature) {
    var tags = feature.tags;
    var prefix = "";

    if (tags.boundary === "administrative" && tags.admin_level) {
      prefix = I18n.t("geocoder.search_osm_nominatim.admin_levels.level" + tags.admin_level, {
        defaultValue: I18n.t("geocoder.search_osm_nominatim.prefix.boundary.administrative")
      });
    } else {
      var prefixes = I18n.t("geocoder.search_osm_nominatim.prefix");
      var key, value;

      for (key in tags) {
        value = tags[key];

        if (prefixes[key]) {
          if (prefixes[key][value]) {
            return prefixes[key][value];
          }
        }
      }

      for (key in tags) {
        value = tags[key];

        if (prefixes[key]) {
          var first = value.slice(0, 1).toUpperCase(),
              rest = value.slice(1).replace(/_/g, " ");

          return first + rest;
        }
      }
    }

    if (!prefix) {
      prefix = I18n.t("javascripts.query." + feature.type);
    }

    return prefix;
  }

  function featureName(feature) {
    var tags = feature.tags,
        locales = OSM.preferred_languages;

    for (const locale of locales) {
      if (tags["name:" + locale]) {
        return tags["name:" + locale];
      }
    }

    for (const key of ["name", "ref", "addr:housename"]) {
      if (tags[key]) {
        return tags[key];
      }
    }

    if (tags["addr:housenumber"] && tags["addr:street"]) {
      return tags["addr:housenumber"] + " " + tags["addr:street"];
    }
    return "#" + feature.id;
  }

  function featureGeometry(feature) {
    var geometry;

    if (feature.type === "node" && feature.lat && feature.lon) {
      geometry = L.circleMarker([feature.lat, feature.lon], featureStyle);
    } else if (feature.type === "way" && feature.geometry && feature.geometry.length > 0) {
      geometry = L.polyline(feature.geometry.filter(function (point) {
        return point !== null;
      }).map(function (point) {
        return [point.lat, point.lon];
      }), featureStyle);
    } else if (feature.type === "relation" && feature.members) {
      geometry = L.featureGroup(feature.members.map(featureGeometry).filter(function (geometry) {
        return typeof geometry !== "undefined";
      }));
    }

    return geometry;
  }

  function runQuery(latlng, radius, query, $section, merge, compare) {
    var $ul = $section.find("ul");

    $ul.empty();
    $section.show();

    if ($section.data("controller")) {
      $section.data("controller").abort();
    }

    $section.data("controller", new AbortController());

    const request = new Request(url, {
      method: "POST",
      body: new URLSearchParams({
        data: "[timeout:10][out:json];" + query
      }),
      credentials: credentials ? "include" : "omit",
      signal: $section.data("controller").signal
    });

    fetch(request)
      .then(response => response.json())
      .then(results => {
        var elements;

        $section.find(".loader").hide();

        if (merge) {
          elements = results.elements.reduce(function (hash, element) {
            var key = element.type + element.id;
            if ("geometry" in element) {
              delete element.bounds;
            }
            hash[key] = $.extend({}, hash[key], element);
            return hash;
          }, {});

          elements = Object.keys(elements).map(function (key) {
            return elements[key];
          });
        } else {
          elements = results.elements;
        }

        if (compare) {
          elements = elements.sort(compare);
        }

        for (const element of elements) {
          if (!interestingFeature(element)) continue;

          var $li = $("<li>")
            .addClass("list-group-item list-group-item-action")
            .text(featurePrefix(element) + " ")
            .appendTo($ul);

          $("<a>")
            .addClass("stretched-link")
            .attr("href", "/" + element.type + "/" + element.id)
            .data("geometry", featureGeometry(element))
            .text(featureName(element))
            .appendTo($li);
        }

        if (results.remark) {
          $("<li>")
            .addClass("list-group-item")
            .text(I18n.t("javascripts.query.error", { server: url, error: results.remark }))
            .appendTo($ul);
        }

        if ($ul.find("li").length === 0) {
          $("<li>")
            .addClass("list-group-item")
            .text(I18n.t("javascripts.query.nothing_found"))
            .appendTo($ul);
        }
      })
      .catch(error => {
        $section.find(".loader").hide();

        $("<li>")
          .addClass("list-group-item")
          .text(I18n.t("javascripts.query.error", { server: url, error: error.message }))
          .appendTo($ul);
      })
      .finally(() => {
        $section.data("controller", null);
      });
  }

  function compareSize(feature1, feature2) {
    var width1 = feature1.bounds.maxlon - feature1.bounds.minlon,
        height1 = feature1.bounds.maxlat - feature1.bounds.minlat,
        area1 = width1 * height1,
        width2 = feature2.bounds.maxlat - feature2.bounds.minlat,
        height2 = feature2.bounds.maxlat - feature2.bounds.minlat,
        area2 = width2 * height2;

    return area1 - area2;
  }

  /*
   * To find nearby objects we ask overpass for the union of the
   * following sets:
   *
   *   node(around:<radius>,<lat>,<lng>)
   *   way(around:<radius>,<lat>,<lng>)
   *   relation(around:<radius>,<lat>,<lng>)
   *
   * to find enclosing objects we first find all the enclosing areas:
   *
   *   is_in(<lat>,<lng>)->.a
   *
   * and then return the union of the following sets:
   *
   *   relation(pivot.a)
   *   way(pivot.a)
   *
   * In both cases we then ask to retrieve tags and the geometry
   * for each object.
   */
  function queryOverpass(lat, lng) {
    var latlng = L.latLng(lat, lng).wrap(),
        bounds = map.getBounds().wrap(),
        zoom = map.getZoom(),
        bbox = [bounds.getSouthWest(), bounds.getNorthEast()]
          .map(c => OSM.cropLocation(c, zoom))
          .join(),
        geombbox = "geom(" + bbox + ");",
        radius = 10 * Math.pow(1.5, 19 - zoom),
        around = "(around:" + radius + "," + lat + "," + lng + ")",
        nodes = "node" + around,
        ways = "way" + around,
        relations = "relation" + around,
        nearby = "(" + nodes + ";" + ways + ";);out tags " + geombbox + relations + ";out " + geombbox,
        isin = "is_in(" + lat + "," + lng + ")->.a;way(pivot.a);out tags bb;out ids " + geombbox + "relation(pivot.a);out tags bb;";

    $("#sidebar_content .query-intro")
      .hide();

    if (marker) map.removeLayer(marker);
    marker = L.circle(latlng, {
      radius: radius,
      className: "query-marker",
      ...featureStyle
    }).addTo(map);

    runQuery(latlng, radius, nearby, $("#query-nearby"), false);
    runQuery(latlng, radius, isin, $("#query-isin"), true, compareSize);
  }

  function clickHandler(e) {
    const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

    OSM.router.route("/query?" + new URLSearchParams({ lat, lon }));
  }

  function enableQueryMode() {
    queryButton.addClass("active");
    map.on("click", clickHandler);
    $(map.getContainer()).addClass("query-active");
  }

  function disableQueryMode() {
    if (marker) map.removeLayer(marker);
    $(map.getContainer()).removeClass("query-active").removeClass("query-disabled");
    map.off("click", clickHandler);
    queryButton.removeClass("active");
  }

  var page = {};

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, function () {
      page.load(path, true);
    });
  };

  page.load = function (path, noCentre) {
    const params = new URLSearchParams(path.substring(path.indexOf("?"))),
          latlng = L.latLng(params.get("lat"), params.get("lon"));

    if (!window.location.hash && !noCentre && !map.getBounds().contains(latlng)) {
      OSM.router.withoutMoveListener(function () {
        map.setView(latlng, 15);
      });
    }

    queryOverpass(params.get("lat"), params.get("lon"));
  };

  page.unload = function (sameController) {
    if (!sameController) {
      disableQueryMode();
      $("#sidebar_content .query-results a.selected").each(hideResultGeometry);
    }
  };

  return page;
};
