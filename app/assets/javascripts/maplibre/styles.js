(function () {
  const convertIDUrlToMapLibreUrls = function (url) {
    const tileUrl = url.replace("{zoom}", "{z}");

    // {switch:a,b,c} for DNS server multiplexing
    const switchRegex = /\{switch:([^}]+)}/;
    const match = tileUrl.match(switchRegex);
    if (!match) {
      // No switch -> single tile URL
      return [tileUrl];
    }

    const subdomains = match[1].split(",");
    return subdomains.map(subdomain =>
      tileUrl.replace(switchRegex, subdomain)
    );
  };

  const createRasterStyle = function (maxzoom, tileUrl) {
    const tiles = convertIDUrlToMapLibreUrls(tileUrl);
    return {
      version: 8,
      sources: {
        raster: {
          type: "raster",
          tileSize: 256,
          tiles,
          maxzoom
        }
      },
      layers: [
        {
          id: "raster",
          type: "raster",
          source: "raster"
        }
      ]
    };
  };

  // we register at OSM.MapLibre.Styles all the light and dark mode styles that exist in layers.yml
  for (const layerDefinition of OSM.LAYER_DEFINITIONS) {
    if (layerDefinition.isVectorStyle) {
      OSM.MapLibre.Styles[layerDefinition.leafletOsmId] = (options) => layerDefinition.styleUrl.replace("{apikey}", options?.apikey);
      if (layerDefinition.leafletOsmDarkId) {
        OSM.MapLibre.Styles[layerDefinition.leafletOsmDarkId] = (options) => layerDefinition.styleUrlDark.replace("{apikey}", options?.apikey);
      }
    } else {
      OSM.MapLibre.Styles[layerDefinition.leafletOsmId] = (options) => createRasterStyle(layerDefinition.maxZoom, layerDefinition.tileUrl.replace("{apikey}", options?.apikey));
      if (layerDefinition.leafletOsmDarkId) {
        OSM.MapLibre.Styles[layerDefinition.leafletOsmDarkId] = (options) => createRasterStyle(layerDefinition.maxZoom, layerDefinition.tileUrlDark.replace("{apikey}", options?.apikey));
      }
    }
  }
}());
