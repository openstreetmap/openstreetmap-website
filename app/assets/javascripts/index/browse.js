//= require templates/browse/feature
//= require templates/browse/feature_list
//= require templates/browse/feature_history

$(document).ready(function () {
  $("#show_data").click(function (e) {
    $.ajax({ url: $(this).attr('href'), success: function (sidebarHtml) {
      startBrowse(sidebarHtml);
    }});
    e.preventDefault();
  });

  function startBrowse(sidebarHtml) {
    var browseBoxControl;
    var browseMode = "auto";
    var browseBounds;
    var browseFeatureList;
    var browseActiveFeature;
    var browseDataLayer;
    var browseSelectControl;
    var browseObjectList;
    var areasHidden = false;

    OpenLayers.Feature.Vector.style['default'].strokeWidth = 3;
    OpenLayers.Feature.Vector.style['default'].cursor = "pointer";

    map.dataLayer.active = true;

    $("#sidebar_title").html(I18n.t('browse.start_rjs.data_frame_title'));
    $("#sidebar_content").html(sidebarHtml);

    openSidebar();

    var vectors = new OpenLayers.Layer.Vector();

    browseBoxControl = new OpenLayers.Control.DrawFeature(vectors, OpenLayers.Handler.RegularPolygon, {
      handlerOptions: {
        sides: 4,
        snapAngle: 90,
        irregular: true,
        persist: true
      }
    });
    browseBoxControl.handler.callbacks.done = endDrag;
    map.addControl(browseBoxControl);

    map.events.register("moveend", map, updateData);
    map.events.triggerEvent("moveend");

    $("#browse_select_view").click(useMap);

    $("#browse_select_box").click(startDrag);

    $("#browse_hide_areas_box").html(I18n.t('browse.start_rjs.hide_areas'));
    $("#browse_hide_areas_box").show();
    $("#browse_hide_areas_box").click(hideAreas);

    function updateData() {
      if (browseMode == "auto") {
        if (map.getZoom() >= 15) {
            useMap(false);
        } else {
            setStatus(I18n.t('browse.start_rjs.zoom_or_select'));
        }
      }
    }

    $("#sidebar").one("closed", function () {
      if (map.dataLayer.active) {
        map.dataLayer.active = false;

        if (browseSelectControl) {
          browseSelectControl.destroy();
          browseSelectControl = null;
        }

        if (browseBoxControl) {
          browseBoxControl.destroy();
          browseBoxControl = null;
        }

        if (browseActiveFeature) {
          browseActiveFeature.destroy();
          browseActiveFeature = null;
        }

        if (browseDataLayer) {
          browseDataLayer.destroy();
          browseDataLayer = null;
        }

        map.dataLayer.setVisibility(false);
        map.events.unregister("moveend", map, updateData);
      }
    });

    function startDrag() {
      $("#browse_select_box").html(I18n.t('browse.start_rjs.drag_a_box'));

      browseBoxControl.activate();

      return false;
    }

    function useMap(reload) {
      var bounds = map.getExtent();
      var projected = unproj(bounds);

      if (!browseBounds || !browseBounds.containsBounds(projected)) {
        var center = bounds.getCenterLonLat();
        var tileWidth = bounds.getWidth() * 1.2;
        var tileHeight = bounds.getHeight() * 1.2;
        var tileBounds = new OpenLayers.Bounds(center.lon - (tileWidth / 2),
                                               center.lat - (tileHeight / 2),
                                               center.lon + (tileWidth / 2),
                                               center.lat + (tileHeight / 2));

        browseBounds = tileBounds;
        getData(tileBounds, reload);

        browseMode = "auto";

        $("#browse_select_view").hide();
      }

      return false;
    }

    function hideAreas() {
      $("#browse_hide_areas_box").html(I18n.t('browse.start_rjs.show_areas'));
      $("#browse_hide_areas_box").show();
      $("#browse_hide_areas_box").click(showAreas);

      areasHidden = true;

      useMap(true);
    }

    function showAreas() {
      $("#browse_hide_areas_box").html(I18n.t('browse.start_rjs.hide_areas'));
      $("#browse_hide_areas_box").show();
      $("#browse_hide_areas_box").click(hideAreas);

      areasHidden = false;

      useMap(true);
    }

    function endDrag(bbox) {
      var bounds = bbox.getBounds();
      var projected = unproj(bounds);

      browseBoxControl.deactivate();
      browseBounds = projected;
      getData(bounds);

      browseMode = "manual";

      $("#browse_select_box").html(I18n.t('browse.start_rjs.manually_select'));
      $("#browse_select_view").show();
    }

    function displayFeatureWarning(count, limit, callback) {
      clearStatus();

      var div = document.createElement("div");

      var p = document.createElement("p");
      p.appendChild(document.createTextNode(I18n.t("browse.start_rjs.loaded_an_area_with_num_features", { num_features: count, max_features: limit })));
      div.appendChild(p);

      var input = document.createElement("input");
      input.type = "submit";
      input.value = I18n.t('browse.start_rjs.load_data');
      input.onclick = callback;
      div.appendChild(input);

      $("#browse_content").html("");
      $("#browse_content").append(div);
    }

    function customDataLoader(resp, options) {
      if (map.dataLayer.active) {
        var request = resp.priv;
        var doc = request.responseXML;

        if (!doc || !doc.documentElement) {
          doc = request.responseText;
        }

        resp.features = this.format.read(doc);

        if (!this.maxFeatures || resp.features.length <= this.maxFeatures) {
          options.callback.call(options.scope, resp);
        } else {
          displayFeatureWarning(resp.features.length, this.maxFeatures, function () {
            options.callback.call(options.scope, resp);
          });
        }
      }
    }

    function getData(bounds, reload) {
      var projected = unproj(bounds);
      var size = projected.getWidth() * projected.getHeight();

      if (size > OSM.MAX_REQUEST_AREA) {
        setStatus(I18n.t("browse.start_rjs.unable_to_load_size", { max_bbox_size: OSM.MAX_REQUEST_AREA, bbox_size: size }));
      } else {
        loadData("/api/" + OSM.API_VERSION + "/map?bbox=" + projected.toBBOX(), reload);
      }
    }

    function loadData(url, reload) {
      setStatus(I18n.t('browse.start_rjs.loading'));

      $("#browse_content").empty();

      var formatOptions = {
        checkTags: true,
        interestingTagsExclude: ['source','source_ref','source:ref','history','attribution','created_by','tiger:county','tiger:tlid','tiger:upload_uuid']
      };

      if (areasHidden) formatOptions.areaTags = [];

      if (!browseDataLayer || reload) {
        var style = new OpenLayers.Style();

        style.addRules([new OpenLayers.Rule({
          symbolizer: {
            Polygon: { fillColor: '#ff0000', strokeColor: '#ff0000' },
            Line: { fillColor: '#ffff00', strokeColor: '#000000', strokeOpacity: '0.4' },
            Point: { fillColor: '#00ff00', strokeColor: '#00ff00' }
          }
        })]);

        if (browseDataLayer) browseDataLayer.destroyFeatures();

        /*
         * Modern browsers are quite happy showing far more than 100 features in
         * the data browser, so increase the limit to 2000 by default, but keep
         * it restricted to 500 for IE8 and 100 for older IEs.
         */
        var maxFeatures = 2000;

        /*@cc_on
          if (navigator.appVersion < 8) {
            maxFeatures = 100;
          } else if (navigator.appVersion < 9) {
            maxFeatures = 500;
          }
        @*/

        browseDataLayer = new OpenLayers.Layer.Vector("Data", {
          strategies: [
            new OpenLayers.Strategy.Fixed()
          ],
          protocol: new OpenLayers.Protocol.HTTP({
            url: url,
            format: new OpenLayers.Format.OSM(formatOptions),
            maxFeatures: maxFeatures,
            handleRead: customDataLoader
          }),
          projection: new OpenLayers.Projection("EPSG:4326"),
          displayInLayerSwitcher: false,
          styleMap: new OpenLayers.StyleMap({
            'default': style,
            'select': { strokeColor: '#0000ff', strokeWidth: 8 }
          })
        });
        browseDataLayer.events.register("loadend", browseDataLayer, dataLoaded );
        map.addLayer(browseDataLayer);

        browseSelectControl = new OpenLayers.Control.SelectFeature(browseDataLayer, { onSelect: onFeatureSelect });
        browseSelectControl.handlers.feature.stopDown = false;
        browseSelectControl.handlers.feature.stopUp = false;
        map.addControl(browseSelectControl);
        browseSelectControl.activate();
      } else {
        browseDataLayer.destroyFeatures();
        browseDataLayer.refresh({ url: url });
      }

      browseActiveFeature = null;
    }

    function dataLoaded() {
      if (this.map.dataLayer.active) {
        clearStatus();

        var features = [];
        for (var i = 0; i < this.features.length; i++) {
          var feature = this.features[i];
          features.push({
            typeName: featureTypeName(feature),
            url: "/browse/" + featureType(feature) + "/" + feature.osm_id,
            name: featureName(feature),
            id: feature.id
          });
        }

        browseObjectList = $(JST["templates/browse/feature_list"]({
          features: features,
          url: this.protocol.url
        }))[0];

        loadObjectList();
      }
    }

    function viewFeatureLink() {
      var feature = browseDataLayer.getFeatureById($(this).data("feature-id"));
      var layer = feature.layer;

      for (var i = 0; i < layer.selectedFeatures.length; i++) {
        var f = layer.selectedFeatures[i];
        layer.drawFeature(f, layer.styleMap.createSymbolizer(f, "default"));
      }

      onFeatureSelect(feature);

      if (browseMode != "auto") {
        map.setCenter(feature.geometry.getBounds().getCenterLonLat());
      }

      return false;
    }

    function loadObjectList() {
      $("#browse_content").html(browseObjectList);
      $("#browse_content").find("a[data-feature-id]").click(viewFeatureLink);

      return false;
    }

    function onFeatureSelect(feature) {
      // Unselect previously selected feature
      if (browseActiveFeature) {
        browseActiveFeature.layer.drawFeature(
          browseActiveFeature,
          browseActiveFeature.layer.styleMap.createSymbolizer(browseActiveFeature, "default")
        );
      }

      // Redraw in selected style
      feature.layer.drawFeature(
        feature, feature.layer.styleMap.createSymbolizer(feature, "select")
      );

      // If the current object is the list, don't innerHTML="", since that could clear it.
      if ($("#browse_content").firstChild == browseObjectList) {
        $("#browse_content").removeChild(browseObjectList);
      } else {
        $("#browse_content").empty();
      }

      $("#browse_content").html(JST["templates/browse/feature"]({
        name: featureNameSelect(feature),
        url: "/browse/" + featureType(feature) + "/" + feature.osm_id,
        attributes: feature.attributes
      }));

      $("#browse_content").find("a.browse_show_list").click(loadObjectList);
      $("#browse_content").find("a.browse_show_history").click(loadHistory);

      // Stash the currently drawn feature
      browseActiveFeature = feature;
    }

    function loadHistory() {
      $(this).attr("href", "").text(I18n.t('browse.start_rjs.wait'));

      var feature = browseActiveFeature;

      $.ajax({
        url: "/api/" + OSM.API_VERSION + "/" + featureType(feature) + "/" + feature.osm_id + "/history",
        success: function (xml) {
          if (browseActiveFeature != feature || $("#browse_content").firstChild == browseObjectList) {
            return;
          }

          $(this).remove();

          var history = [];
          var nodes = xml.getElementsByTagName(featureType(feature));
          for (var i = nodes.length - 1; i >= 0; i--) {
            history.push({
              user: nodes[i].getAttribute("user") || I18n.t('browse.start_rjs.private_user'),
              timestamp: nodes[i].getAttribute("timestamp")
            });
          }

          $("#browse_content").append(JST["templates/browse/feature_history"]({
            name: featureNameHistory(feature),
            url: "/browse/" + featureType(feature) + "/" + feature.osm_id,
            history: history
          }));
        }.bind(this)
      });

      return false;
    }

    function featureType(feature) {
      if (feature.geometry.CLASS_NAME == "OpenLayers.Geometry.Point") {
        return "node";
      } else {
        return "way";
      }
    }

    function featureTypeName(feature) {
      if (featureType(feature) == "node") {
        return I18n.t('browse.start_rjs.object_list.type.node');
      } else if (featureType(feature) == "way") {
        return I18n.t('browse.start_rjs.object_list.type.way');
      }
    }

    function featureName(feature) {
      var lang = $('html').attr('lang');
      if (feature.attributes['name:' + lang]) {
        return feature.attributes['name:' + lang];
      } else if (feature.attributes.name) {
        return feature.attributes.name;
      } else {
        return feature.osm_id;
      }
    }

    function featureNameSelect(feature) {
      var lang = $('html').attr('lang');
      if (feature.attributes['name:' + lang]) {
        return feature.attributes['name:' + lang];
      } else if (feature.attributes.name) {
        return feature.attributes.name;
      } else if (featureType(feature) == "node") {
        return I18n.t("browse.start_rjs.object_list.selected.type.node", { id: feature.osm_id });
      } else if (featureType(feature) == "way") {
        return I18n.t("browse.start_rjs.object_list.selected.type.way", { id: feature.osm_id });
      }
    }

    function featureNameHistory(feature) {
      var lang = $('html').attr('lang');
      if (feature.attributes['name:' + lang]) {
        return feature.attributes['name:' + lang];
      } else if (feature.attributes.name) {
        return feature.attributes.name;
      } else if (featureType(feature) == "node") {
        return I18n.t("browse.start_rjs.object_list.history.type.node", { id: feature.osm_id });
      } else if (featureType(feature) == "way") {
        return I18n.t("browse.start_rjs.object_list.history.type.way", { id: feature.osm_id });
      }
    }

    function setStatus(status) {
      $("#browse_status").html(status);
      $("#browse_status").show();
    }

    function clearStatus() {
      $("#browse_status").html("");
      $("#browse_status").hide();
    }
  }
});