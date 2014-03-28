//= require jquery.simulate

OSM.Query = function(map) {
  var protocol = document.location.protocol === "https:" ? "https:" : "http:",
    url = protocol + OSM.OVERPASS_URL,
    queryButton = $(".control-query .control-button"),
    uninterestingTags = ['source', 'source_ref', 'source:ref', 'history', 'attribution', 'created_by', 'tiger:county', 'tiger:tlid', 'tiger:upload_uuid'],
    marker;

  var featureStyle = {
    color: "#FF6200",
    weight: 4,
    opacity: 1,
    fillOpacity: 0.5,
    clickable: false
  };

  queryButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if (queryButton.hasClass("disabled")) return;

    if (queryButton.hasClass("active")) {
      if ($("#content").hasClass("overlay-sidebar")) {
        disableQueryMode();
      }
    } else {
      enableQueryMode();
    }
  }).on("disabled", function (e) {
    if (queryButton.hasClass("active")) {
      map.off("click", clickHandler);
      $(map.getContainer()).removeClass("query-active").addClass("query-disabled");
      $(this).tooltip("show");
    }
  }).on("enabled", function (e) {
    if (queryButton.hasClass("active")) {
      map.on("click", clickHandler);
      $(map.getContainer()).removeClass("query-disabled").addClass("query-active");
      $(this).tooltip("hide");
    }
  });

  $("#sidebar_content")
    .on("mouseover", ".query-results li.query-result", function () {
      var geometry = $(this).data("geometry")
      if (geometry) map.addLayer(geometry);
      $(this).addClass("selected");
    })
    .on("mouseout", ".query-results li.query-result", function () {
      var geometry = $(this).data("geometry")
      if (geometry) map.removeLayer(geometry);
      $(this).removeClass("selected");
    })
    .on("click", ".query-results li.query-result", function (e) {
      var geometry = $(this).data("geometry")
      if (geometry) map.removeLayer(geometry);

      if (!$(e.target).is('a')) {
        $(this).find("a").simulate("click", e);
      }
    });

  function interestingFeature(feature, origin, radius) {
    if (feature.tags) {
      if (feature.type === "node" &&
          OSM.distance(origin, L.latLng(feature.lat, feature.lon)) > radius) {
        return false;
      }

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

    if (tags.boundary === "administrative") {
      prefix = I18n.t("geocoder.search_osm_nominatim.admin_levels.level" + tags.admin_level)
    } else {
      var prefixes = I18n.t("geocoder.search_osm_nominatim.prefix");

      for (var key in tags) {
        var value = tags[key];

        if (prefixes[key]) {
          if (prefixes[key][value]) {
            return prefixes[key][value];
          } else {
            var first = value.substr(0, 1).toUpperCase(),
              rest = value.substr(1).replace(/_/g, " ");

            return first + rest;
          }
        }
      }
    }

    if (!prefix) {
      prefix = I18n.t("javascripts.query." + feature.type);
    }

    return prefix;
  }

  function featureName(feature) {
    var tags = feature.tags;

    if (tags["name"]) {
      return tags["name"];
    } else if (tags["ref"]) {
      return tags["ref"];
    } else if (tags["addr:housename"]) {
      return tags["addr:housename"];
    } else if (tags["addr:housenumber"] && tags["addr:street"]) {
      return tags["addr:housenumber"] + " " + tags["addr:street"];
    } else {
      return "#" + feature.id;
    }
  }

  function featureGeometry(feature, features) {
    var geometry;

    if (feature.type === "node") {
      geometry = L.circleMarker([feature.lat, feature.lon], featureStyle);
    } else if (feature.type === "way") {
      geometry = L.polyline(feature.nodes.map(function (node) {
        return features["node" + node].getLatLng();
      }), featureStyle);
    } else if (feature.type === "relation") {
      geometry = L.featureGroup();

      feature.members.forEach(function (member) {
        if (features[member.type + member.ref]) {
          geometry.addLayer(features[member.type + member.ref]);
        }
      });
    }

    if (geometry) {
      features[feature.type + feature.id] = geometry;
    }

    return geometry;
  }

  function runQuery(latlng, radius, query, $section) {
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
        data: "[timeout:5][out:json];" + query,
      },
      success: function(results) {
        var features = {};

        $section.find(".loader").stopTime("loading").hide();

        for (var i = 0; i < results.elements.length; i++) {
          var element = results.elements[i],
            geometry = featureGeometry(element, features);

          if (interestingFeature(element, latlng, radius)) {
            var $li = $("<li>")
              .addClass("query-result")
              .data("geometry", geometry)
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

        if ($ul.find("li").length == 0) {
          $("<li>")
            .text(I18n.t("javascripts.query.nothing_found"))
            .appendTo($ul);
        }
      },
      error: function(xhr, status, error) {
        $section.find(".loader").stopTime("loading").hide();

        $("<li>")
          .text(I18n.t("javascripts.query." + status, { server: url, error: error }))
          .appendTo($ul);
      }
    }));
  }

  /*
   * To find nearby objects we ask overpass for the union of the
   * following sets:
   *
   *   node(around:<radius>,<lat>,lng>)
   *   way(around:<radius>,<lat>,lng>)
   *   node(w)
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
   *   node(w)
   *
   * In order to avoid overly large responses we don't currently
   * attempt to complete any relations and instead just show those
   * ways and nodes which are returned for other reasons.
   */
  function queryOverpass(lat, lng) {
    var latlng = L.latLng(lat, lng),
      radius = 10 * Math.pow(1.5, 19 - map.getZoom()),
      around = "around:" + radius + "," + lat + "," + lng,
      nodes = "node(" + around + ")",
      ways = "way(" + around + ");node(w)",
      relations = "relation(" + around + ")",
      nearby = "(" + nodes + ";" + ways + ";" + relations + ");out;",
      isin = "is_in(" + lat + "," + lng + ")->.a;(relation(pivot.a);way(pivot.a);node(w));out;";

    $("#sidebar_content .query-intro")
      .hide();

    if (marker) map.removeLayer(marker);
    marker = L.circle(latlng, radius, featureStyle).addTo(map);

    $(document).everyTime(75, "fadeQueryMarker", function (i) {
      if (i == 10) {
        map.removeLayer(marker);
      } else {
        marker.setStyle({
          opacity: 1 - i * 0.1,
          fillOpacity: 0.5 - i * 0.05
        });
      }
    }, 10);

    runQuery(latlng, radius, nearby, $("#query-nearby"));
    runQuery(latlng, radius, isin, $("#query-isin"));
  }

  function clickHandler(e) {
    var precision = OSM.zoomPrecision(map.getZoom()),
      lat = e.latlng.lat.toFixed(precision),
      lng = e.latlng.lng.toFixed(precision);

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

  page.pushstate = page.popstate = function(path) {
    OSM.loadSidebarContent(path, function () {
      page.load(path, true);
    });
  };

  page.load = function(path, noCentre) {
    var params = querystring.parse(path.substring(path.indexOf('?') + 1)),
      latlng = L.latLng(params.lat, params.lon);

    if (!window.location.hash &&
        (!noCentre || !map.getBounds().contains(latlng))) {
      OSM.router.withoutMoveListener(function () {
        map.setView(latlng, 15);
      });
    }

    queryOverpass(params.lat, params.lon);
    enableQueryMode();
  };

  page.unload = function() {
    disableQueryMode();
  };

  return page;
};
