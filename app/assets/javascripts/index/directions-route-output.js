OSM.DirectionsRouteOutput = function (map) {
  const popup = L.popup({ autoPanPadding: [100, 100] });

  const polyline = L.polyline([], {
    color: "#03f",
    opacity: 0.3,
    weight: 10
  });

  const highlight = L.polyline([], {
    color: "#ff0",
    opacity: 0.5,
    weight: 12
  });

  let distanceUnits = "km_m";
  let downloadURL = null;

  function translateDistanceUnits(m) {
    if (distanceUnits === "mi_ft") {
      return [m / 0.3048, "ft", m / 1609.344, "mi"];
    } else if (distanceUnits === "mi_yd") {
      return [m / 0.9144, "yd", m / 1609.344, "mi"];
    } else {
      return [m, "m", m / 1000, "km"];
    }
  }

  function formatTotalDistance(minorValue, minorName, majorValue, majorName) {
    const scope = "javascripts.directions.distance_in_units";

    if (minorValue < 1000 || majorValue < 0.25) {
      return OSM.i18n.t(minorName, { scope, distance: Math.round(minorValue) });
    } else if (majorValue < 10) {
      return OSM.i18n.t(majorName, { scope, distance: majorValue.toFixed(1) });
    } else {
      return OSM.i18n.t(majorName, { scope, distance: Math.round(majorValue) });
    }
  }

  function formatStepDistance(minorValue, minorName, majorValue, majorName) {
    const scope = "javascripts.directions.distance_in_units";

    if (minorValue < 5) {
      return "";
    } else if (minorValue < 200) {
      return OSM.i18n.t(minorName, { scope, distance: Math.round(minorValue / 10) * 10 });
    } else if (minorValue < 1500 || majorValue < 0.25) {
      return OSM.i18n.t(minorName, { scope, distance: Math.round(minorValue / 100) * 100 });
    } else if (majorValue < 5) {
      return OSM.i18n.t(majorName, { scope, distance: majorValue.toFixed(1) });
    } else {
      return OSM.i18n.t(majorName, { scope, distance: Math.round(majorValue) });
    }
  }

  function formatHeight(minorValue, minorName) {
    const scope = "javascripts.directions.distance_in_units";

    return OSM.i18n.t(minorName, { scope, distance: Math.round(minorValue) });
  }

  function formatTime(s) {
    let m = Math.round(s / 60);
    const h = Math.floor(m / 60);

    m -= h * 60;

    return h + ":" + (m < 10 ? "0" : "") + m;
  }

  function writeSummary(route) {
    $("#directions_route_distance").val(formatTotalDistance(...translateDistanceUnits(route.distance)));
    $("#directions_route_time").val(formatTime(route.time));

    if (typeof route.ascend !== "undefined" && typeof route.descend !== "undefined") {
      $("#directions_route_ascend_descend").prop("hidden", false);
      $("#directions_route_ascend").val(formatHeight(...translateDistanceUnits(route.ascend)));
      $("#directions_route_descend").val(formatHeight(...translateDistanceUnits(route.descend)));
    } else {
      $("#directions_route_ascend_descend").prop("hidden", true);
      $("#directions_route_ascend").val("");
      $("#directions_route_descend").val("");
    }
  }

  function writeSteps(route) {
    $("#directions_route_steps").empty();

    for (const [i, [direction, instruction, dist, lineseg]] of route.steps.entries()) {
      const row = $("<tr class='turn'/>").appendTo($("#directions_route_steps"));

      if (direction) {
        row.append("<td class='ps-3'><svg width='20' height='20' class='d-block'><use href='#routing-sprite-" + direction + "' /></svg></td>");
      } else {
        row.append("<td class='ps-3'>");
      }

      row.append(`<td><b>${i + 1}.</b> ${instruction}`);
      row.append("<td class='pe-3 distance text-body-secondary text-end'>" + formatStepDistance(...translateDistanceUnits(dist)));

      row.on("click", function () {
        popup
          .setLatLng(lineseg[0])
          .setContent(`<p><b>${i + 1}.</b> ${instruction}</p>`)
          .openOn(map);
      });

      row
        .on("mouseenter", function () {
          highlight
            .setLatLngs(lineseg)
            .addTo(map);
        })
        .on("mouseleave", function () {
          map.removeLayer(highlight);
        });
    }
  }

  const routeOutput = {};

  routeOutput.write = function (route) {
    polyline
      .setLatLngs(route.line)
      .addTo(map);

    writeSummary(route);
    writeSteps(route);

    $("#directions_distance_units_settings input").off().on("change", function () {
      distanceUnits = this.value;
      writeSummary(route);
      writeSteps(route);
    });

    const blob = new Blob([JSON.stringify(polyline.toGeoJSON())], { type: "application/geo+json" });

    URL.revokeObjectURL(downloadURL);
    downloadURL = URL.createObjectURL(blob);
    $("#directions_route_download").prop("href", downloadURL);

    $("#directions_route_credit")
      .text(route.credit)
      .prop("href", route.creditlink);
    $("#directions_route_demo")
      .text(route.credit)
      .prop("href", route.demolink);
  };

  routeOutput.fit = function () {
    map.fitBounds(polyline.getBounds().pad(0.05));
  };

  routeOutput.isVisible = function () {
    return map.hasLayer(polyline);
  };

  routeOutput.remove = function () {
    map
      .removeLayer(popup)
      .removeLayer(polyline);

    $("#directions_distance_units_settings input").off();

    $("#directions_route_steps").empty();

    URL.revokeObjectURL(downloadURL);
    $("#directions_route_download").prop("href", "");
  };

  return routeOutput;
};
