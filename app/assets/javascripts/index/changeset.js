OSM.ChangesetList = function(map) {
  var page = {};

  var group = L.featureGroup()
    .on({
      mouseover: function (e) {
        highlightChangeset(e.layer.id);
      },
      mouseout: function (e) {
        unHighlightChangeset(e.layer.id);
      }
    });

  group.getLayerId = function(layer) {
    return layer.id;
  };

  function highlightChangeset(id) {
    group.getLayer(id).setStyle({fillOpacity: 0.5});
    $("#changeset_" + id).addClass("selected");
  }

  function unHighlightChangeset(id) {
    group.getLayer(id).setStyle({fillOpacity: 0});
    $("#changeset_" + id).removeClass("selected");
  }

  page.pushstate = page.popstate = function(path) {
    $("#history_tab").addClass("current");
    $('#sidebar_content').load(path, page.load);
  };

  page.load = function() {
    map.addLayer(group);

    var changesets = [];
    $("[data-changeset]").each(function () {
      var changeset = $(this).data('changeset');
      if (changeset.bbox) {
        changeset.bounds = L.latLngBounds([changeset.bbox.minlat, changeset.bbox.minlon],
          [changeset.bbox.maxlat, changeset.bbox.maxlon]);
        changesets.push(changeset);
      }
    });

    changesets.sort(function (a, b) {
      return b.bounds.getSize() - a.bounds.getSize();
    });

    for (var i = 0; i < changesets.length; ++i) {
      var changeset = changesets[i],
        rect = L.rectangle(changeset.bounds,
          {weight: 2, color: "#ee9900", fillColor: "#ffff55", fillOpacity: 0});
      rect.id = changeset.id;
      rect.addTo(group);
    }

    $("[data-changeset]").on({
      mouseover: function () {
        highlightChangeset($(this).data("changeset").id);
      },
      mouseout: function () {
        unHighlightChangeset($(this).data("changeset").id);
      }
    });
  };

  page.unload = function() {
    map.removeLayer(group);
    group.clearLayers();
    $("#history_tab").removeClass("current");
  };

  return page;
};
