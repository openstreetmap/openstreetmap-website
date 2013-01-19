var OWL = {

  geoJsonStyles: {
    'node_create': {
      fill: true,
      stroke: false,
      fillColor: "indigo",
      fillOpacity: 0.50,
      radius: 8
    },
    'node_modify': {
      fill: true,
      stroke: false,
      fillColor: "blue",
      fillOpacity: 0.50,
      radius: 8
    },
    'node_delete': {
      fill: true,
      stroke: false,
      fillColor: "red",
      fillOpacity: 0.50,
      radius: 8
    },
    'way_create': {
      color: "indigo",
      fillColor: "indigo",
      weight: 5,
      opacity: 0.50,
      fillOpacity: 0.50
    },
    'way_modify': {
      color: "blue",
      fillColor: "blue",
      weight: 5,
      opacity: 0.50,
      fillOpacity: 0.50
    },
    'way_delete': {
      color: "red",
      fillColor: "red",
      weight: 5,
      opacity: 0.50,
      fillOpacity: 0.50
    },
    'way_affect': {
      color: "blue",
      fillColor: "lightblue",
      weight: 5,
      opacity: 0.50,
      fillOpacity: 0.50
    },
    'hover': {
      opacity: 0.75,
      fillOpacity: 0.75,
      weight: 7,
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
            var value = text.match(/(browse\/.*?\.png)/)[0];
            symbols[key] = value;
          }
      });
    });
    //console.log(this.tagSymbols);
  }
};
