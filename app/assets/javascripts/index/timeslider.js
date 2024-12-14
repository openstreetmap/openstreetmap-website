/*
 * the wrapper function for adding the OpenHistoricalMap TimeSlider to the OHM map
 * called by the various OSM views to add this to their map, with optional callbacks
 */

function addOpenHistoricalMapTimeSlider (map, params, onreadycallback) {
  const historicalLayerKeys = ['historical', 'woodblock', 'japanese', 'railway'];

  const sliderOptions = {
    vectorLayer: undefined,  // see addTimeSliderToMap() which searches for this
    sourcename: "osm",
    stepInterval: 1,
    stepAmount: '10year',
    // range: ['1850-01-01', '2020-12-31'], // see below
    // date: '1860-06-15', // see below
    onDateChange: function () {
      OSM.router.updateHash();
    },
    onRangeChange: function () {
      OSM.router.updateHash();
    },
    onReady: function () {
      OSM.router.updateHash('force');
    },
    position: 'bottomright',
  };
  if (params && params.date && typeof params.date == 'string' && params.date.match(/^\-?\d{1,4}\-\d\d\-\d\d$/)) {
    sliderOptions.date = params.date;
  }
  if (params && params.daterange && typeof params.daterange == 'string' && params.daterange.match(/^\-?\d{1,4}\-\d\d\-\d\d,\-?\d{1,4}\-\d\d\-\d\d$/)) {
    sliderOptions.range = params.daterange.split(',');
  }
  // change basemap = MBGL gone and so is the real timeslider, so reinstate a new one
  // add the slider IF the OSM vector map is the layer showing
  if (getHistoryLayerIfShowing()) {
    addTimeSliderToMap(sliderOptions);
  }

  map.on('baselayerchange', function () {
    // do not use this.removeControl(this.timeslider)
    // by now, the timeslider is already gone from the visible map, along with the MBGL map
    // but the Leaflet wrapper will leave behind an empty DIV, and those pile up
    const oldctrl = this._container.querySelector('div.leaflet-control.leaflet-ohm-timeslider');

    if (oldctrl) oldctrl.parentElement.removeChild(oldctrl);

    if (this.timeslider) this.timeslider.autoplayPause();

    // should we add a new slider?
    const usetheslider = getHistoryLayerIfShowing();
    if (! usetheslider) return;

    // create a new slider, copying the old slider's date & range
    const newSliderOptions = Object.assign({}, sliderOptions);
    if (this.timeslider) {
      newSliderOptions.date = this.timeslider.getDate();
      newSliderOptions.range = this.timeslider.getRange();
      newSliderOptions.stepAmount = this.timeslider.getStepAmount();
      newSliderOptions.stepInterval = this.timeslider.getStepInterval();
    }
    addTimeSliderToMap(newSliderOptions);
  });

  function getHistoryLayerIfShowing () {
    let ohmlayer;
    map.eachLayer(function (layer) { // there's only 1 or 0 time layers at a time, so this works
      if (historicalLayerKeys.indexOf(layer.options.keyid) !== -1) ohmlayer = layer;
    });
    return ohmlayer;
  }

  function addTimeSliderToMap (slideroptions) {
    const ohmlayer = getHistoryLayerIfShowing();
    slideroptions.vectorLayer = ohmlayer;

    map.timeslider = new L.Control.OHMTimeSlider(slideroptions).addTo(map);

    // if a callback was given for when the slider is ready, poll until it becomes ready
    if (onreadycallback) {
      var waitforslider = setInterval(() => {
        var ready = ! getHistoryLayerIfShowing() || map.timeslider;
        if (ready) {
          clearInterval(waitforslider);
          onreadycallback();
        }
      }, 0.1 * 1000);
    }
  }
}
