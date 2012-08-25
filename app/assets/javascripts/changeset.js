$(document).ready(function () {
  var rects = {};
  var map = createMap("changeset_list_map");
  var group = L.featureGroup().addTo(map);

  $("[data-changeset]").each(function () {
    var changeset = $(this).data('changeset');
    if (changeset.bbox) {
      var rect = L.rectangle([[changeset.bbox.minlat, changeset.bbox.minlon],
                              [changeset.bbox.maxlat, changeset.bbox.maxlon]],
                             {weight: 2, color: "#ee9900", fillColor: "#ffff55", fillOpacity: 0});
      rect.id = changeset.id;
      rects[changeset.id] = rect;
      rect.addTo(group);
    }
  });

  function highlightChangeset(id) {
    rects[id].setStyle({fillOpacity: 0.5});
    $("#tr-changeset-" + id).addClass("selected");
  }

  function unHighlightChangeset(id) {
    rects[id].setStyle({fillOpacity: 0});
    $("#tr-changeset-" + id).removeClass("selected");
  }

  group.on({
    mouseover: function (e) {
      highlightChangeset(e.layer.id);
    },
    mouseout: function (e) {
      unHighlightChangeset(e.layer.id);
    }
  });

  $("[data-changeset]").on({
    mouseover: function () {
      highlightChangeset($(this).data("changeset").id);
    },
    mouseout: function () {
      unHighlightChangeset($(this).data("changeset").id);
    }
  });

  var params = OSM.mapParams();
  if (params.bbox) {
    map.fitBounds([[params.minlat, params.minlon],
                   [params.maxlat, params.maxlon]]);
  } else {
    map.fitBounds(group.getBounds());
  }
});
