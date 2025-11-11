//= require ./history-changesets-layer

OSM.History = function (map) {
  const page = {};

  $("#sidebar_content")
    .on("click", ".changeset_more a", loadMoreChangesets)
    .on("mouseover", "[data-changeset]", function () {
      toggleChangesetHighlight($(this).data("changeset").id, true);
    })
    .on("mouseout", "[data-changeset]", function () {
      toggleChangesetHighlight($(this).data("changeset").id, false);
    });

  let inZoom = false;
  map.on("zoomstart", () => inZoom = true);
  map.on("zoomend", () => inZoom = false);

  const changesetsLayer = new OSM.HistoryChangesetsLayer()
    .on("mouseover", function (e) {
      if (inZoom) return;
      toggleChangesetHighlight(e.layer.id, true);
    })
    .on("mouseout", function (e) {
      if (inZoom) return;
      toggleChangesetHighlight(e.layer.id, false);
    })
    .on("requestscrolltochangeset", function (e) {
      const [item] = $(`#changeset_${e.id}`);
      item?.scrollIntoView({ block: "nearest", behavior: "smooth" });
    });

  let changesetIntersectionObserver;

  function disableChangesetIntersectionObserver() {
    if (changesetIntersectionObserver) {
      changesetIntersectionObserver.disconnect();
      changesetIntersectionObserver = null;
    }
  }

  function enableChangesetIntersectionObserver() {
    disableChangesetIntersectionObserver();
    if (!window.IntersectionObserver) return;

    let keepInitialLocation = true;
    let itemsInViewport = $();

    changesetIntersectionObserver = new IntersectionObserver((entries) => {
      let closestTargetToTop,
          closestDistanceToTop = Infinity,
          closestTargetToBottom,
          closestDistanceToBottom = Infinity;

      for (const entry of entries) {
        const id = $(entry.target).data("changeset")?.id;

        if (entry.isIntersecting) {
          itemsInViewport = itemsInViewport.add(entry.target);
          if (id) changesetsLayer.setChangesetSidebarRelativePosition(id, 0);
          continue;
        } else {
          itemsInViewport = itemsInViewport.not(entry.target);
        }

        const distanceToTop = entry.rootBounds.top - entry.boundingClientRect.bottom;
        const distanceToBottom = entry.boundingClientRect.top - entry.rootBounds.bottom;

        if (distanceToTop >= 0 && distanceToTop < closestDistanceToTop) {
          closestDistanceToTop = distanceToTop;
          closestTargetToTop = entry.target;
        }
        if (distanceToBottom >= 0 && distanceToBottom <= closestDistanceToBottom) {
          closestDistanceToBottom = distanceToBottom;
          closestTargetToBottom = entry.target;
        }
      }

      itemsInViewport.first().prevAll().each(function () {
        const id = $(this).data("changeset")?.id;
        if (id) changesetsLayer.setChangesetSidebarRelativePosition(id, 1);
      });
      itemsInViewport.last().nextAll().each(function () {
        const id = $(this).data("changeset")?.id;
        if (id) changesetsLayer.setChangesetSidebarRelativePosition(id, -1);
      });

      changesetsLayer.updateChangesetsOrder();

      if (keepInitialLocation) {
        keepInitialLocation = false;
        return;
      }

      if (closestTargetToTop && closestDistanceToTop < closestDistanceToBottom) {
        const id = $(closestTargetToTop).data("changeset")?.id;
        if (id) {
          OSM.router.replace(location.pathname + "?" + new URLSearchParams({ before: id }) + location.hash);
        }
      } else if (closestTargetToBottom) {
        const id = $(closestTargetToBottom).data("changeset")?.id;
        if (id) {
          OSM.router.replace(location.pathname + "?" + new URLSearchParams({ after: id }) + location.hash);
        }
      }
    }, { root: $("#sidebar")[0] });

    $("#sidebar_content .changesets ol").children().each(function () {
      changesetIntersectionObserver.observe(this);
    });
  }

  function toggleChangesetHighlight(id, state) {
    changesetsLayer.toggleChangesetHighlight(id, state);
    $("#sidebar_content .changesets ol li").removeClass("selected");
    if (state) {
      $("#changeset_" + id).addClass("selected");
    }
  }

  function displayFirstChangesets(html) {
    $("#sidebar_content .changesets").html(html);

    $("#sidebar_content .changesets ol")
      .before($("<div class='changeset-color-hint-bar opacity-75 sticky-top changeset-above-sidebar-viewport'>"))
      .after($("<div class='changeset-color-hint-bar opacity-75 sticky-bottom changeset-below-sidebar-viewport'>"));

    if (location.pathname === "/history") {
      setPaginationMapHashes();
    }
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

    if (location.pathname === "/history") {
      setPaginationMapHashes();
    }
  }

  function setPaginationMapHashes() {
    $("#sidebar .pagination a").each(function () {
      $(this).prop("hash", OSM.formatHash(map));
    });
  }

  function loadFirstChangesets() {
    const data = new URLSearchParams();
    const isHistory = location.pathname === "/history";

    disableChangesetIntersectionObserver();

    if (isHistory) {
      setBboxFetchData(data);
      const feedLink = $("link[type=\"application/atom+xml\"]"),
            feedHref = feedLink.attr("href").split("?")[0];
      feedLink.attr("href", feedHref + "?" + data);
    }

    setListFetchData(data, location);

    fetch(location.pathname + "?" + data)
      .then(response => response.text())
      .then(function (html) {
        displayFirstChangesets(html);
        enableChangesetIntersectionObserver();

        if (data.has("before")) {
          const [firstItem] = $("#sidebar_content .changesets ol").children().first();
          firstItem?.scrollIntoView();
        } else if (data.has("after")) {
          const [lastItem] = $("#sidebar_content .changesets ol").children().last();
          lastItem?.scrollIntoView(false);
        } else {
          const [sidebar] = $("#sidebar");
          sidebar.scrollTop = 0;
        }

        updateMap(isHistory);
      });
  }

  function loadMoreChangesets(e) {
    e.preventDefault();
    e.stopPropagation();

    const div = $(this).parents(".changeset_more");
    const isHistory = location.pathname === "/history";

    div.find(".pagination").addClass("invisible");
    div.find("[hidden]").prop("hidden", false);

    const data = new URLSearchParams();

    if (location.pathname === "/history") {
      setBboxFetchData(data);
    }

    const url = new URL($(this).attr("href"), location);
    setListFetchData(data, url);

    fetch(url.pathname + "?" + data)
      .then(response => response.text())
      .then(function (html) {
        displayMoreChangesets(div, html);
        enableChangesetIntersectionObserver();

        updateMap(isHistory);
      });
  }

  function setBboxFetchData(data) {
    const crs = map.options.crs;
    const sw = map.getBounds().getSouthWest();
    const ne = map.getBounds().getNorthEast();
    const swClamped = crs.unproject(crs.project(sw));
    const neClamped = crs.unproject(crs.project(ne));

    if (sw.lat >= swClamped.lat || ne.lat <= neClamped.lat || ne.lng - sw.lng < 360) {
      data.set("bbox", map.getBounds().toBBoxString());
    }
  }

  function setListFetchData(data, url) {
    const params = new URLSearchParams(url.search);

    data.set("list", "1");

    if (params.has("before")) {
      data.set("before", params.get("before"));
    }
    if (params.has("after")) {
      data.set("after", params.get("after"));
    }
  }

  function moveEndListener() {
    if (location.pathname === "/history") {
      OSM.router.replace("/history" + window.location.hash);
      loadFirstChangesets();
    } else {
      $("#sidebar_content .changesets ol li").removeClass("selected");
      changesetsLayer.updateChangesetsGeometry(map);
    }
  }

  function zoomEndListener() {
    $("#sidebar_content .changesets ol li").removeClass("selected");
    changesetsLayer.updateChangesetsGeometry(map);
  }

  function updateMap(isHistory) {
    const changesets = $("[data-changeset]").map(function (index, element) {
      return $(element).data("changeset");
    }).get().filter(function (changeset) {
      return changeset.bbox;
    });

    changesetsLayer.updateChangesets(map, changesets);

    if (!isHistory) {
      const bounds = changesetsLayer.getBounds();
      if (bounds.isValid()) map.fitBounds(bounds);
    }
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map.addLayer(changesetsLayer);
    map.on("moveend", moveEndListener);
    map.on("zoomend", zoomEndListener);
    loadFirstChangesets();
  };

  page.unload = function () {
    map.removeLayer(changesetsLayer);
    map.off("moveend", moveEndListener);
    map.off("zoomend", zoomEndListener);
    disableChangesetIntersectionObserver();
  };

  return page;
};
