OSM.History = function(map) {
  var page = {};

  $("#sidebar_content")
    .on("click", ".changeset_more a", loadMore)
    .on("mouseover", "[data-changeset]", function () {
      highlightChangeset($(this).data("changeset").id);
    })
    .on("mouseout", "[data-changeset]", function () {
      unHighlightChangeset($(this).data("changeset").id);
    });

  var group = L.featureGroup()
    .on("mouseover", function (e) {
      highlightChangeset(e.layer.id);
    })
    .on("mouseout", function (e) {
      unHighlightChangeset(e.layer.id);
    })
    .on("click", function (e) {
      clickChangeset(e.layer.id);
    });

  group.getLayerId = function(layer) {
    return layer.id;
  };

  function highlightChangeset(id) {
    group.getLayer(id).setStyle({fillOpacity: 0.3});
    $("#changeset_" + id).addClass("selected");
  }

  function unHighlightChangeset(id) {
    group.getLayer(id).setStyle({fillOpacity: 0});
    $("#changeset_" + id).removeClass("selected");
  }

  function clickChangeset(id) {
    OSM.router.route($("#changeset_" + id).find(".changeset_id").attr("href"));
  }

  function loadData() {
    var data = {};

    if (window.location.pathname === '/history') {
      data = {bbox: map.getBounds().wrap().toBBoxString()};
    }

    $.ajax({
      url: window.location.pathname,
      method: "GET",
      data: data,
      success: function(html, status, xhr) {
        $('#sidebar_content .changesets').html(html);
        updateMap();
      }
    });
  }

  function loadMore(e) {
    e.preventDefault();
    e.stopPropagation();

    var div = $(this).parents(".changeset_more");

    $(this).hide();
    div.find(".loader").show();

    $.get($(this).attr("href"), function(data) {
      div.replaceWith(data);
      updateMap();
    });
  }

  function updateMap() {
    group.clearLayers();

    var changesets = [];

    $("[data-changeset]").each(function () {
      var changeset = $(this).data('changeset');
      if (changeset.bbox) {
        changeset.bounds = L.latLngBounds(
          [changeset.bbox.minlat, changeset.bbox.minlon],
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
          {weight: 2, color: "#FF9500", opacity: 1, fillColor: "#FFFFBF", fillOpacity: 0});
      rect.id = changeset.id;
      rect.addTo(group);
    }

    if (window.location.pathname !== '/history') {
      var bounds = group.getBounds();
      if (bounds.isValid()) map.fitBounds(bounds);
    }
  }

  page.pushstate = page.popstate = function(path) {
    $("#history_tab").addClass("current");
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function() {
    map.addLayer(group);

    if (window.location.pathname === '/history') {
      map.on("moveend", loadData)
    }

    loadData();
  };

  page.unload = function() {
    map.removeLayer(group);

    if (window.location.pathname === '/history') {
      map.off("moveend", loadData)
    }

    $("#history_tab").removeClass("current");
  };

  return page;
};
