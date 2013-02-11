var OWL = {

  geoJsonStyles: {
    'Point': {
      fill: true,
      stroke: false,
      opacity: 0.50,
      radius: 8
    },
    'LineString': {
      fill: false,
      opacity: 0.50,
      weight: 5
    },
    'MultiLineString': {
      fill: false,
      opacity: 0.50,
      weight: 5
    },
    'Polygon': {
      stroke: false,
      fillOpacity: 0.10,
      opacity: 0.50,
      weight: 1
    },
    'MultiPolygon': {
      stroke: false,
      fillOpacity: 0.10,
      opacity: 0.50,
      weight: 1
    },
    'action_CREATE': {
      color: 'indigo',
      fillColor: 'indigo'
    },
    'action_MODIFY': {
      color: 'blue',
      fillColor: 'blue'
    },
    'action_DELETE': {
      color: 'red',
      fillColor: 'red'
    },
    'hover': {
      opacity: 0.75,
      fillOpacity: 0.25
    }
  },

  // Mapping from "tag=value" to tag symbol image URL. Calling initTagSymbols populates this hash.
  tagSymbols: {},

  // Goes through CSS rules and extracts tag=value and image URL information (see browse.css.scss)
  // to the tagSymbols hash.
  initTagSymbols: function () {
    var symbols = this.tagSymbols;
    $.each(document.styleSheets, function (index, stylesheet) {
      $.each(stylesheet.rules || stylesheet.cssRules, function (index, rule) {
          var text = rule.cssText || rule.style.cssText;
          if (text.search(/browse\/.*?\.png/) != -1) {
            // It's a rule for a tag symbol, let's process it!
            var key = text.substring(1, text.indexOf(" {")).replace('.', '=');
            var value = text.match(/\([\"]*(.*?browse\/.*?\.png)/)[1];
            symbols[key] = value;
          }
      });
    });
    //console.log(this.tagSymbols);
  }
};
