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

  let downloadURL = null;

  function formatTotalDistance(m) {
    if (m < 1000) {
      return OSM.i18n.t("javascripts.directions.distance_m", { distance: Math.round(m) });
    } else if (m < 10000) {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: (m / 1000.0).toFixed(1) });
    } else {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: Math.round(m / 1000) });
    }
  }

  function formatStepDistance(m) {
    if (m < 5) {
      return "";
    } else if (m < 200) {
      return OSM.i18n.t("javascripts.directions.distance_m", { distance: String(Math.round(m / 10) * 10) });
    } else if (m < 1500) {
      return OSM.i18n.t("javascripts.directions.distance_m", { distance: String(Math.round(m / 100) * 100) });
    } else if (m < 5000) {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: String(Math.round(m / 100) / 10) });
    } else {
      return OSM.i18n.t("javascripts.directions.distance_km", { distance: String(Math.round(m / 1000)) });
    }
  }

  function formatHeight(m) {
    return OSM.i18n.t("javascripts.directions.distance_m", { distance: Math.round(m) });
  }

  function formatTime(s) {
    let m = Math.round(s / 60);
    const h = Math.floor(m / 60);
    m -= h * 60;
    return h + ":" + (m < 10 ? "0" : "") + m;
  }

  const routeOutput = {};

  routeOutput.write = function (content, route) {
    polyline
      .setLatLngs(route.line)
      .addTo(map);

    const distanceText = $("<p>").append(
      OSM.i18n.t("javascripts.directions.distance") + ": " + formatTotalDistance(route.distance) + ". " +
      OSM.i18n.t("javascripts.directions.time") + ": " + formatTime(route.time) + ".");
    if (typeof route.ascend !== "undefined" && typeof route.descend !== "undefined") {
      distanceText.append(
        $("<br>"),
        OSM.i18n.t("javascripts.directions.ascend") + ": " + formatHeight(route.ascend) + ". " +
        OSM.i18n.t("javascripts.directions.descend") + ": " + formatHeight(route.descend) + ".");
    }

    const turnByTurnTable = $("<table class='table table-hover table-sm mb-3'>")
      .append($("<tbody>"));

    content
      .empty()
      .append(
        distanceText,
        turnByTurnTable
      );

    for (const [i, [direction, instruction, dist, lineseg]] of route.steps.entries()) {
      const row = $("<tr class='turn'/>").appendTo(turnByTurnTable);

      if (direction) {
        row.append("<td class='border-0'><svg width='20' height='20' class='d-block'><use href='#routing-sprite-" + direction + "' /></svg></td>");
      } else {
        row.append("<td class='border-0'>");
      }
      row.append(`<td><b>${i + 1}.</b> ${instruction}`);
      row.append("<td class='distance text-body-secondary text-end'>" + formatStepDistance(dist));

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

    const blob = new Blob([JSON.stringify(polyline.toGeoJSON())], { type: "application/json" });
    URL.revokeObjectURL(downloadURL);
    downloadURL = URL.createObjectURL(blob);

    content.append(`<p class="text-center"><a href="${downloadURL}" download="${
      OSM.i18n.t("javascripts.directions.filename")
    }">${
      OSM.i18n.t("javascripts.directions.download")
    }</a></p>`);

    content.append("<p class=\"text-center\">" +
      OSM.i18n.t("javascripts.directions.instructions.courtesy", {
        link: `<a href="${route.creditlink}" target="_blank">${route.credit}</a>`
      }) +
      "</p>");
  };

  routeOutput.fit = function () {
    map.fitBounds(polyline.getBounds().pad(0.05));
  };

  routeOutput.isVisible = function () {
    return map.hasLayer(polyline);
  };

  routeOutput.remove = function (content) {
    content.empty();
    map
      .removeLayer(popup)
      .removeLayer(polyline);
  };

  return routeOutput;
};
