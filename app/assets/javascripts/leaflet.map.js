L.extend(L.LatLngBounds.prototype, {
  getSize: function () {
    return (this._northEast.lat - this._southWest.lat) *
           (this._northEast.lng - this._southWest.lng);
  },

  wrap: function () {
    return new L.LatLngBounds(this._southWest.wrap(), this._northEast.wrap());
  }
});

L.OSM.Map = L.Map.extend({
  initialize: function (id, options) {
    L.Map.prototype.initialize.call(this, id, options);

    this.baseLayers = OSM.LAYER_DEFINITIONS.map((
      { credit, nameId, leafletOsmId, leafletOsmDarkId, ...layerOptions }
    ) => {
      if (credit) layerOptions.attribution = makeAttribution(credit);
      if (nameId) layerOptions.name = OSM.i18n.t(`javascripts.map.base.${nameId}`);
      const layerConstructor =
        (OSM.isDarkMap() && L.OSM[leafletOsmDarkId]) ||
        L.OSM[leafletOsmId] ||
        L.OSM.TileLayer;

      const layer = new layerConstructor(layerOptions);
      layer.on("add", () => {
        this.fire("baselayerchange", { layer: layer });
      });
      return layer;
    });

    const credit = { 'id': 'make_a_donation', 'href': 'https://openstreetmap.app.neoncrm.com/forms/ohm', 'donate': true }
    this.ohmMaplibreOptions = {
      attribution: makeAttribution(credit, true),
      localIdeographFontFamily: "'Noto Sans', 'Noto Sans CJK SC', sans-serif",
      minZoom: 1,  /* leave at 1 even if L.OSM.Map has something deeper */
      maxZoom: 20,  /* match to "L.OSM.Map" options in index.js */
    }

    /* see also timeslider.js and viewreset/baselayerchange handlers */

    // Add multi-lingual awareness
    const language = new MapboxLanguage({
      defaultLanguage: 'mul'
    });
    let selectedLanguage;
    /*
     * Note: there is no language validation at this step; OSM.preferred_languages[0] may be any arbitrary string. Even
     * if it is a valid (RFC 5646) language string it may be filtered out for being infrequently used
     * (see https://github.com/OpenHistoricalMap/issues/issues/948) and may not appear on the OHM map.
     */
    if (OSM.preferred_languages !== undefined && OSM.preferred_languages.length > 0) {
      selectedLanguage = OSM.preferred_languages[0]
    } else {
      if (navigator.language) {
        selectedLanguage = navigator.language
      }
    }
    if (selectedLanguage) {
      // Strip out country and script codes. Country- and script-qualified language tags are relatively rare in OHM, and mapbox-gl-language lacks cascading fallback functionality.
      // https://github.com/mapbox/mapbox-gl-language/issues/4
      selectedLanguage = selectedLanguage.split("-")[0];
    }
    // console.info(`language:\n  preferred: ${OSM.preferred_languages}\n  browser: ${navigator.language}\n  using: ${selectedLanguage}`);
    language.supportedLanguages.push(selectedLanguage);

    let ohmLayerOptions = [
      {
        code: "O",
        keyid: "historical",
        name: OSM.i18n.t("javascripts.map.base.historical"),
        style: ohmVectorStyles.Historical,
      },
      {
        code: "R",
        keyid: "railway",
        name: OSM.i18n.t("javascripts.map.base.railway"),
        style: ohmVectorStyles.Railway,
      },
      {
        code: "W",
        keyid: "woodblock",
        name: OSM.i18n.t("javascripts.map.base.woodblock"),
        style: ohmVectorStyles.Woodblock,
      },
      {
        code: "J",
        keyid: "japanese",
        name: OSM.i18n.t("javascripts.map.base.japanesescroll"),
        style: ohmVectorStyles.JapaneseScroll,
      },
    ];

    this.baseLayers.unshift(...ohmLayerOptions.map(layerOptions => {
      layerOptions.style = language.setLanguage(layerOptions.style, selectedLanguage);
      let layer = new L.MaplibreGL(
        Object.assign(this.ohmMaplibreOptions, layerOptions)
      );
      layer.on("add", () => {
        this.fire("baselayerchange", { layer: layer });
      });
      return layer;
    }));

    this.noteLayer = new L.FeatureGroup();
    this.noteLayer.options = { code: "N" };

    this.dataLayer = new L.OSM.DataLayer(null);
    this.dataLayer.options.code = "D";

    this.gpsLayer = new L.OSM.GPS({
      pane: "overlayPane",
      code: "G",
      name: OSM.i18n.t("javascripts.map.base.gps")
    });
    this.gpsLayer.on("add", () => {
      this.fire("overlayadd", { layer: this.gpsLayer });
    }).on("remove", () => {
      this.fire("overlayremove", { layer: this.gpsLayer });
    });


    this.on("baselayerchange", function (event) {
      if (this.baseLayers.indexOf(event.layer) >= 0) {
        this.setMaxZoom(event.layer.options.maxZoom);
      }
    });

    function makeAttribution(credit, isOhm = false) {
      let attribution = "";

      if (isOhm) {
        attribution += OSM.i18n.t("javascripts.map.cc0_text", {
          copyright_link: $("<a>", {
            href: "/copyright",
            text: OSM.i18n.t("javascripts.map.openhistoricalmap_contributors")
          }).prop("outerHTML")
        })
      } else {
        attribution += OSM.i18n.t("javascripts.map.copyright_text", {
          copyright_link: $("<a>", {
            href: "/copyright",
            text: OSM.i18n.t("javascripts.map.openstreetmap_contributors")
          }).prop("outerHTML")
        })
      }

      attribution += credit.donate ? " &hearts; " : ". ";
      attribution += makeCredit(credit);
      attribution += ". ";

      attribution += $("<a>", {
        href: isOhm ? "https://wiki.openstreetmap.org/wiki/OpenHistoricalMap/Reuse" : "https://wiki.osmfoundation.org/wiki/Terms_of_Use",
        text: OSM.i18n.t("javascripts.map.website_and_api_terms")
      }).prop("outerHTML");

      return attribution;
    }

    function makeCredit(credit) {
      const children = {};
      for (const childId in credit.children) {
        children[childId] = makeCredit(credit.children[childId]);
      }
      const text = OSM.i18n.t(`javascripts.map.${credit.id}`, children);
      if (credit.href) {
        const link = $("<a>", {
          href: credit.href,
          text: text
        });
        if (credit.donate) {
          link.addClass("donate-attr");
        } else {
          link.attr("target", "_blank");
        }
        return link.prop("outerHTML");
      }
      return text;
    }
  },

  updateLayers: function (layerParam) {
    var layers = layerParam || "O",
      layersAdded = "";

    for (let i = this.baseLayers.length - 1; i >= 0; i--) {
      if (layers.indexOf(this.baseLayers[i].options.code) >= 0) {
        this.addLayer(this.baseLayers[i]);
        layersAdded = layersAdded + this.baseLayers[i].options.code;
      } else if (i === 0 && layersAdded === "") {
        this.addLayer(this.baseLayers[i]);
      } else {
        this.removeLayer(this.baseLayers[i]);
      }
    }
  },

  getLayersCode: function () {
    let layerConfig = "";
    this.eachLayer(function (layer) {
      if (layer.options && layer.options.code) {
        layerConfig += layer.options.code;
      }
    });
    return layerConfig;
  },

  getMapBaseLayerId: function () {
    var baseLayerId;
    this.eachLayer(function (layer) {
      if (layer.options && layer.options.keyid) baseLayerId = layer.options.keyid;
    });
    return baseLayerId;
  },

  getMapBaseLayer: function () {
    for (const layer of this.baseLayers) {
      if (this.hasLayer(layer)) return layer;
    }
  },

  getUrl: function (marker) {
    const precision = OSM.zoomPrecision(this.getZoom());
    const params = {};

    if (marker && this.hasLayer(marker)) {
      const latLng = marker.getLatLng().wrap();
      [params.mlat, params.mlon] = OSM.cropLocation(marker.getLatLng(), this.getZoom());

    }

    let url = location.protocol + "//" + OSM.SERVER_URL + "/";
    const query = new URLSearchParams(params),
          hash = OSM.formatHash(this);

    if (query) url += "?" + query;
    if (hash) url += hash;

    return url;
  },

  getShortUrl: function (marker) {
    const zoom = this.getZoom(),
          latLng = marker && this.hasLayer(marker) ? marker.getLatLng().wrap() : this.getCenter().wrap(),
          char_array = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~",
          x = Math.round((latLng.lng + 180.0) * ((1 << 30) / 90.0)),
          y = Math.round((latLng.lat + 90.0) * ((1 << 30) / 45.0)),
          // JavaScript only has to keep 32 bits of bitwise operators, so this has to be
          // done in two parts. each of the parts c1/c2 has 30 bits of the total in it
          // and drops the last 4 bits of the full 64 bit Morton code.
          c1 = interlace(x >>> 17, y >>> 17),
          c2 = interlace((x >>> 2) & 0x7fff, (y >>> 2) & 0x7fff);
    let str = location.protocol + "//" + location.hostname.replace(/^www\.openstreetmap\.org/i, "osm.org") + "/go/";

    for (let i = 0; i < Math.ceil((zoom + 8) / 3.0) && i < 5; ++i) {
      const digit = (c1 >> (24 - (6 * i))) & 0x3f;
      str += char_array.charAt(digit);
    }
    for (let i = 5; i < Math.ceil((zoom + 8) / 3.0); ++i) {
      const digit = (c2 >> (24 - (6 * (i - 5)))) & 0x3f;
      str += char_array.charAt(digit);
    }
    for (let i = 0; i < ((zoom + 8) % 3); ++i) str += "-";

    // Called to interlace the bits in x and y, making a Morton code.
    function interlace(x, y) {
      let interlaced_x = x,
          interlaced_y = y;
      interlaced_x = (interlaced_x | (interlaced_x << 8)) & 0x00ff00ff;
      interlaced_x = (interlaced_x | (interlaced_x << 4)) & 0x0f0f0f0f;
      interlaced_x = (interlaced_x | (interlaced_x << 2)) & 0x33333333;
      interlaced_x = (interlaced_x | (interlaced_x << 1)) & 0x55555555;
      interlaced_y = (interlaced_y | (interlaced_y << 8)) & 0x00ff00ff;
      interlaced_y = (interlaced_y | (interlaced_y << 4)) & 0x0f0f0f0f;
      interlaced_y = (interlaced_y | (interlaced_y << 2)) & 0x33333333;
      interlaced_y = (interlaced_y | (interlaced_y << 1)) & 0x55555555;
      return (interlaced_x << 1) | interlaced_y;
    }

    const params = new URLSearchParams();
    const layers = this.getLayersCode().replace("M", "");

    if (layers) {
      params.set("layers", layers);
    }

    if (marker && this.hasLayer(marker)) {
      params.set("m", "");
    }

    if (this._object) {
      params.set(this._object.type, this._object.id);
    }

    const query = params.toString();
    if (query) {
      str += "?" + query;
    }

    return str;
  },

  getGeoUri: function (marker) {
    const precision = OSM.zoomPrecision(this.getZoom());
    let latLng = this.getCenter();
    const zoom = this.getZoom();
    params = {};

    if (marker && this.hasLayer(marker)) {
      latLng = marker.getLatLng().wrap();
    } else {
      latLng = this.getCenter();
    }

    return `geo:${OSM.cropLocation(latLng, zoom).join(",")}?z=${zoom}`;
  },

  addObject: function (object, callback) {
    const objectStyle = {
      color: "#FF6200",
      weight: 4,
      opacity: 1,
      fillOpacity: 0.5
    };

    const changesetStyle = {
      weight: 4,
      color: "#FF9500",
      opacity: 1,
      fillOpacity: 0,
      interactive: false
    };

    const haloStyle = {
      weight: 2.5,
      radius: 20,
      fillOpacity: 0.5,
      color: "#FF6200"
    };

    this.removeObject();

    if (object.type === "note" || object.type === "changeset") {
      this._objectLoader = { abort: () => {} };

      this._object = object;
      this._objectLayer = L.featureGroup().addTo(this);

      if (object.type === "note") {
        L.circleMarker(object.latLng, haloStyle).addTo(this._objectLayer);

        if (object.icon) {
          L.marker(object.latLng, {
            icon: object.icon,
            opacity: 1,
            interactive: true
          }).addTo(this._objectLayer);
        }
      } else if (object.type === "changeset") {
        if (object.bbox) {
          L.rectangle([
            [object.bbox.minlat, object.bbox.minlon],
            [object.bbox.maxlat, object.bbox.maxlon]
          ], changesetStyle).addTo(this._objectLayer);
        }
      }

      if (callback) callback(this._objectLayer.getBounds());
      this.fire("overlayadd", { layer: this._objectLayer });
    } else { // element handled by L.OSM.DataLayer
      const map = this;
      this._objectLoader = new AbortController();
      fetch(OSM.apiUrl(object), {
        headers: { accept: "application/json" },
        signal: this._objectLoader.signal
      })
        .then(response => response.json())
        .then(function (data) {
          map._object = object;

          map._objectLayer = new L.OSM.DataLayer(null, {
            styles: {
              node: objectStyle,
              way: objectStyle,
              area: objectStyle,
              changeset: changesetStyle
            }
          });

          map._objectLayer.interestingNode = function (node, wayNodes, relationNodes) {
            return object.type === "node" ||
                   (object.type === "relation" && Boolean(relationNodes[node.id]));
          };

          map._objectLayer.addData(data);
          map._objectLayer.addTo(map);

          if (callback) callback(map._objectLayer.getBounds());
          map.fire("overlayadd", { layer: map._objectLayer });
        })
        .catch(() => {});
    }
  },

  removeObject: function () {
    this._object = null;
    if (this._objectLoader) this._objectLoader.abort();
    if (this._objectLayer) this.removeLayer(this._objectLayer);
    this.fire("overlayremove", { layer: this._objectLayer });
  },

  getState: function () {
    return {
      center: this.getCenter().wrap(),
      zoom: this.getZoom(),
      layers: this.getLayersCode()
    };
  },

  setState: function (state, options) {
    if (state.center) this.setView(state.center, state.zoom, options);
    if (state.layers) this.updateLayers(state.layers);
  },

  setSidebarOverlaid: function (overlaid) {
    const mediumDeviceWidth = window.getComputedStyle(document.documentElement).getPropertyValue("--bs-breakpoint-md");
    const isMediumDevice = window.matchMedia(`(max-width: ${mediumDeviceWidth})`).matches;
    const sidebarWidth = $("#sidebar").width();
    const sidebarHeight = $("#sidebar").height();
    if (overlaid && !$("#content").hasClass("overlay-sidebar")) {
      $("#content").addClass("overlay-sidebar");
      this.invalidateSize({ pan: false });
      if (isMediumDevice) {
        this.panBy([0, -sidebarHeight], { animate: false });
      } else if ($("html").attr("dir") !== "rtl") {
        this.panBy([-sidebarWidth, 0], { animate: false });
      }
    } else if (!overlaid && $("#content").hasClass("overlay-sidebar")) {
      if (isMediumDevice) {
        this.panBy([0, $("#map").height() / 2], { animate: false });
      } else if ($("html").attr("dir") !== "rtl") {
        this.panBy([sidebarWidth, 0], { animate: false });
      }
      $("#content").removeClass("overlay-sidebar");
      this.invalidateSize({ pan: false });
    }
    return this;
  }
});

L.Icon.Default.imagePath = "/images/";

L.Icon.Default.imageUrls = {
  "/images/marker-icon.png": OSM.MARKER_ICON,
  "/images/marker-icon-2x.png": OSM.MARKER_ICON_2X,
  "/images/marker-shadow.png": OSM.MARKER_SHADOW
};

L.extend(L.Icon.Default.prototype, {
  _oldGetIconUrl: L.Icon.Default.prototype._getIconUrl,

  _getIconUrl: function (name) {
    const url = this._oldGetIconUrl(name);
    return L.Icon.Default.imageUrls[url];
  }
});

OSM.isDarkMap = function () {
  const mapTheme = $("body").attr("data-map-theme");
  if (mapTheme) return mapTheme === "dark";
  const siteTheme = $("html").attr("data-bs-theme");
  if (siteTheme) return siteTheme === "dark";
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
};

OSM.getMarker = function ({ icon = "MARKER_RED", shadow = true, height = 41 }) {
  const options = {
    iconUrl: OSM[icon.toUpperCase()] || OSM.MARKER_RED,
    iconSize: [25, height],
    iconAnchor: [12, height],
    popupAnchor: [1, -34]
  };
  if (shadow) {
    options.shadowUrl = OSM.MARKER_SHADOW;
    options.shadowSize = [41, 41];
    options.shadowAnchor = [12, 41];
  }
  return L.icon(options);
};
