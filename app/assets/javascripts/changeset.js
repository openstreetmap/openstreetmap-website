$(document).ready(function () {
  var highlight;

  function highlightChangeset(id) {
    var feature = vectors.getFeatureByFid(id);
    var bounds = feature.geometry.getBounds();

    if (bounds.containsBounds(map.getExtent())) {
      bounds = map.getExtent().scale(1.1);
    }

    if (highlight) vectors.removeFeatures(highlight);

    highlight = new OpenLayers.Feature.Vector(bounds.toGeometry(), {}, {
      strokeWidth: 2,
      strokeColor: "#ee9900",
      fillColor: "#ffff55",
      fillOpacity: 0.5
    });

    vectors.addFeatures(highlight);

    $("#tr-changeset-" + id).addClass("selected");
  }

  function unHighlightChangeset(id) {
    vectors.removeFeatures(highlight);

    $("#tr-changeset-" + id).removeClass("selected");
  }

  var map = createMap("changeset_list_map", {
    controls: [
      new OpenLayers.Control.Navigation(),
      new OpenLayers.Control.Zoom(),
      new OpenLayers.Control.SimplePanZoom()
    ]
  });

  var bounds = new OpenLayers.Bounds();

  $("[data-changeset]").each(function () {
    var changeset = $(this).data('changeset');
    if (changeset.bbox) {
      var bbox = new OpenLayers.Bounds(changeset.bbox.minlon, changeset.bbox.minlat, changeset.bbox.maxlon, changeset.bbox.maxlat);

      bounds.extend(bbox);

      addBoxToMap(bbox, changeset.id, true);
    }
  });

  vectors.events.on({
    "featureselected": function(feature) {
      highlightChangeset(feature.feature.fid);
    },
    "featureunselected": function(feature) {
      unHighlightChangeset(feature.feature.fid);
    }
  });

  var selectControl = new OpenLayers.Control.SelectFeature(vectors, {
    multiple: false,
    hover: true
  });
  map.addControl(selectControl);
  selectControl.activate();

  var params = OSM.mapParams();
  if (params.bbox) {
    map.zoomToExtent(proj(new OpenLayers.Bounds(params.minlon, params.minlat, params.maxlon, params.maxlat)));
  } else {
    map.zoomToExtent(proj(bounds));
  }

  $("[data-changeset]").mouseover(function() {
    highlightChangeset($(this).data("changeset").id);
  });

  $("[data-changeset]").mouseout(function() {
    unHighlightChangeset($(this).data("changeset").id);
  });
});
