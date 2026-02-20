OSM.initializations.push(function (map) {
  const control = $(".control-query"),
        queryButton = control.find(".control-button");

  queryButton.on("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    if (control.hasClass("active")) {
      disableQueryMode();
    } else if (!queryButton.hasClass("disabled")) {
      enableQueryMode();
    }
  }).on("disabled", function () {
    if (control.hasClass("active")) {
      map.off("click", clickHandler);
      $(map.getContainer()).removeClass("query-active").addClass("query-disabled");
      $(this).tooltip("show");
    }
  }).on("enabled", function () {
    if (control.hasClass("active")) {
      map.on("click", clickHandler);
      $(map.getContainer()).removeClass("query-disabled").addClass("query-active");
      $(this).tooltip("hide");
    }
  });

  function clickHandler(e) {
    const [lat, lon] = OSM.cropLocation(e.latlng, map.getZoom());

    OSM.router.route("/query?" + new URLSearchParams({ lat, lon }));
  }

  function enableQueryMode() {
    $(".control-query").addClass("active");
    map.on("click", clickHandler);
    $(map.getContainer()).addClass("query-active");
  }

  function disableQueryMode() {
    $(map.getContainer()).removeClass("query-active").removeClass("query-disabled");
    map.off("click", clickHandler);
    $(".control-query").removeClass("active");
  }
});

OSM.Query = function (map) {
  const uninterestingTags = ["source", "source_ref", "source:ref", "history", "attribution", "created_by", "tiger:county", "tiger:tlid", "tiger:upload_uuid", "KSJ2:curve_id", "KSJ2:lat", "KSJ2:lon", "KSJ2:coordinate", "KSJ2:filename", "note:ja"];
  let marker;

  const featureStyle = {
    color: "#FF6200",
    weight: 4,
    opacity: 1,
    fillOpacity: 0.5,
    interactive: false
  };

  function showResultGeometry() {
    const geometry = $(this).data("geometry");
    if (geometry) map.addLayer(geometry);
    $(this).addClass("selected");
  }

  function hideResultGeometry() {
    const geometry = $(this).data("geometry");
    if (geometry) map.removeLayer(geometry);
    $(this).removeClass("selected");
  }

  $("#sidebar_content")
    .on("mouseover", ".query-results a", showResultGeometry)
    .on("mouseout", ".query-results a", hideResultGeometry);

  function interestingFeature(feature) {
    if (feature.tags) {
      for (const key in feature.tags) {
        if (uninterestingTags.indexOf(key) < 0) {
          return true;
        }
      }
    }

    return false;
  }

  function featurePrefix(feature) {
    const tags = feature.tags;
    let prefix = "";

    if (tags.boundary === "administrative" && (tags.border_type || tags.admin_level)) {
      prefix = OSM.i18n.t("geocoder.search_osm_nominatim.border_types." + tags.border_type, {
        defaultValue: OSM.i18n.t("geocoder.search_osm_nominatim.admin_levels.level" + tags.admin_level, {
          defaultValue: OSM.i18n.t("geocoder.search_osm_nominatim.prefix.boundary.administrative")
        })
      });
    } else {
      const prefixes = OSM.i18n.t("geocoder.search_osm_nominatim.prefix");

      for (const key in tags) {
        const value = tags[key];

        if (prefixes[key]) {
          if (prefixes[key][value]) {
            return prefixes[key][value];
          }
        }
      }

      for (const key in tags) {
        const value = tags[key];

        if (prefixes[key]) {
          const first = value.slice(0, 1).toUpperCase(),
                rest = value.slice(1).replace(/_/g, " ");

          return first + rest;
        }
      }
    }

    if (!prefix) {
      prefix = OSM.i18n.t("javascripts.query." + feature.type);
    }

    return prefix;
  }

  function featureName(feature) {
    const tags = feature.tags,
          localeKeys = OSM.preferred_languages.map(locale => `name:${locale}`);

    for (const key of [...localeKeys, "name", "ref", "addr:housename"]) {
      if (tags[key]) return tags[key];
    }
    if (tags["addr:housenumber"] && tags["addr:street"]) return `${tags["addr:housenumber"]} ${tags["addr:street"]}`;

    return "#" + feature.id;
  }

  function featureGeometry(feature) {
    switch (feature.type) {
      case "node":
        if (!feature.lat || !feature.lon) return;
        return L.circleMarker([feature.lat, feature.lon], featureStyle);
      case "way":
        if (!feature.geometry?.length) return;
        return L.polyline(feature.geometry.filter(p => p).map(p => [p.lat, p.lon]), featureStyle);
      case "relation":
        if (!feature.members?.length) return;
        return L.featureGroup(feature.members.map(featureGeometry).filter(g => g));
    }
  }

  function runQuery(query, $section, merge, compare) {
    const $ul = $section.find("ul");

    $ul.empty();
    $section.show();

    if ($section.data("ajax")) {
      $section.data("ajax").abort();
    }

    $section.data("ajax", new AbortController());
    fetch(OSM.OVERPASS_URL, {
      method: "POST",
      body: new URLSearchParams({
        data: "[timeout:10][out:json];" + query
      }),
      credentials: OSM.OVERPASS_CREDENTIALS ? "include" : "same-origin",
      signal: $section.data("ajax").signal
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error(response.statusText || response.status);
      })
      .then(function (results) {
        let elements = results.elements;

        $section.find(".loader").hide();

        // Make Overpass-specific bounds to Leaflet compatible
        for (const element of elements) {
          if (!element.bounds) continue;
          if (element.bounds.maxlon >= element.bounds.minlon) continue;
          element.bounds.maxlon += 360;
        }

        if (merge) {
          elements = Object.values(elements.reduce(function (hash, element) {
            const key = element.type + element.id;
            if ("geometry" in element) delete element.bounds;
            hash[key] = { ...hash[key], ...element };
            return hash;
          }, {}));
        }

        if (compare) {
          elements = elements.sort(compare);
        }

        for (const element of elements) {
          if (!interestingFeature(element)) continue;

          const $li = $("<li>")
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

        if (results.remark) renderError($ul, results.remark);

        if ($ul.find("li").length === 0) {
          $("<li>")
            .addClass("list-group-item")
            .text(OSM.i18n.t("javascripts.query.nothing_found"))
            .appendTo($ul);
        }
      })
      .catch(function (error) {
        if (error.name === "AbortError") return;

        $section.find(".loader").hide();

        renderError($ul, error.message);
      });
  }

  function renderError($ul, errorMessage) {
    $("<li>")
      .addClass("list-group-item")
      .text(OSM.i18n.t("javascripts.query.error", { server: OSM.OVERPASS_URL, error: errorMessage }))
      .appendTo($ul);
  }

  function size({ maxlon, minlon, maxlat, minlat }) {
    return (maxlon - minlon) * (maxlat - minlat);
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
  function queryOverpass(latlng) {
    const bounds = map.getBounds(),
          zoom = map.getZoom(),
          bbox = [bounds.getSouthWest(), bounds.getNorthEast()]
            .map(c => OSM.cropLocation(c, zoom))
            .join(),
          geom = `geom(${bbox})`,
          radius = 10 * Math.pow(1.5, 19 - zoom),
          here = `(around:${radius},${latlng})`,
          enclosed = "(pivot.a);out tags bb",
          nearby = `(node${here};way${here};);out tags ${geom};relation${here};out ${geom};`,
          isin = `is_in(${latlng})->.a;way${enclosed};out ids ${geom};relation${enclosed};`;

    $("#sidebar_content .query-intro")
      .hide();

    if (marker) map.removeLayer(marker);
    marker = L.circle(L.latLng(latlng).wrap(), {
      radius: radius,
      className: "query-marker",
      ...featureStyle
    }).addTo(map);

    runQuery(nearby, $("#query-nearby"), false);
    runQuery(isin, $("#query-isin"), true, (feature1, feature2) => size(feature1.bounds) - size(feature2.bounds));
  }

  const page = {};

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, function () {
      page.load(path, true);
    });
  };

  page.load = function (path, noCentre) {
    const params = new URLSearchParams(path.substring(path.indexOf("?"))),
          latlng = L.latLng(params.get("lat"), params.get("lon"));

    if (!location.hash && !noCentre && !map.getBounds().contains(latlng)) {
      OSM.router.withoutMoveListener(function () {
        map.setView(latlng, 15);
      });
    }

    queryOverpass([params.get("lat"), params.get("lon")]);
  };

  page.unload = function (sameController) {
    if (!sameController) {
      $("#sidebar_content .query-results a.selected").each(hideResultGeometry);
    }
  };

  return page;
};
