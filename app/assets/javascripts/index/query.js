//= require jquery.simulate
//= require querystring

OSM.Query = function (map) {
  var querystring = require("querystring-component");

  var url = OSM.OVERPASS_URL,
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

  $("#sidebar_content")
    .on("mouseover", ".query-results li.query-result", function () {
      var geometry = $(this).data("geometry");
      if (geometry) map.addLayer(geometry);
      $(this).addClass("selected");
    })
    .on("mouseout", ".query-results li.query-result", function () {
      var geometry = $(this).data("geometry");
      if (geometry) map.removeLayer(geometry);
      $(this).removeClass("selected");
    })
    .on("mousedown", ".query-results li.query-result", function () {
      var moved = false;
      $(this).one("click", function (e) {
        if (!moved) {
          var geometry = $(this).data("geometry");
          if (geometry) map.removeLayer(geometry);

          if (!$(e.target).is("a")) {
            $(this).find("a").simulate("click", e);
          }
        }
      }).one("mousemove", function () {
        moved = true;
      });
    });

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
          var first = value.substr(0, 1).toUpperCase(),
              rest = value.substr(1).replace(/_/g, " ");

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
        locales = I18n.locales.get();

    for (var i = 0; i < locales.length; i++) {
      if (tags["name:" + locales[i]]) {
        return tags["name:" + locales[i]];
      }
    }

    if (tags.name) {
      return tags.name;
    } else if (tags.ref) {
      return tags.ref;
    } else if (tags["addr:housename"]) {
      return tags["addr:housename"];
    } else if (tags["addr:housenumber"] && tags["addr:street"]) {
      return tags["addr:housenumber"] + " " + tags["addr:street"];
    } else {
      return "#" + feature.id;
    }
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

    $section.find(".loader").oneTime(1000, "loading", function () {
      $(this).show();
    });

    if ($section.data("ajax")) {
      $section.data("ajax").abort();
    }

    $section.data("ajax", $.ajax({
      url: url,
      method: "POST",
      data: {
        data: "[timeout:10][out:json];" + query
      },
      success: function (results) {
        var elements;

        $section.find(".loader").stopTime("loading").hide();

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

        for (var i = 0; i < elements.length; i++) {
          var element = elements[i];

          if (interestingFeature(element)) {
            var $li = $("<li>")
              .addClass("query-result")
              .data("geometry", featureGeometry(element))
              .appendTo($ul);
            var $p = $("<p>")
              .text(featurePrefix(element) + " ")
              .appendTo($li);

            $("<a>")
              .attr("href", "/" + element.type + "/" + element.id)
              .text(featureName(element))
              .appendTo($p);
          }
        }

        if (results.remark) {
          $("<li>")
            .text(I18n.t("javascripts.query.error", { server: url, error: results.remark }))
            .appendTo($ul);
        }

        if ($ul.find("li").length === 0) {
          $("<li>")
            .text(I18n.t("javascripts.query.nothing_found"))
            .appendTo($ul);
        }
      },
      error: function (xhr, status, error) {
        $section.find(".loader").stopTime("loading").hide();

        $("<li>")
          .text(I18n.t("javascripts.query." + status, { server: url, error: error }))
          .appendTo($ul);
      }
    }));
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
   *   node(around:<radius>,<lat>,lng>)
   *   way(around:<radius>,<lat>,lng>)
   *   relation(around:<radius>,<lat>,lng>)
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
        precision = OSM.zoomPrecision(map.getZoom()),
        bbox = bounds.getSouth().toFixed(precision) + "," +
               bounds.getWest().toFixed(precision) + "," +
               bounds.getNorth().toFixed(precision) + "," +
               bounds.getEast().toFixed(precision),
        radius = 10 * Math.pow(1.5, 19 - map.getZoom()),
        around = "around:" + radius + "," + lat + "," + lng,
        nodes = "node(" + around + ")",
        ways = "way(" + around + ")",
        relations = "relation(" + around + ")",
        nearby = "(" + nodes + ";" + ways + ";);out tags geom(" + bbox + ");" + relations + ";out geom(" + bbox + ");",
        isin = "is_in(" + lat + "," + lng + ")->.a;way(pivot.a);out tags bb;out ids geom(" + bbox + ");relation(pivot.a);out tags bb;";

    $("#sidebar_content .query-intro")
      .hide();

    if (marker) map.removeLayer(marker);
    marker = L.circle(latlng, radius, featureStyle).addTo(map);

    $(document).everyTime(75, "fadeQueryMarker", function (i) {
      if (i === 10) {
        map.removeLayer(marker);
      } else {
        marker.setStyle({
          opacity: 1 - (i * 0.1),
          fillOpacity: 0.5 - (i * 0.05)
        });
      }
    }, 10);

    runQuery(latlng, radius, nearby, $("#query-nearby"), false);
    runQuery(latlng, radius, isin, $("#query-isin"), true, compareSize);
  }

  function clickHandler(e) {
    var precision = OSM.zoomPrecision(map.getZoom()),
        latlng = e.latlng.wrap(),
        lat = latlng.lat.toFixed(precision),
        lng = latlng.lng.toFixed(precision);

    OSM.router.route("/query?lat=" + lat + "&lon=" + lng);
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
    var params = querystring.parse(path.substring(path.indexOf("?") + 1)),
        latlng = L.latLng(params.lat, params.lon);

    if (!window.location.hash && !noCentre && !map.getBounds().contains(latlng)) {
      OSM.router.withoutMoveListener(function () {
        map.setView(latlng, 15);
      });
    }

    queryOverpass(params.lat, params.lon);
  };

  page.unload = function (sameController) {
    if (!sameController) {
      disableQueryMode();
    }
  };

  return page;
};
