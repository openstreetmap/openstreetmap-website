L.OSM.layers = function (options) {
  var control = L.OSM.sidebarPane(options, "layers", "javascripts.map.layers.title", "javascripts.map.layers.header");

  control.onAddPane = function (map, button, $ui, toggle) {
    var layers = options.layers;

    var baseSection = $("<div>")
      .attr("class", "section base-layers")
      .appendTo($ui);

    var baseLayers = $("<ul class='list-unstyled mb-0'>")
      .appendTo(baseSection);

    layers.forEach(function (layer) {
      var item = $("<li>")
        .attr("class", "rounded-3")
        .appendTo(baseLayers);

      if (map.hasLayer(layer)) {
        item.addClass("active");
      }

      var div = $("<div>")
        .appendTo(item);

      map.whenReady(function () {
        var miniMap = L.map(div[0], { attributionControl: false, zoomControl: false, keyboard: false })
          .addLayer(new layer.constructor({ apikey: layer.options.apikey }));

        miniMap.dragging.disable();
        miniMap.touchZoom.disable();
        miniMap.doubleClickZoom.disable();
        miniMap.scrollWheelZoom.disable();

        $ui
          .on("show", shown)
          .on("hide", hide);

        function shown() {
          miniMap.invalidateSize();
          setView({ animate: false });
          map.on("moveend", moved);
        }

        function hide() {
          map.off("moveend", moved);
        }

        function moved() {
          setView();
        }

        function setView(options) {
          miniMap.setView(map.getCenter(), Math.max(map.getZoom() - 2, 0), options);
        }
      });

      var label = $("<label>")
        .appendTo(item);

      var input = $("<input>")
        .attr("type", "radio")
        .prop("checked", map.hasLayer(layer))
        .appendTo(label);

      label.append(layer.options.name);

      item.on("click", function () {
        layers.forEach(function (other) {
          if (other === layer) {
            map.addLayer(other);
          } else {
            map.removeLayer(other);
          }
        });
        map.fire("baselayerchange", { layer: layer });
      });

      item.on("dblclick", toggle);

      map.on("layeradd layerremove", function () {
        item.toggleClass("active", map.hasLayer(layer));
        input.prop("checked", map.hasLayer(layer));
      });
    });

    if (OSM.STATUS !== "api_offline" && OSM.STATUS !== "database_offline") {
      var overlaySection = $("<div>")
        .attr("class", "section overlay-layers")
        .appendTo($ui);

      $("<p>")
        .text(I18n.t("javascripts.map.layers.overlays"))
        .attr("class", "text-muted")
        .appendTo(overlaySection);

      var overlays = $("<ul class='list-unstyled form-check'>")
        .appendTo(overlaySection);

      var addOverlay = function (layer, name, maxArea) {
        var item = $("<li>")
          .appendTo(overlays);

        if (name === "notes" || name === "data") {
          item
            .attr("title", I18n.t("javascripts.site.map_" + name + "_zoom_in_tooltip"))
            .tooltip("disable");
        }

        var label = $("<label>")
          .attr("class", "form-check-label")
          .appendTo(item);

        var checked = map.hasLayer(layer);

        var input = $("<input>")
          .attr("type", "checkbox")
          .attr("class", "form-check-input")
          .prop("checked", checked)
          .appendTo(label);

        label.append(I18n.t("javascripts.map.layers." + name));

        input.on("change", function () {
          checked = input.is(":checked");
          if (checked) {
            map.addLayer(layer);
          } else {
            map.removeLayer(layer);
          }
          map.fire("overlaylayerchange", { layer: layer });
        });

        map.on("layeradd layerremove", function () {
          input.prop("checked", map.hasLayer(layer));
        });

        map.on("zoomend", function () {
          var disabled = map.getBounds().getSize() >= maxArea;
          $(input).prop("disabled", disabled);

          if (disabled && $(input).is(":checked")) {
            $(input).prop("checked", false)
              .trigger("change");
            checked = true;
          } else if (!disabled && !$(input).is(":checked") && checked) {
            $(input).prop("checked", true)
              .trigger("change");
          }

          $(item)
            .attr("class", disabled ? "disabled" : "")
            .tooltip(disabled ? "enable" : "disable");
        });
      };

      addOverlay(map.noteLayer, "notes", OSM.MAX_NOTE_REQUEST_AREA);
      addOverlay(map.dataLayer, "data", OSM.MAX_REQUEST_AREA);
      addOverlay(map.gpsLayer, "gps", Number.POSITIVE_INFINITY);
    }
  };

  return control;
};
