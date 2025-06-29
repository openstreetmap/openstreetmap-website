(function () {
  $(document).on("click", "a[href='#versions-navigation-active-page-item']", function (e) {
    scrollToActiveVersion();
    $("#versions-navigation-active-page-item a.page-link").trigger("focus");
    e.preventDefault();
  });

  OSM.Element = function (map, type) {
    const page = {};
    let scrollStartObserver, scrollEndObserver;
    let abortController = null;

    function markWikidataLinkAsExplainable(i, link) {
      const qid = link.href.match(/Q\d+/)?.at();
      if (!qid) {
        $(link).addClass("unexplainable");
        return;
      }
      $(link).addClass("explainable")
        .one("click", function (e) {
          e.preventDefault();
          explainWikidataLink(link, qid);
        });
    }

    function explainWikidataLink(link, qid) {
      const langs = [...new Set([...OSM.preferred_languages.map(l => l.toLowerCase()), "en"])];
      const wikis = [...new Set(langs.map(l => l.split("-")[0] + "wiki"))];
      fetch(OSM.WIKIDATA_URL + "?" + new URLSearchParams({
        action: "wbgetentities",
        format: "json",
        origin: "*",
        ids: qid,
        props: "labels|sitelinks|claims|descriptions",
        languages: langs.join("|"),
        sitefilter: wikis.join("|")
      }), { signal: abortController.signal })
        .then(response => response.ok ? response.json() : Promise.reject(response))
        .then(({ entities }) => {
          if (!entities || !entities[qid]) return Promise.reject(entities);
          const entity = entities[qid];
          const localizedProperty = (property, langs) => langs.reduce((out, lang) => out ?? entity[property][lang], null);
          const data = {
            link,
            qid,
            label: localizedProperty("labels", langs)?.value,
            icon: ["P8972", "P154", "P14"].reduce((out, prop) => out ?? entity.claims[prop]?.[0]?.mainsnak?.datavalue?.value, null),
            description: localizedProperty("descriptions", langs)?.value,
            article: localizedProperty("sitelinks", wikis)
          };
          if (!data.label && !data.icon && !data.description && !data.article) return Promise.reject(data);
          renderWikidataResponse(data);
        })
        .catch(() => $(link).removeClass("explainable").addClass("unexplainable"));
    }

    function renderWikidataResponse(data) {
      const labelLink = $(data.link).removeClass("explainable unexplainable").addClass("explained");
      const cell = $("<td>")
        .attr("colspan", 2)
        .addClass("bg-body-tertiary");
      labelLink
        .closest("tr")
        .after($("<tr>").append(cell));

      if (data.icon) {
        $("<a>")
          .attr("href", OSM.WIKIMEDIA_COMMONS_URL + "File:" + data.icon)
          .append($("<img>").attr({ src: OSM.WIKIMEDIA_COMMONS_URL + "Special:FilePath/" + data.icon, height: "32" }))
          .addClass("float-end mb-1 ms-2")
          .appendTo(cell);
      }
      if (data.label) {
        labelLink.clone()
          .text(data.label)
          .removeAttr("title")
          .addClass("me-1")
          .appendTo(cell);
      }
      if (data.article) {
        $(`<${data.label ? "sup" : "div"}>`)
          .append($("<a>")
            .attr("href", `https://${data.article.site.slice(0, -4)}.wikipedia.org/wiki/` + encodeURIComponent(data.article.title))
            .text(data.label ? data.article.site : data.article.title)
          )
          .appendTo(cell);
      }
      if (data.description) {
        $("<div>")
          .text(data.description)
          .addClass("small")
          .appendTo(cell);
      }
    }

    function initWikidataLinks() {
      const markWikidataLinksAsExplainable = () => $("a[href*='wikidata.org/entity/Q']:not([class*='explain'])").each(markWikidataLinkAsExplainable);
      abortController = new AbortController();
      markWikidataLinksAsExplainable();
      $("#sidebar-content").on("turbo:before-stream-render", event => {
        const defaultRender = event.detail.render;
        event.detail.render = function (streamElement) {
          defaultRender(streamElement);
          markWikidataLinksAsExplainable();
        };
      });
    }

    page.pushstate = page.popstate = function (path, id, version) {
      OSM.loadSidebarContent(path, function () {
        initVersionsNavigation();
        page._addObject(type, id, version);
        initWikidataLinks();
      });
    };

    page.load = function (path, id, version) {
      initVersionsNavigation();
      page._addObject(type, id, version, true);
      initWikidataLinks();
    };

    page.unload = function () {
      page._removeObject();
      scrollStartObserver?.disconnect();
      scrollStartObserver = null;
      scrollEndObserver?.disconnect();
      scrollEndObserver = null;
      abortController?.abort();
      $("#sidebar_content").off("turbo:before-stream-render");
    };

    page._addObject = function () {};
    page._removeObject = function () {};

    function initVersionsNavigation() {
      scrollToActiveVersion();

      const $scrollableList = $("#versions-navigation-list-middle");
      const [scrollableFirstItem] = $scrollableList.children().first();
      const [scrollableLastItem] = $scrollableList.children().last();

      if (scrollableFirstItem) {
        scrollStartObserver = createScrollObserver("#versions-navigation-list-start", "2px 0px");
        scrollStartObserver.observe(scrollableFirstItem);
      }

      if (scrollableLastItem) {
        scrollEndObserver = createScrollObserver("#versions-navigation-list-end", "-2px 0px");
        scrollEndObserver.observe(scrollableLastItem);
      }
    }

    function createScrollObserver(shadowTarget, shadowOffset) {
      const threshold = 0.95;
      return new IntersectionObserver(([entry]) => {
        const floating = entry.intersectionRatio < threshold;
        $(shadowTarget)
          .css("box-shadow", floating ? `rgba(0, 0, 0, 0.075) ${shadowOffset} 2px` : "")
          .css("z-index", floating ? "5" : ""); // floating z-index should be larger than z-index of Bootstrap's .page-link:focus, which is 3
      }, { threshold });
    }

    return page;
  };

  OSM.MappedElement = function (map, type) {
    const page = OSM.Element(map, type);

    page._addObject = function (type, id, version, center) {
      const hashParams = OSM.parseHash();
      map.addObject({ type: type, id: parseInt(id, 10), version: version && parseInt(version, 10) }, function (bounds) {
        if (!hashParams.center && bounds.isValid() &&
            (center || !map.getBounds().contains(bounds))) {
          OSM.router.withoutMoveListener(function () {
            map.fitBounds(bounds);
          });
        }
      });
    };

    page._removeObject = function () {
      map.removeObject();
    };

    return page;
  };

  function scrollToActiveVersion() {
    const [scrollableList] = $("#versions-navigation-list-middle");

    if (!scrollableList) return;

    const [activeStartItem] = $("#versions-navigation-list-start #versions-navigation-active-page-item");
    const [activeScrollableItem] = $("#versions-navigation-list-middle #versions-navigation-active-page-item");

    if (activeStartItem) {
      scrollableList.scrollLeft = 0;
    } else if (activeScrollableItem) {
      scrollableList.scrollLeft = Math.round(activeScrollableItem.offsetLeft - (scrollableList.offsetWidth / 2) + (activeScrollableItem.offsetWidth / 2));
    } else {
      scrollableList.scrollLeft = scrollableList.scrollWidth - scrollableList.offsetWidth;
    }
  }
}());
