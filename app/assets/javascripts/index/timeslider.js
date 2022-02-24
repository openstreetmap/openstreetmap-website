/*
 * the wrapper function for adding the OpenHistoricalMap TimeSlider to the OHM map
 * called by the various OSM views to add this to their map, with optional callbacks
 */

function addOpenHistoricalMapTimeSlider (map, params, onreadycallback) {
  const historicalLayerKeys = ['historical', 'woodblock'];
  const timeSliderHardMaxYear = (new Date()).getFullYear();  // current calendar year
  const timeSliderHardMinYear = -4000;
  const timeSliderDateRange = (params && params.daterange) ? params.daterange.split(',').map(function (i) { return parseInt(i); }) : [1800, timeSliderHardMaxYear];
  const timeSliderDate = (params && params.date) ? parseInt(params.date) : 1900;

  var sliderOptions = {
    position: 'bottomright',
    mbgllayer: undefined,  // see addTimeSliderToMap() which searches for this
    timeSliderOptions: {
      sourcename: "osm",
      datelimit: [timeSliderHardMinYear, timeSliderHardMaxYear],
      onDateSelect: function () {
        OSM.router.updateHash();
      },
      onRangeChange: function () {
        OSM.router.updateHash();
      },
      onReady: function () {
        OSM.router.updateHash('force');
      },
    }
  };
  if (timeSliderDate) sliderOptions.timeSliderOptions.date = timeSliderDate;
  if (timeSliderDateRange) sliderOptions.timeSliderOptions.range = timeSliderDateRange;

  // change basemap = MBGL gone and so is the real timeslider, so reinstate a new one
  // add the slider IF the the OSM vector map is the layer showing
  if (getHistoryLayerIfShowing()) {
    addTimeSliderToMap(sliderOptions);
  }

  map.on('baselayerchange', function () {
    // by now, the timeslider is already gone from the visible map, along with the MBGL map
    // but the Leaflet wrapper will leave behind an empty DIV, and those pile up
    const oldctrl = this._container.querySelector('div.leaflet-control-mbgltimeslider');
    if (oldctrl) oldctrl.parentElement.removeChild(oldctrl);

    const usetheslider = getHistoryLayerIfShowing();
    if (! usetheslider) return;

    // create a new slider, copying the old slider's date & range
    const newSliderOptions = Object.assign({}, sliderOptions);
    if (this.timeslider) {
      newSliderOptions.timeSliderOptions.date = this.timeslider.getDate();
      newSliderOptions.timeSliderOptions.range = this.timeslider.getRange();
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
    slideroptions.mbgllayer = ohmlayer;
    map.timeslider = new L.Control.MBGLTimeSlider(slideroptions).addTo(map);

    // if a callback was given for when the slider is ready, poll until it becomes ready
    if (onreadycallback) {
      var waitforslider = setInterval(function () {
        var ready = ! getHistoryLayerIfShowing() || (map.timeslider && map.timeslider._timeslider);
        if (ready) {
          clearInterval(waitforslider);
          onreadycallback();
        }
      }, 0.1 * 1000);
    }
  }
}
