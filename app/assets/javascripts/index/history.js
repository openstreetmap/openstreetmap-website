//= require jquery-simulate/jquery.simulate

OSM.History = function (map) {
  var page = {};

  $("#sidebar_content")
    .on("click", ".changeset_more a", loadMoreChangesets)
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
      clickChangeset(e.layer.id, e.originalEvent);
    });

  group.getLayerId = function (layer) {
    return layer.id;
  };

  function highlightChangeset(id) {
    var layer = group.getLayer(id);
    if (layer) layer.setStyle({ fillOpacity: 0.3, color: "#FF6600", weight: 3 });
    $("#changeset_" + id).addClass("selected");
  }

  function unHighlightChangeset(id) {
    var layer = group.getLayer(id);
    if (layer) layer.setStyle({ fillOpacity: 0, color: "#FF9500", weight: 2 });
    $("#changeset_" + id).removeClass("selected");
  }

  function clickChangeset(id, e) {
    $("#changeset_" + id).find("a.changeset_id").simulate("click", e);
  }

  function displayFirstChangesets(html) {
    $("#sidebar_content .changesets").html(html);
  }

  function displayMoreChangesets(html) {
    $("#sidebar_content .changeset_more").replaceWith(html);
    var oldList = $("#sidebar_content .changesets ol").first();
    var newList = oldList.next("ol");
    newList.children().appendTo(oldList);
    newList.remove();
  }

  function loadFirstChangesets() {
    var data = prepareAjaxData();

    if (data.bbox) {
      var feedLink = $("link[type=\"application/atom+xml\"]"),
          feedHref = feedLink.attr("href").split("?")[0];
      feedLink.attr("href", feedHref + "?bbox=" + data.bbox);
    }

    $.ajax({
      url: window.location.pathname,
      data: data,
      success: function (html) {
        displayFirstChangesets(html);
        updateMap();
      }
    });
  }

  function loadMoreChangesets(e) {
    e.preventDefault();
    e.stopPropagation();

    var div = $(this).parents(".changeset_more");

    $(this).hide();
    div.find(".loader").show();

    var data = prepareAjaxData();

    $.ajax({
      url: $(this).attr("href"),
      data: data,
      success: function (html) {
        displayMoreChangesets(html);
        updateMap();
      }
    });
  }

  function prepareAjaxData() {
    var data = { list: "1" };

    if (isPlaceHistory()) {
      data.bbox = map.getBounds().wrap().toBBoxString();
    }

    return data;
  }

  function isPlaceHistory() {
    return window.location.pathname.indexOf("/history") === 0;
  }

  var changesets = [];

  function updateBounds() {
    group.clearLayers();

    changesets.forEach(function (changeset) {
      var bottomLeft = map.project(L.latLng(changeset.bbox.minlat, changeset.bbox.minlon)),
          topRight = map.project(L.latLng(changeset.bbox.maxlat, changeset.bbox.maxlon)),
          width = topRight.x - bottomLeft.x,
          height = bottomLeft.y - topRight.y,
          minSize = 20; // Min width/height of changeset in pixels

      if (width < minSize) {
        bottomLeft.x -= ((minSize - width) / 2);
        topRight.x += ((minSize - width) / 2);
      }

      if (height < minSize) {
        bottomLeft.y += ((minSize - height) / 2);
        topRight.y -= ((minSize - height) / 2);
      }

      changeset.bounds = L.latLngBounds(map.unproject(bottomLeft),
                                        map.unproject(topRight));
    });

    changesets.sort(function (a, b) {
      return b.bounds.getSize() - a.bounds.getSize();
    });

    for (var i = 0; i < changesets.length; ++i) {
      var changeset = changesets[i],
          rect = L.rectangle(changeset.bounds,
                             { weight: 2, color: "#FF9500", opacity: 1, fillColor: "#FFFFAF", fillOpacity: 0 });
      rect.id = changeset.id;
      rect.addTo(group);
    }
  }

  function updateMap() {
    changesets = $("[data-changeset]").map(function (index, element) {
      return $(element).data("changeset");
    }).get().filter(function (changeset) {
      return changeset.bbox;
    });

    updateBounds();

    if (!isPlaceHistory()) {
      var bounds = group.getBounds();
      if (bounds.isValid()) map.fitBounds(bounds);
    }
  }

  function updatePlaceHistoryBecauseOfMapMovement() {
    if (window.location.pathname !== "/history") {
      OSM.router.replace("/history" + window.location.hash);
    }
    loadFirstChangesets();
  }

  page.pushstate = page.popstate = function (path) {
    $("#history_tab").addClass("current");
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map.addLayer(group);

    if (isPlaceHistory()) {
      map.on("moveend", updatePlaceHistoryBecauseOfMapMovement);
    }

    map.on("zoomend", updateBounds);

    loadFirstChangesets();
  };

  page.unload = function () {
    map.removeLayer(group);
    map.off("moveend", updatePlaceHistoryBecauseOfMapMovement);

    $("#history_tab").removeClass("current");
  };

  return page;
};
