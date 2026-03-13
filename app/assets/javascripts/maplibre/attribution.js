OSM.MapLibre.AttributionControl = class extends maplibregl.AttributionControl {
  constructor(options = {}) {
    super({});
    this._map = null;
    this._container = null;
    this._includeReportLink = Boolean(options.includeReportLink);
    this._credit = options.credit;
  }

  _updateAttributions() {
    if (!this._map.style) return;

    let attribHTML = "";

    // Add report link if enabled
    if (this._includeReportLink) {
      const reportLink = document.createElement("a");
      reportLink.href = "/fixthemap";
      reportLink.target = "_blank";
      reportLink.rel = "noopener noreferrer";
      reportLink.className = "maplibregl-ctrl-attrib-report-link";
      reportLink.textContent = OSM.i18n.t("javascripts.embed.report_problem");
      attribHTML += reportLink.outerHTML + " | ";
    }

    const copyrightLink = document.createElement("a");
    copyrightLink.href = "/copyright";
    copyrightLink.textContent = OSM.i18n.t("javascripts.map.openstreetmap_contributors");

    attribHTML += OSM.i18n.t("javascripts.map.copyright_text", {
      copyright_link: copyrightLink.outerHTML
    });

    if (this._credit) {
      attribHTML += this._credit.donate ? " ♥️ " : ". ";
      attribHTML += this._buildCreditHtml(this._credit);
    }

    attribHTML += ". ";

    const termsLink = document.createElement("a");
    termsLink.href = "https://wiki.osmfoundation.org/wiki/Terms_of_Use";
    termsLink.target = "_blank";
    termsLink.rel = "noopener noreferrer";
    termsLink.textContent = OSM.i18n.t("javascripts.map.website_and_api_terms");
    attribHTML += termsLink.outerHTML;

    // check if attribution string is different to minimize DOM changes
    if (attribHTML === this._attribHTML) return;

    this._innerContainer.innerHTML = attribHTML;
    this._attribHTML = attribHTML;
    this._updateCompact();

    // Update report link href after initial render
    if (this._includeReportLink) {
      this._updateReportLink();
    }
  }

  _buildCreditHtml(credit) {
    const children = {};
    if (credit.children) {
      for (const childId in credit.children) {
        children[childId] = OSM.MapLibre.AttributionControl._buildCreditHtml(credit.children[childId]);
      }
    }

    const text = OSM.i18n.t(`javascripts.map.${credit.id}`, children);

    if (credit.href) {
      const link = document.createElement("a");
      link.href = credit.href;
      link.textContent = text;

      if (credit.donate) {
        link.className = "donate-attr";
      } else {
        link.target = "_blank";
        link.rel = "noopener noreferrer";
      }

      return link.outerHTML;
    }

    return text;
  }

  onAdd(map) {
    this._map = map;

    if (this._includeReportLink) {
      map.on("moveend", this._updateReportLink.bind(this));
    }

    return super.onAdd(map);
  }

  onRemove() {
    if (!this._map) return;

    if (this._includeReportLink) {
      this._map.off("moveend", this._updateReportLink.bind(this));
    }
    this._map = null;
    super.onRemove();
  }

  _updateReportLink() {
    if (!this._container) return;

    const reportLink = this._container.querySelector(".maplibregl-ctrl-attrib-report-link");
    if (!reportLink) return;

    const center = this._map.getCenter();
    const params = new URLSearchParams({
      lat: center.lat.toFixed(5),
      lon: center.lng.toFixed(5),
      zoom: Math.floor(this._map.getZoom())
    });
    reportLink.href = `/fixthemap?${params.toString()}`;
  }
};
