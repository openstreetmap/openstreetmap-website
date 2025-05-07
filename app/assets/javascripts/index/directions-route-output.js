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

  let distanceUnits = "km";
  let downloadURL = null;
  let route = {};

  function translateDistanceUnits(m) {
    const scope = "javascripts.directions.distance_in_units.";
    if (distanceUnits === "mi") return [scope + "miles", m / 0.3048, "ft", m / 1609.344, "mi"];
    return [scope + "meters", m, "m", m / 1000, "km"];
  }

  function formatTotalDistance(m) {
    const [scope, minorValue, minorName, majorValue, majorName] = translateDistanceUnits(m);

    if (minorValue < 1000 || majorValue < 0.25) {
      return OSM.i18n.t(minorName, { scope, distance: Math.round(minorValue) });
    } else if (majorValue < 10) {
      return OSM.i18n.t(majorName, { scope, distance: majorValue.toFixed(1) });
    } else {
      return OSM.i18n.t(majorName, { scope, distance: Math.round(majorValue) });
    }
  }

  function formatStepDistance(m) {
    const [scope, minorValue, minorName, majorValue, majorName] = translateDistanceUnits(m);

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

  function formatHeight(m) {
    const [scope, value, name] = translateDistanceUnits(m);

    return OSM.i18n.t(name, { scope, distance: Math.round(value) });
  }

  function formatTime(s) {
    let m = Math.round(s / 60);
    const h = Math.floor(m / 60);
    m -= h * 60;
    return h + ":" + (m < 10 ? "0" : "") + m;
  }

  function writeContent() {
    if (this?.dataset?.unit) distanceUnits = this.dataset.unit;

    $("#directions_route_distance").val(formatTotalDistance(route.distance));
    $("#directions_route_time").val(formatTime(route.time));
    $("#directions_route_ascend_descend").prop("hidden", typeof route.ascend === "undefined" || typeof route.descend === "undefined");
    $("#directions_route_ascend").val(formatHeight(route.ascend ?? 0));
    $("#directions_route_descend").val(formatHeight(route.descend ?? 0));
    $("#directions_route_steps").empty();

    for (const [i, step] of route.steps.entries()) {
      writeStep(step, i).appendTo("#directions_route_steps");
    }
  }

  function writeStep([direction, instruction, dist, lineseg], i) {
    const popupText = `<b>${i + 1}.</b> ${instruction}`;
    let icon = "";
    if (direction) icon = `<svg width="20" height="20" class="d-block"><use href="#routing-sprite-${direction}" /></svg>`;

    return $("<tr class='turn'/>")
      .append(`<td class="ps-3">${icon}</td>`)
      .append(`<td>${popupText}</td>`)
      .append(`<td class="pe-3 distance text-body-secondary text-end">${formatStepDistance(dist)}</td>`)
      .on("click", function () {
        popup
          .setLatLng(lineseg[0])
          .setContent(`<p>${popupText}</p>`)
          .openOn(map);
      })
      .on("mouseenter", function () {
        highlight
          .setLatLngs(lineseg)
          .addTo(map);
      })
      .on("mouseleave", function () {
        map.removeLayer(highlight);
      });
  }

  const routeOutput = {};

  routeOutput.write = function (r) {
    route = r;
    polyline
      .setLatLngs(route.line)
      .addTo(map);

    writeContent();
    $("#directions_route input[data-unit]").off().on("change", writeContent);

    const blob = new Blob([JSON.stringify(polyline.toGeoJSON())], { type: "application/json" });
    URL.revokeObjectURL(downloadURL);
    downloadURL = URL.createObjectURL(blob);
    $("#directions_route_download").prop("href", downloadURL);

    $("#directions_route_credit")
      .text(route.credit)
      .prop("href", route.creditlink);
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

    $("#directions_route input[data-unit]").off();

    $("#directions_route_steps").empty();

    URL.revokeObjectURL(downloadURL);
    $("#directions_route_download").prop("href", "");
  };

  return routeOutput;
};
