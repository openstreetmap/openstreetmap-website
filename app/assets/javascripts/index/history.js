//= require jquery.simulate

OSM.History = function (map) {
  var page = {};

  $("#sidebar_content")
    .on("click", ".changeset_more a", loadMore)
    .on("mouseover", "[data-changeset]", function () {
      highlightChangeset($(this).data("changeset").id);
    })
    .on("mouseout", "[data-changeset]", function () {
      unHighlightChangeset($(this).data("changeset").id);
    })
    .on("mousedown", "[data-changeset]", function () {
      var moved = false;
      $(this)
        .one("click", function (e) {
          if (!moved && !$(e.target).is("a")) {
            clickChangeset($(this).data("changeset").id, e);
          }
        })
        .one("mousemove", function () {
          moved = true;
        });
    });

  var group = L.featureGroup()
    .on("mouseover", function (e) {
      highlightChangeset(e.layer.id);
    })
    .on("mouseout", function (e) {
      unHighlightChangeset(e.layer.id);
    })
    .on("click", function (e) {
      clickChangeset(e.layer.id, e);
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

  function update() {
    var data = { list: "1" };

    if (window.location.pathname === "/history") {
      data.bbox = map.getBounds().wrap().toBBoxString();
    }

    $.ajax({
      url: window.location.pathname,
      method: "GET",
      data: data,
      success: function (html) {
        $("#sidebar_content .changesets").html(html);
        updateMap();
      }
    });

    var feedLink = $("link[type=\"application/atom+xml\"]"),
        feedHref = feedLink.attr("href").split("?")[0];

    feedLink.attr("href", feedHref + "?bbox=" + data.bbox);
  }

  function loadMore(e) {
    e.preventDefault();
    e.stopPropagation();

    var div = $(this).parents(".changeset_more");

    $(this).hide();
    div.find(".loader").show();

    $.get($(this).attr("href"), function (data) {
      div.replaceWith(data);
      updateMap();
    });
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

    if (window.location.pathname !== "/history") {
      var bounds = group.getBounds();
      if (bounds.isValid()) map.fitBounds(bounds);
    }
  }

  page.pushstate = page.popstate = function (path) {
    $("#history_tab").addClass("current");
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map.addLayer(group);

    if (window.location.pathname === "/history") {
      map.on("moveend", update);
    }

    map.on("zoomend", updateBounds);

    update();
  };

  page.unload = function () {
    map.removeLayer(group);
    map.off("moveend", update);

    $("#history_tab").removeClass("current");
  };

  return page;
};
