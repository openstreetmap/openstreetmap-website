//= require jquery-simulate/jquery.simulate

OSM.History = function (map) {
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

  function getBBoxParameter() {
    return map.getBounds().wrap().toBBoxString();
  }

  function getStoreNameAndKey() {
    if (window.location.pathname === "/history/friends") {
      return null; // depends on current login - don't store for now
    } else if (window.location.pathname === "/history/nearby") {
      return null; // depends on current login - don't store for now
    } else if (window.location.pathname === "/history") {
      return ["history-place", getBBoxParameter()]; // separate store for places because bbox is too volatile
    } else {
      return ["history-user", window.location.pathname]; // has display_name inside pathname
    }
  }

  function loadStore(storeName) {
    var requiredSchema = 1;
    var storeString = sessionStorage[storeName];
    var store = {
      schema: requiredSchema,
      items: []
    };
    try {
      if (storeString) {
        var readStore = JSON.parse(storeString);
        if (readStore.schema === requiredSchema) {
          store = readStore;
        }
      }
    } catch (ex) {
      // reset store if it's damaged
    }
    return store;
  }

  function saveStore(storeName, store) {
    sessionStorage[storeName] = JSON.stringify(store);
  }

  function getStoreItem(store, storeKey) {
    var maxStoreSize = 10;
    var storeItem;
    for (var i = 0; i < store.items.length; i++) {
      if (store.items[i].key !== storeKey) continue;
      storeItem = store.items[i];
      store.items.splice(i, 1);
      store.items.unshift(storeItem);
      return storeItem;
    }
    storeItem = {
      key: storeKey,
      // TODO timestamp - need to receive it from fn doing request
      lists: []
    };
    store.items.splice(maxStoreSize - 1);
    store.items.unshift(storeItem);
    return storeItem;
  }

  function saveDataToStore(html, rewrite) {
    var storeNameAndKey = getStoreNameAndKey();
    if (!storeNameAndKey) return;
    var storeName = storeNameAndKey[0];
    var storeKey = storeNameAndKey[1];
    var store = loadStore(storeName);
    var storeItem = getStoreItem(store, storeKey);
    if (rewrite) storeItem.lists = [];
    storeItem.lists.push(html);
    saveStore(storeName, store);
  }

  function loadDataFromStore() {
    var storeNameAndKey = getStoreNameAndKey();
    if (!storeNameAndKey) return false;
    var storeName = storeNameAndKey[0];
    var storeKey = storeNameAndKey[1];
    var store = loadStore(storeName);
    var storeItem = getStoreItem(store, storeKey);
    if (storeItem.lists.length === 0) return false;
    for (var i = 0; i < storeItem.lists.length; i++) {
      var html = storeItem.lists[i];
      if (i === 0) {
        displayFirstChangesets(html);
      } else {
        displayMoreChangesets(html);
      }
    }
    return true;
  }

  function update() {
    var data = { list: "1" };

    if (window.location.pathname === "/history") {
      data.bbox = getBBoxParameter();
      var feedLink = $("link[type=\"application/atom+xml\"]"),
          feedHref = feedLink.attr("href").split("?")[0];
      feedLink.attr("href", feedHref + "?bbox=" + data.bbox);
    }

    var loadedDataFromStore = loadDataFromStore();
    if (!loadedDataFromStore) {
      $.ajax({
        url: window.location.pathname,
        method: "GET",
        data: data,
        success: function (html) {
          saveDataToStore(html, true);
          displayFirstChangesets(html);
          updateMap();
        }
      });
    }
  }

  function loadMore(e) {
    e.preventDefault();
    e.stopPropagation();

    var div = $(this).parents(".changeset_more");

    $(this).hide();
    div.find(".loader").show();

    $.get($(this).attr("href"), function (html) {
      saveDataToStore(html, false);
      displayMoreChangesets(html);
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
