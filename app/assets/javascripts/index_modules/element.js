let abortController = null;
const languagesToRequest = [...new Set(OSM.preferred_languages.map(l => l.toLowerCase()))];
const wikisToRequest = [...new Set([...OSM.preferred_languages, "en"].map(l => l.split("-")[0] + "wiki"))];
const isOfExpectedLanguage = ({ language }) => languagesToRequest[0].startsWith(language) || language === "mul";

export function element(type) {
  return function () {
    const page = {};

    page.load = function (path, id, version) {
      OSM.loadSidebarContent(path)
        .then(() => page.init(path, id, version, true));
    };

    page.init = function (path, id, version, keepViewport) {
      page._addObject(type, id, version, keepViewport);
      $(".numbered_pagination").trigger("numbered_pagination:enable");
      abortController = new AbortController();
    };

    page.unload = function () {
      page._removeObject();
      $(".numbered_pagination").trigger("numbered_pagination:disable");
      abortController?.abort();
    };

    page._addObject = function () {};
    page._removeObject = function () {};

    return page;
  };
};

export function mappedElement(type) {
  return function (map) {
    const page = element(type)(map);

    page._addObject = function (type, id, version, keepViewport) {
      const hashParams = OSM.parseHash();
      map.addObject({ type: type, id: parseInt(id, 10), version: version && parseInt(version, 10) }, function (bounds) {
        if (!hashParams.center && bounds.isValid() &&
            (!keepViewport || !map.getBounds().contains(bounds))) {
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
};

$(document).on("click", "button.wdt-preview", e => previewWikidataValue($(e.currentTarget)));

function previewWikidataValue($btn) {
  if (!OSM.WIKIDATA_API_URL) return;
  const items = $btn.data("qids");
  if (!items?.length) return;
  $btn.prop("disabled", true);
  const fetchOptions = {
    headers: { "Api-User-Agent": "OSM-TagPreview (https://github.com/openstreetmap/openstreetmap-website)" },
    signal: abortController?.signal
  };
  fetch(OSM.WIKIDATA_API_URL + "?" + new URLSearchParams({
    action: "wbgetentities",
    format: "json",
    origin: "*",
    ids: items.join("|"),
    props: "labels|sitelinks/urls|claims|descriptions",
    languages: languagesToRequest.join("|"),
    languagefallback: 1,
    sitefilter: wikisToRequest.join("|")
  }), fetchOptions)
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
            .map(data => renderWikidataResponse(data, $btn.siblings(`a[href*="wikidata.org/entity/${data.qid}"]`), fetchOptions))
        );
    })
    .catch(() => $btn.prop("disabled", false));
}

function getLocalizedResponse(entity) {
  const siteScheme = OSM.isDark("bs") ? "Q6545942" : "Q101608434";
  const scheme = ({ qualifiers } = {}) => qualifiers?.P8798?.some(q => q?.datavalue?.value?.id === siteScheme) ?? 0;
  const rank = ({ rank } = {}) => ({ preferred: 2, normal: 0 })[rank] ?? 0;
  const toBestClaim = (out, claim) => (!out || rank(claim) + scheme(claim) > rank(out) + scheme(out)) ? claim : out;
  const toFirstOf = (property) => (out, localization) => out ?? property[localization];
  const data = {
    qid: entity.id,
    label: languagesToRequest.reduce(toFirstOf(entity.labels), null),
    icon: [
      "P8972", // small logo or icon
      "P154", // logo image
      "P14" // traffic sign
    ].reduce((out, prop) => out ?? entity.claims[prop]?.filter(claim => claim.rank !== "deprecated").reduce(toBestClaim, null)?.mainsnak?.datavalue?.value, null),
    description: languagesToRequest.reduce(toFirstOf(entity.descriptions), null),
    article: wikisToRequest.reduce(toFirstOf(entity.sitelinks), null)
  };
  if (data.article) data.article.language = data.article.site.replace("wiki", "");
  return data;
}

function renderWikidataResponse({ icon, label, article, description }, $link, fetchOptions) {
  const localeName = new Intl.DisplayNames(OSM.preferred_languages, { type: "language" });
  const cell = $("<td>")
    .attr("colspan", 2)
    .addClass("bg-body-tertiary");

  if (icon && OSM.WIKIMEDIA_COMMONS_URL) {
    fetchCommonsThumbnail(icon, fetchOptions)
      .then(src => {
        $("<a>")
          .attr("href", OSM.WIKIMEDIA_COMMONS_URL + "/wiki/File:" + encodeURIComponent(icon) + `?uselang=${OSM.i18n.locale}`)
          .append($("<img>").attr({ src, height: "32", alt: icon }))
          .addClass("float-end mb-1 ms-2")
          .appendTo(cell);
      })
      .catch(() => {});
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

function fetchCommonsThumbnail(filename, fetchOptions) {
  const isVectorImage = filename.toLowerCase().endsWith(".svg");
  return fetch(OSM.WIKIMEDIA_COMMONS_URL + "/w/api.php?" + new URLSearchParams({
    action: "query",
    format: "json",
    origin: "*",
    prop: "imageinfo",
    titles: "File:" + filename,
    iiprop: "url",
    iiurlheight: "32"
  }), fetchOptions)
    .then(response => response.ok ? response.json() : Promise.reject(response))
    .then(({ query }) => {
      const page = Object.values(query.pages)[0];
      const imageInfo = page.imageinfo?.[0];
      const imageUrl = isVectorImage ? imageInfo?.url : imageInfo?.thumburl;
      if (!imageUrl) return Promise.reject(page);
      return imageUrl;
    });
}
