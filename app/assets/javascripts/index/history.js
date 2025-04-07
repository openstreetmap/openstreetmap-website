//= require jquery-simulate/jquery.simulate
//= require ./history-changesets-layer

OSM.History = function (map) {
  const page = {};

  $("#sidebar_content")
    .on("click", ".changeset_more a", loadMoreChangesets)
    .on("mouseover", "[data-changeset]", function () {
      highlightChangeset($(this).data("changeset").id);
    })
    .on("mouseout", "[data-changeset]", function () {
      unHighlightChangeset($(this).data("changeset").id);
    });

  const changesetsLayer = new OSM.HistoryChangesetsLayer()
    .on("mouseover", function (e) {
      highlightChangeset(e.layer.id);
    })
    .on("mouseout", function (e) {
      unHighlightChangeset(e.layer.id);
    })
    .on("click", function (e) {
      clickChangeset(e.layer.id, e.originalEvent);
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

    let ignoreIntersectionEvents = true;

    changesetIntersectionObserver = new IntersectionObserver((entries) => {
      if (ignoreIntersectionEvents) {
        ignoreIntersectionEvents = false;
        return;
      }

      let closestTargetToTop,
          closestDistanceToTop = Infinity,
          closestTargetToBottom,
          closestDistanceToBottom = Infinity;

      for (const entry of entries) {
        if (entry.isIntersecting) continue;

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

  function highlightChangeset(id) {
    changesetsLayer.highlightChangeset(id);
    $("#changeset_" + id).addClass("selected");
  }

  function unHighlightChangeset(id) {
    changesetsLayer.unHighlightChangeset(id);
    $("#changeset_" + id).removeClass("selected");
  }

  function clickChangeset(id, e) {
    $("#changeset_" + id).find("a.changeset_id").simulate("click", e);
  }

  function displayFirstChangesets(html) {
    $("#sidebar_content .changesets").html(html);

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
      $(this).prop("hash", OSM.formatHash({
        center: map.getCenter(),
        zoom: map.getZoom()
      }));
    });
  }

  function loadFirstChangesets() {
    const data = new URLSearchParams();

    disableChangesetIntersectionObserver();

    if (location.pathname === "/history") {
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

        updateMap();
      });
  }

  function loadMoreChangesets(e) {
    e.preventDefault();
    e.stopPropagation();

    const div = $(this).parents(".changeset_more");

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

        updateMap();
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

  function reloadChangesetsBecauseOfMapMovement() {
    OSM.router.replace("/history" + window.location.hash);
    loadFirstChangesets();
  }

  function updateBounds() {
    changesetsLayer.updateChangesetShapes(map);
  }

  function updateMap() {
    const changesets = $("[data-changeset]").map(function (index, element) {
      return $(element).data("changeset");
    }).get().filter(function (changeset) {
      return changeset.bbox;
    });

    changesetsLayer.updateChangesets(map, changesets);

    if (location.pathname !== "/history") {
      const bounds = changesetsLayer.getBounds();
      if (bounds.isValid()) map.fitBounds(bounds);
    }
  }

  page.pushstate = page.popstate = function (path) {
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    map.addLayer(changesetsLayer);

    if (location.pathname === "/history") {
      map.on("moveend", reloadChangesetsBecauseOfMapMovement);
    }

    map.on("zoomend", updateBounds);

    loadFirstChangesets();
  };

  page.unload = function () {
    map.removeLayer(changesetsLayer);
    map.off("moveend", reloadChangesetsBecauseOfMapMovement);
    map.off("zoomend", updateBounds);
    disableChangesetIntersectionObserver();
  };

  return page;
};
