//= require jquery-simulate/jquery.simulate

OSM.History = function (map) {
  const page = {};

  $("#sidebar_content")
    .on("click", ".changeset_more a", loadMore)
    .on("mouseover", "[data-changeset]", function () {
      highlightChangeset($(this).data("changeset").id);
    })
    .on("mouseout", "[data-changeset]", function () {
      unHighlightChangeset($(this).data("changeset").id);
    });

  const group = L.featureGroup()
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
    const layer = group.getLayer(id);
    if (layer) layer.setStyle({ fillOpacity: 0.3, color: "#FF6600", weight: 3 });
    $("#changeset_" + id).addClass("selected");
  }

  function unHighlightChangeset(id) {
    const layer = group.getLayer(id);
    if (layer) layer.setStyle({ fillOpacity: 0, color: "#FF9500", weight: 2 });
    $("#changeset_" + id).removeClass("selected");
  }

  function clickChangeset(id, e) {
    $("#changeset_" + id).find("a.changeset_id").simulate("click", e);
  }

  function displayFirstChangesets(html) {
    $("#sidebar_content .changesets").html(html);
  }

  function displayMoreChangesets(div, html) {
    const sidebar = $("#sidebar")[0];
    const previousScrollHeightMinusTop = sidebar.scrollHeight - sidebar.scrollTop;

    const oldList = $("#sidebar_content .changesets ol");

    div.replaceWith(html);

    const prevNewList = oldList.prevAll("ol");
    if (prevNewList.length) {
      prevNewList.next(".changeset_more").remove();
      prevNewList.children().prependTo(oldList);
      prevNewList.remove();

      // restore scroll position only if prepending
      sidebar.scrollTop = sidebar.scrollHeight - previousScrollHeightMinusTop;
    }

    const nextNewList = oldList.nextAll("ol");
    if (nextNewList.length) {
      nextNewList.prev(".changeset_more").remove();
      nextNewList.children().appendTo(oldList);
      nextNewList.remove();
    }
  }

  function update() {
    const data = new URLSearchParams();
    const params = new URLSearchParams(location.search);

    if (location.pathname === "/history") {
      data.set("bbox", map.getBounds().wrap().toBBoxString());
      const feedLink = $("link[type=\"application/atom+xml\"]"),
            feedHref = feedLink.attr("href").split("?")[0];
      feedLink.attr("href", feedHref + "?" + data);
    }

    data.set("list", "1");

    if (params.has("before")) {
      data.set("before", params.get("before"));
    }
    if (params.has("after")) {
      data.set("after", params.get("after"));
    }

    fetch(location.pathname + "?" + data)
      .then(response => response.text())
      .then(function (html) {
        displayFirstChangesets(html);
        updateMap();
      });
  }

  function loadMore(e) {
    e.preventDefault();
    e.stopPropagation();

    const div = $(this).parents(".changeset_more");

    $(this).hide();
    div.find(".loader").show();

    $.get($(this).attr("href"), function (html) {
      displayMoreChangesets(div, html);
      updateMap();
    });
  }

  let changesets = [];

  function updateBounds() {
    group.clearLayers();

    for (const changeset of changesets) {
      const bottomLeft = map.project(L.latLng(changeset.bbox.minlat, changeset.bbox.minlon)),
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
    }

    changesets.sort(function (a, b) {
      return b.bounds.getSize() - a.bounds.getSize();
    });

    for (const changeset of changesets) {
      const rect = L.rectangle(changeset.bounds,
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

    if (location.pathname !== "/history") {
      const bounds = group.getBounds();
      if (bounds.isValid()) map.fitBounds(bounds);
    }
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map.addLayer(group);

    if (location.pathname === "/history") {
      map.on("moveend", update);
    }

    map.on("zoomend", updateBounds);

    update();
  };

  page.unload = function () {
    map.removeLayer(group);
    map.off("moveend", update);
    map.off("zoomend", updateBounds);
  };

  return page;
};
