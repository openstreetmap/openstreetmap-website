(function () {
  let abortController = null;
  const languagesToRequest = [...new Set(OSM.preferred_languages.map(l => l.toLowerCase()))];
  const wikisToRequest = [...new Set([...OSM.preferred_languages, "en"].map(l => l.split("-")[0] + "wiki"))];
  const isOfExpectedLanguage = ({ language }) => languagesToRequest[0].startsWith(language) || language === "mul";

  $(document).on("click", "a[href='#versions-navigation-active-page-item']", function (e) {
    scrollToActiveVersion();
    $("#versions-navigation-active-page-item a.page-link").trigger("focus");
    e.preventDefault();
  });

  $(document).on("click", "button.wdt-preview", e => previewWikidataValue($(e.currentTarget)));

  OSM.Element = function (map, type) {
    const page = {};
    let scrollStartObserver, scrollEndObserver;

    page.pushstate = page.popstate = function (path, id, version) {
      OSM.loadSidebarContent(path, function () {
        initVersionsNavigation();
        page._addObject(type, id, version);
        abortController = new AbortController();
      });
    };

    page.load = function (path, id, version) {
      initVersionsNavigation();
      page._addObject(type, id, version, true);
      abortController = new AbortController();
    };

    page.unload = function () {
      page._removeObject();
      scrollStartObserver?.disconnect();
      scrollStartObserver = null;
      scrollEndObserver?.disconnect();
      scrollEndObserver = null;
      abortController?.abort();
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

  function previewWikidataValue($btn) {
    if (!OSM.WIKIDATA_API_URL) return;
    const items = $btn.data("qids");
    if (!items?.length) return;
    $btn.prop("disabled", true);
    fetch(OSM.WIKIDATA_API_URL + "?" + new URLSearchParams({
      action: "wbgetentities",
      format: "json",
      origin: "*",
      ids: items.join("|"),
      props: "labels|sitelinks/urls|claims|descriptions",
      languages: languagesToRequest.join("|"),
      languagefallback: 1,
      sitefilter: wikisToRequest.join("|")
    }), {
      headers: { "Api-User-Agent": "OSM-TagPreview (https://github.com/openstreetmap/openstreetmap-website)" },
      signal: abortController?.signal
    })
      .then(response => response.ok ? response.json() : Promise.reject(response))
      .then(({ entities }) => {
        if (!entities) return Promise.reject(entities);
        $btn
          .closest("tr")
          .after(
            items
              .filter(qid => entities[qid])
              .map(qid => getLocalizedResponse(entities[qid]))
              .filter(data => data.label || data.icon || data.description || data.article)
              .map(data => renderWikidataResponse(data, $btn.siblings(`a[href*="wikidata.org/entity/${data.qid}"]`)))
          );
      })
      .catch(() => $btn.prop("disabled", false));
  }

  function getLocalizedResponse(entity) {
    const rank = ({ rank }) => ({ preferred: 1, normal: 0, deprecated: -1 })[rank] ?? 0;
    const toBestClaim = (out, claim) => (rank(claim) > rank(out)) ? claim : out;
    const toFirstOf = (property) => (out, localization) => out ?? entity[property][localization];
    const data = {
      qid: entity.id,
      label: languagesToRequest.reduce(toFirstOf("labels"), null),
      icon: [
        "P8972", // small logo or icon
        "P154", // logo image
        "P14" // traffic sign
      ].reduce((out, prop) => out ?? entity.claims[prop]?.reduce(toBestClaim)?.mainsnak?.datavalue?.value, null),
      description: languagesToRequest.reduce(toFirstOf("descriptions"), null),
      article: wikisToRequest.reduce(toFirstOf("sitelinks"), null)
    };
    if (data.article) data.article.language = data.article.site.replace("wiki", "");
    return data;
  }

  function renderWikidataResponse({ icon, label, article, description }, $link) {
    const localeName = new Intl.DisplayNames(OSM.preferred_languages, { type: "language" });
    const cell = $("<td>")
      .attr("colspan", 2)
      .addClass("bg-body-tertiary");

    if (icon && OSM.WIKIMEDIA_COMMONS_URL) {
      let src = OSM.WIKIMEDIA_COMMONS_URL + "Special:Redirect/file/" + encodeURIComponent(icon) + "?mobileaction=toggle_view_desktop";
      if (!icon.endsWith(".svg")) src += "&width=128";
      $("<a>")
        .attr("href", OSM.WIKIMEDIA_COMMONS_URL + "File:" + encodeURIComponent(icon) + `?uselang=${OSM.i18n.locale}`)
        .append($("<img>").attr({ src, height: "32" }))
        .addClass("float-end mb-1 ms-2")
        .appendTo(cell);
    }
    if (label) {
      const link = $link.clone()
        .text(label.value)
        .attr("dir", "auto")
        .appendTo(cell);
      if (!isOfExpectedLanguage(label)) {
        link.attr("lang", label.language);
        link.after($("<sup>").text(" " + localeName.of(label.language)));
      }
    }
    if (article) {
      const link = $("<a>")
        .attr("href", article.url + `?uselang=${OSM.i18n.locale}`)
        .text(label ? OSM.i18n.t("javascripts.element.wikipedia") : article.title)
        .attr("dir", "auto")
        .appendTo(cell);
      if (label) {
        link.before(" (");
        link.after(")");
      }
      if (!isOfExpectedLanguage(article)) {
        link.attr("lang", article.language);
        link.after($("<sup>").text(" " + localeName.of(article.language)));
      }
    }
    if (description) {
      const text = $("<div>")
        .text(description.value)
        .addClass("small")
        .attr("dir", "auto")
        .appendTo(cell);
      if (!isOfExpectedLanguage(description)) {
        text.attr("lang", description.language);
      }
    }
    return $("<tr>").append(cell);
  }
}());
