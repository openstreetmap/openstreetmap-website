/* exported RouteOutput */
function RouteOutput(map) {
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

  class UnitFormatter {
    constructor(unitObj) {
      const units = Object.entries(unitObj).sort((a, b) => a[1] - b[1]);
      [[this.minorName, this.minorScale], [this.majorName, this.majorScale]] = units;
    }

    print(name, distance) {
      const scope = "javascripts.directions.distance_in_units";
      return OSM.i18n.t(name, { scope, distance });
    }

    totalDistance(m) {
      const minorValue = m / this.minorScale;
      const majorValue = m / this.majorScale;

      if (minorValue < 1000 || majorValue < 0.25) return this.print(this.minorName, Math.round(minorValue));
      if (majorValue < 10) return this.print(this.majorName, majorValue.toFixed(1));
      return this.print(this.majorName, Math.round(majorValue));
    }

    stepDistance(m) {
      const minorValue = m / this.minorScale;
      const majorValue = m / this.majorScale;

      if (minorValue < 5) return "";
      if (minorValue < 200) return this.print(this.minorName, Math.round(minorValue / 10) * 10);
      if (minorValue < 1500 || majorValue < 0.25) return this.print(this.minorName, Math.round(minorValue / 100) * 100);
      if (majorValue < 5) return this.print(this.majorName, majorValue.toFixed(1));
      return this.print(this.majorName, Math.round(majorValue));
    }

    height(m) {
      if (isNaN(m)) return "";
      const minorValue = m / this.minorScale;

      return this.print(this.minorName, Math.round(minorValue));
    }

    time(s) {
      let m = Math.round(s / 60);
      const h = Math.floor(m / 60);

      m -= h * 60;

      return h + ":" + (m < 10 ? "0" : "") + m;
    }
  }

  const FORMATTERS = {
    km_m: new UnitFormatter({ km: 1000, m: 1 }),
    mi_ft: new UnitFormatter({ mi: 1609.344, ft: 0.3048 }),
    mi_yd: new UnitFormatter({ mi: 1609.344, yd: 0.9144 })
  };
  let formatter = FORMATTERS.km_m;
  let downloadURL = null;

  function writeTable({ distance, time, ascend, descend, steps }) {
    $("#directions_route_distance").val(formatter.totalDistance(distance));
    $("#directions_route_time").val(formatter.time(time));

    $("#directions_route_ascend_descend").prop("hidden", isNaN(ascend) || isNaN(descend));
    $("#directions_route_ascend").val(formatter.height(ascend));
    $("#directions_route_descend").val(formatter.height(descend));

    $("#directions_route_steps").empty().append(...steps.map(stepToRow));
  }

  function stepToRow([direction, instruction, dist, lineseg], i) {
    const popupText = `<b>${i + 1}.</b> ${instruction}`;
    let icon = "";
    if (direction) icon = `<svg width="20" height="20" class="d-block"><use href="#routing-sprite-${direction}" /></svg>`;

    return $("<tr class='turn'/>")
      .append(`<td class='ps-3'>${icon}</td>`)
      .append(`<td class="text-break">${popupText}</td>`)
      .append(`<td class="pe-3 distance text-body-secondary text-end">${formatter.stepDistance(dist)}</td>`)
      .on("click", () => popup
        .setLatLng(lineseg[0])
        .setContent(`<p>${popupText}</p>`)
        .openOn(map))
      .on("mouseenter", () => highlight
        .setLatLngs(lineseg)
        .addTo(map))
      .on("mouseleave", () => map.removeLayer(highlight));
  }

  const routeOutput = {};

  routeOutput.write = function (route) {
    polyline
      .setLatLngs(route.line)
      .addTo(map);

    writeTable(route);

    $("#directions_distance_units_settings input").off().on("change", function () {
      formatter = FORMATTERS[this.value] || FORMATTERS.km_m;
      writeTable(route);
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

  routeOutput.fit = () => map.fitBounds(polyline.getBounds().pad(0.05));

  routeOutput.isVisible = () => map.hasLayer(polyline);

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
