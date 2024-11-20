L.Control.OHMTimeSlider = L.Control.extend({
    options: {
        position: 'bottomright',
        vectorLayer: null, // the L.MapboxGL that this will filter; required
        vectorSourceName: 'osm', // within that vectorLayer, layers with this source will be managed/filtered
        range: null, // the [date, date] range corresponding to the slider's sliding range; default provided in initialize()
        date: null, // the date currently selected by the slider, interpolating over the range; default provided in initialize()
        stepInterval: 5, // when autoplaying, how many seconds between ticks
        stepAmount: '100year', // when autoplaying, how far to skip in time per tick
        language: undefined, // language translations from OHMTimeSlider.Translations; specify in constructor, or else will auto-detect
        sliderColorBefore: '#003AFA', // color of the time-slider, left side before the currntly-selected date
        sliderColorAfter: '#668CFF', // color of the time-slider, right side after the currntly-selected date
        onReady: function () {}, // called when control is all initialized and has started filtering the vectorLayer
        onDateChange: function () {}, // called when date is changed
        onRangeChange: function () {}, // called when range is changed
    },

    initialize: function (options={}) {
        L.setOptions(this, options);

        if (! this.options.range) {
            const current_year = (new Date()).getFullYear();
            this.options.range = [`${current_year - 200}-01-01`, `${current_year}-12-31`];
        }

        if (! this.options.date) {
            // Get today's date
            let today = new Date();
            // Subtract 100 years
            today.setFullYear(today.getFullYear() - 100);
            // Format the date as yyyy-mm-dd
            let formattedDate = today.toISOString().split('T')[0];
            this.options.date = formattedDate;
        }

        // preliminary sanity checks
        if (! this.options.vectorLayer) throw `OHMTimeSlider: missing required vectorLayer`;

        if (! this.isValidDate(this.options.date) ) throw 'OHMTimeSlider: date must be YYYY-MM-DD format';
        if (! this.isValidDate(this.options.range[0]) ) throw 'OHMTimeSlider: range lower date must be YYYY-MM-DD format';
        if (! this.isValidDate(this.options.range[1]) ) throw 'OHMTimeSlider: range upper date must be YYYY-MM-DD format';

        // load the language translations, or die
        const lang0 = this.options.language || 'undefined';
        const lang1 = navigator.language;
        const lang2 = navigator.language.substr(0, 2).toLowerCase();
        this._translations = L.Control.OHMTimeSlider.Translations[lang0] || L.Control.OHMTimeSlider.Translations[lang1] || L.Control.OHMTimeSlider.Translations[lang2];
        if (! this._translations) {
            this._translations = L.Control.OHMTimeSlider.Translations['en-US'];
            console.error(`OHMTimeSlider: unknown language, using en-US; options were '${[lang0, lang1, lang2].join(',')}'`);
        }
    },

    onAdd: function (map) {
        // final sanity check, that the vectorLayer in fact is a MBGL map
        if (! this.options.vectorLayer._glMap) throw 'OHMTimeSlider: vectorLayer is not a MBGL layer, or is not yet initialized';

        // some internal constants
        this.constants = {};
        this.constants.onedaystep = 1 / 365.0;
        this.constants.minYear = -4000;
        this.constants.maxYear = (new Date()).getFullYear();

        // internal state of selected range & date
        this.state = {};
        this.state.date = this.options.date;
        this.state.range = this.options.range;

        // the max year to allow in the range picker inputs
        const maxabsyear = Math.max(Math.abs(this.constants.minYear), Math.abs(this.constants.maxYear));

        // the BCE/CE pickers, get their options text from Intl.DateTimeFormat so it matches the displays in formatDateShort() and formatDateLong()
        const text_ce = this.getTextForCE();
        const text_bce = this.getTextForBCE();

        // looks good
        // create the main container and the Change Date widget
        const container = L.DomUtil.create('div', 'leaflet-ohm-timeslider');
        L.DomEvent.disableClickPropagation(container);
        L.DomEvent.disableScrollPropagation(container);
        this.container = container;

        container.innerHTML = `
        <div class="leaflet-ohm-timeslider-expandcollapse" data-timeslider="expandcollapse" role="button" tabindex="0" title="${this._translations.expandcollapse_title}"><span></span></div>
        <div class="leaflet-ohm-timeslider-rangeinputs">
            <div class="leaflet-ohm-timeslider-rangeinputs-title">
                <strong>${this._translations.range_title}</strong>
            </div>
            <div class="leaflet-ohm-timeslider-rangeinputs-mindate">
                <select data-timeslider="rangeminmonth" aria-label="${this._translations.daterange_min_month_title}">
                    <option value="01">${this._translations.months[0]}</option>
                    <option value="02">${this._translations.months[1]}</option>
                    <option value="03">${this._translations.months[2]}</option>
                    <option value="04">${this._translations.months[3]}</option>
                    <option value="05">${this._translations.months[4]}</option>
                    <option value="06">${this._translations.months[5]}</option>
                    <option value="07">${this._translations.months[6]}</option>
                    <option value="08">${this._translations.months[7]}</option>
                    <option value="09">${this._translations.months[8]}</option>
                    <option value="10">${this._translations.months[9]}</option>
                    <option value="11">${this._translations.months[10]}</option>
                    <option value="12">${this._translations.months[11]}</option>
                </select>
                <input type="number" data-timeslider="rangeminday" min="1" max="31" step="1"  class="leaflet-ohm-timeslider-rangeinputs-day" aria-label="${this._translations.daterange_min_day_title}" />
                <input type="number" data-timeslider="rangeminyear" min="1" max="${maxabsyear}" step="1" class="leaflet-ohm-timeslider-rangeinputs-year" aria-label="${this._translations.daterange_min_year_title}" />
                <select data-timeslider="rangemincebce" aria-label="${this._translations.daterange_min_cebce_title}">
                    <option value="+">${text_ce}</option>
                    <option value="-">${text_bce}</option>
                </select>
            </div>
            <div class="leaflet-ohm-timeslider-rangeinputs-separator">
                -
            </div>
            <div class="leaflet-ohm-timeslider-rangeinputs-maxdate">
                <select data-timeslider="rangemaxmonth" aria-label="${this._translations.daterange_max_month_title}">
                    <option value="01">${this._translations.months[0]}</option>
                    <option value="02">${this._translations.months[1]}</option>
                    <option value="03">${this._translations.months[2]}</option>
                    <option value="04">${this._translations.months[3]}</option>
                    <option value="05">${this._translations.months[4]}</option>
                    <option value="06">${this._translations.months[5]}</option>
                    <option value="07">${this._translations.months[6]}</option>
                    <option value="08">${this._translations.months[7]}</option>
                    <option value="09">${this._translations.months[8]}</option>
                    <option value="10">${this._translations.months[9]}</option>
                    <option value="11">${this._translations.months[10]}</option>
                    <option value="12">${this._translations.months[11]}</option>
                </select>
                <input type="number" data-timeslider="rangemaxday" min="1" max="31" step="1" class="leaflet-ohm-timeslider-rangeinputs-day" aria-label="${this._translations.daterange_max_day_title}" />
                <input type="number" data-timeslider="rangemaxyear" min="1" max="${maxabsyear}" step="1" class="leaflet-ohm-timeslider-rangeinputs-year" aria-label="${this._translations.daterange_max_year_title}" />
                <select data-timeslider="rangemaxcebce" aria-label="${this._translations.daterange_max_cebce_title}">
                    <option value="+">${text_ce}</option>
                    <option value="-">${text_bce}</option>
                </select>
            </div>
            <div class="leaflet-ohm-timeslider-rangeinputs-submit">
                <button data-timeslider="rangesubmit" aria-label="${this._translations.daterange_submit_title}">${this._translations.daterange_submit_text}</button>
            </div>
        </div>
        <div class="leaflet-ohm-timeslider-datereadout">
            <span data-timeslider="datereadout"></span>
            <button type="button" data-timeslider="datepickeropen" aria-label="${this._translations.datepicker_title}"></button>
        </div>
        <div class="leaflet-ohm-timeslider-slider-wrap">
            <div>
                ${this._translations.ymd_placeholder_short}
                <br/>
                <span data-timeslider="rangestartreadout"></span>
            </div>
            <div>
                <input type="range" min="" max="" step="${this.constants.onedaystep}" class="leaflet-ohm-timeslider-sliderbar" data-timeslider="slider" aria-label="${this._translations.slider_description}" />
            </div>
            <div>
                ${this._translations.ymd_placeholder_short}
                <br/>
                <span data-timeslider="rangeendreadout"></span>
            </div>
        </div>
        <div class="leaflet-ohm-timeslider-playcontrols-wrap">
            <div class="leaflet-ohm-timeslider-playcontrols-buttons">
                <span data-timeslider="reset" role="button" tabindex="0" title="${this._translations.resetbutton_title}"></span>
                <span data-timeslider="play" role="button" tabindex="0" title="${this._translations.playbutton_title}"></span>
                <span data-timeslider="pause" role="button" tabindex="0" title="${this._translations.pausebutton_title}"></span>
                <span data-timeslider="prev" role="button" tabindex="0" title="${this._translations.backwardbutton_title}"></span>
                <span data-timeslider="next" role="button" tabindex="0" title="${this._translations.forwardbutton_title}"></span>
            </div>
            <div class="leaflet-ohm-timeslider-playcontrols-settings">
                <div>
                    <strong>${this._translations.stepamount_title}</strong>
                    <select data-timeslider="stepamount" aria-label="${this._translations.stepamount_selector_title}">
                        <option value="1day">${this._translations.stepamount_1day}</option>
                        <option value="1month">${this._translations.stepamount_1month}</option>
                        <option value="1year">${this._translations.stepamount_1year}</option>
                        <option value="10year">${this._translations.stepamount_10year}</option>
                        <option value="100year">${this._translations.stepamount_100year}</option>
                    </select>
                </div>
                <div>
                    <strong>${this._translations.stepinterval_title}</strong>
                    <select data-timeslider="stepinterval" aria-label="${this._translations.stepinterval_selector_title}">
                        <option value="5">${this._translations.stepinterval_5sec}</option>
                        <option value="2">${this._translations.stepinterval_2sec}</option>
                        <option value="1">${this._translations.stepinterval_1sec}</option>
                    </select>
                </div>
                <div>
                    <button data-timeslider="autoplaysubmit" aria-label="${this._translations.autoplay_submit_title}">${this._translations.autoplay_submit_text}</button>
                </div>
            </div>
        </div>
        `;

        const datepickermodal = L.DomUtil.create('div', 'leaflet-ohm-timeslider-modal leaflet-ohm-timeslider-datepicker');
        L.DomEvent.disableClickPropagation(datepickermodal);
        L.DomEvent.disableScrollPropagation(datepickermodal);
        this._datepickermodal = datepickermodal;

        datepickermodal.innerHTML = `
        <div class="leaflet-ohm-timeslider-modal-background"></div>
        <div class="leaflet-ohm-timeslider-modal-panel">
            <div class="leaflet-ohm-timeslider-modal-content">
                <div class="leaflet-ohm-timeslider-modal-head">
                    <h4>${this._translations.datepicker_title}</h4>
                    <span class="leaflet-ohm-timeslider-modal-close" aria-label="${this._translations.close}" data-timeslider="datepickerclose">&times;</span>
                </div>
                <hr />
                <div class="leaflet-ohm-timeslider-modal-body">
                    <p>${this._translations.datepicker_text}</p>
                    <select data-timeslider="datepickermonth" aria-label="${this._translations.datepicker_month}">
                        <option value="01">${this._translations.months[0]}</option>
                        <option value="02">${this._translations.months[1]}</option>
                        <option value="03">${this._translations.months[2]}</option>
                        <option value="04">${this._translations.months[3]}</option>
                        <option value="05">${this._translations.months[4]}</option>
                        <option value="06">${this._translations.months[5]}</option>
                        <option value="07">${this._translations.months[6]}</option>
                        <option value="08">${this._translations.months[7]}</option>
                        <option value="09">${this._translations.months[8]}</option>
                        <option value="10">${this._translations.months[9]}</option>
                        <option value="11">${this._translations.months[10]}</option>
                        <option value="12">${this._translations.months[11]}</option>
                    </select>
                    <input type="number" data-timeslider="datepickerday" min="1" max="31" step="1"  class="leaflet-ohm-timeslider-datepicker-day" aria-label="${this._translations.datepicker_day}" />
                    <input type="number" data-timeslider="datepickeryear" min="1" max="${maxabsyear}" step="1" class="leaflet-ohm-timeslider-datepicker-year" aria-label="${this._translations.datepicker_year}" />
                    <select data-timeslider="datepickercebce" aria-label="${this._translations.datepicker_cebce}">
                        <option value="+">${text_ce}</option>
                        <option value="-">${text_bce}</option>
                    </select>

                    <p></p>
                    <hr />
                </div>
                <div class="leaflet-ohm-timeslider-modal-foot">
                    <button data-timeslider="datepickersubmit">${this._translations.datepicker_submit_text}</button>
                    <button data-timeslider="datepickercancel">${this._translations.datepicker_cancel_text}</button>
                </div>
            </div>
        </div>
        `;

        // attach events: change, press enter, slide, play and pause, ...
        this.controls = {};
        this.controls.slider = container.querySelector('[data-timeslider="slider"]');
        this.controls.rangeminui = container.querySelector('div.leaflet-ohm-timeslider-rangeinputs-mindate');
        this.controls.rangeminmonth = container.querySelector('select[data-timeslider="rangeminmonth"]');
        this.controls.rangeminday = container.querySelector('input[data-timeslider="rangeminday"]');
        this.controls.rangeminyear = container.querySelector('input[data-timeslider="rangeminyear"]');
        this.controls.rangemincebce = container.querySelector('select[data-timeslider="rangemincebce"]');
        this.controls.rangemaxui = container.querySelector('div.leaflet-ohm-timeslider-rangeinputs-maxdate');
        this.controls.rangemaxmonth = container.querySelector('select[data-timeslider="rangemaxmonth"]');
        this.controls.rangemaxday = container.querySelector('input[data-timeslider="rangemaxday"]');
        this.controls.rangemaxyear = container.querySelector('input[data-timeslider="rangemaxyear"]');
        this.controls.rangemaxcebce = container.querySelector('select[data-timeslider="rangemaxcebce"]');
        this.controls.rangesubmit = container.querySelector('button[data-timeslider="rangesubmit"]');
        this.controls.playbutton = container.querySelector('[data-timeslider="play"]');
        this.controls.pausebutton = container.querySelector('[data-timeslider="pause"]');
        this.controls.playnext = container.querySelector('[data-timeslider="next"]');
        this.controls.playprev = container.querySelector('[data-timeslider="prev"]');
        this.controls.playreset = container.querySelector('[data-timeslider="reset"]');
        this.controls.stepamount = container.querySelector('[data-timeslider="stepamount"]');
        this.controls.stepinterval = container.querySelector('[data-timeslider="stepinterval"]');
        this.controls.autoplaysubmit = container.querySelector('[data-timeslider="autoplaysubmit"]');
        this.controls.rangestartreadout = container.querySelector('[data-timeslider="rangestartreadout"]');
        this.controls.rangeendreadout = container.querySelector('[data-timeslider="rangeendreadout"]');
        this.controls.datereadout = container.querySelector('[data-timeslider="datereadout"]');
        this.controls.expandcollapse = container.querySelector('[data-timeslider="expandcollapse"]');
        this.controls.datepickeropen = container.querySelector('button[data-timeslider="datepickeropen"]');
        this.controls.datepickerclose = datepickermodal.querySelector('span[data-timeslider="datepickerclose"]');
        this.controls.datepickermonth = datepickermodal.querySelector('select[data-timeslider="datepickermonth"]');
        this.controls.datepickerday = datepickermodal.querySelector('input[data-timeslider="datepickerday"]');
        this.controls.datepickeryear = datepickermodal.querySelector('input[data-timeslider="datepickeryear"]');
        this.controls.datepickercebce = datepickermodal.querySelector('select[data-timeslider="datepickercebce"]');
        this.controls.datepickersubmit = datepickermodal.querySelector('button[data-timeslider="datepickersubmit"]');
        this.controls.datepickercancel = datepickermodal.querySelector('button[data-timeslider="datepickercancel"]');

        L.DomEvent.on(this.controls.rangesubmit, 'click', () => {
            this.setRangeFromSelectors();
        });
        L.DomEvent.on(this.controls.rangesubmit, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.rangeminyear, 'change', () => {
            if (parseInt(this.controls.rangeminyear.value) < parseInt(this.controls.rangeminyear.min)) this.controls.rangeminyear.value = this.controls.rangeminyear.min;
            else if (parseInt(this.controls.rangeminyear.value) > parseInt(this.controls.rangeminyear.max)) this.controls.rangeminyear.value = this.controls.rangeminyear.max;

            this.adjustDateRangeInputsForSelectedMonthAndYear();
            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.rangeminmonth, 'input', () => {
            this.adjustDateRangeInputsForSelectedMonthAndYear();
            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.rangeminday, 'change', () => {
            if (parseInt(this.controls.rangeminday.value) < parseInt(this.controls.rangeminday.min)) this.controls.rangeminday.value = this.controls.rangeminday.min;
            else if (parseInt(this.controls.rangeminday.value) > parseInt(this.controls.rangeminday.max)) this.controls.rangeminday.value = this.controls.rangeminday.max;

            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.rangemincebce, 'change', () => {
            this.adjustDateRangeInputsForSelectedMonthAndYear();
            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.rangemaxyear, 'change', () => {
            if (parseInt(this.controls.rangemaxyear.value) < parseInt(this.controls.rangemaxyear.min)) this.controls.rangemaxyear.value = this.controls.rangemaxyear.min;
            else if (parseInt(this.controls.rangemaxyear.value) > parseInt(this.controls.rangemaxyear.max)) this.controls.rangemaxyear.value = this.controls.rangemaxyear.max;

            this.adjustDateRangeInputsForSelectedMonthAndYear();
            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.rangemaxmonth, 'input', () => {
            this.adjustDateRangeInputsForSelectedMonthAndYear();
            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.rangemaxday, 'change', () => {
            if (parseInt(this.controls.rangemaxday.value) < parseInt(this.controls.rangemaxday.min)) this.controls.rangemaxday.value = this.controls.rangemaxday.min;
            else if (parseInt(this.controls.rangemaxday.value) > parseInt(this.controls.rangemaxday.max)) this.controls.rangemaxday.value = this.controls.rangemaxday.max;

            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.rangemaxcebce, 'change', () => {
            this.adjustDateRangeInputsForSelectedMonthAndYear();
            this.setDateRangeFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.slider, 'input', () => {
            this.setDateFromSlider();
        });
        L.DomEvent.on(this.controls.playbutton, 'click', () => {
            this.autoplayStart();
            this.controls.pausebutton.focus();
        });
        L.DomEvent.on(this.controls.playbutton, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.pausebutton, 'click', () => {
            this.autoplayPause();
            this.controls.playbutton.focus();
        });
        L.DomEvent.on(this.controls.pausebutton, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.playnext, 'click', () => {
            this.sliderForwardOneStep();
        });
        L.DomEvent.on(this.controls.playnext, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.playprev, 'click', () => {
            this.sliderBackOneStep();
        });
        L.DomEvent.on(this.controls.playprev, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.playreset, 'click', () => {
            this.setDate(this.getRange()[0]);
        });
        L.DomEvent.on(this.controls.playreset, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.autoplaysubmit, 'click', () => {
            this.setAutoplayFromPickers();
        });
        L.DomEvent.on(this.controls.stepamount, 'input', () => {
            this.setAutoPlayFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.stepinterval, 'input', () => {
            this.setAutoPlayFormAsOutOfSync(true);
        });
        L.DomEvent.on(this.controls.autoplaysubmit, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.expandcollapse, 'click', () => {
            this.controlToggle();
        });
        L.DomEvent.on(this.controls.expandcollapse, 'keydown', (event) => {
            if (event.key == 'Enter' || event.key == 'Space') event.target.click();
        });
        L.DomEvent.on(this.controls.datepickeropen, 'click', () => {
            this.datepickerOpen();
        });
        L.DomEvent.on(this.controls.datepickerclose, 'click', () => {
            this.datepickerClose();
        });
        L.DomEvent.on(this.controls.datepickercancel, 'click', () => {
            this.controls.datepickerclose.click();
        });
        L.DomEvent.on(this.controls.datepickersubmit, 'click', () => {
            this.datepickerSubmit();
        });
        L.DomEvent.on(this.controls.datepickersubmit, 'keydown', (event) => {
            if (event.key == 'Escape') this.controls.datepickerclose.click();
        });
        L.DomEvent.on(this.controls.datepickermonth, 'input', () => {
            this.adjustDatePickerInputsForSelectedMonthAndYear();
        });
        L.DomEvent.on(this.controls.datepickerday, 'change', () => {
            if (parseInt(this.controls.datepickerday.value) < parseInt(this.controls.datepickerday.min)) this.controls.datepickerday.value = this.controls.datepickerday.min;
            else if (parseInt(this.controls.datepickerday.value) > parseInt(this.controls.datepickerday.max)) this.controls.datepickerday.value = this.controls.datepickerday.max;
        });
        L.DomEvent.on(this.controls.datepickeryear, 'change', () => {
            if (parseInt(this.controls.datepickeryear.value) < parseInt(this.controls.datepickeryear.min)) this.controls.datepickeryear.value = this.controls.datepickeryear.min;
            else if (parseInt(this.controls.datepickeryear.value) > parseInt(this.controls.datepickeryear.max)) this.controls.datepickeryear.value = this.controls.datepickeryear.max;

            this.adjustDatePickerInputsForSelectedMonthAndYear();
        });
        L.DomEvent.on(this.controls.datepickercebce, 'change', () => {
            this.adjustDatePickerInputsForSelectedMonthAndYear();
        });

        // shuffle the layout, swapping the range elements' month & day pickers, to fit their browser's date format M/D/Y or D/M/Y
        // the layout already in place above is M/D/Y so no action needed if that's still the case
        this.preferreddateformat = 'mdy';
        {
            const testdate = new Date(Date.UTC(2000, 11, 31, 12, 0, 0, 0));
            testdate.setFullYear(2000);
            const formatted = new Intl.DateTimeFormat(navigator.languages, {year: 'numeric', month: 'numeric', day: 'numeric'}).format(testdate);
            const dateparts = formatted.split(/\D/);

            if (dateparts.indexOf('31') == 1) this.preferreddateformat = 'mdy';
            else if (dateparts.indexOf('31') == 0) this.preferreddateformat = 'dmy';
        }
        if (this.preferreddateformat == 'dmy') {
            this.controls.rangeminui.insertBefore(this.controls.rangeminday, this.controls.rangeminmonth);
            this.controls.rangeminui.insertBefore(document.createTextNode(' '), this.controls.rangeminmonth);

            this.controls.rangemaxui.insertBefore(this.controls.rangemaxday, this.controls.rangemaxmonth);
            this.controls.rangemaxui.insertBefore(document.createTextNode(' '), this.controls.rangemaxmonth);
        }

        // set up autoplay state
        this.autoplay = {};
        this.autoplay.timer = null; // will become a setInterval(); see autoplayStart() and autoplayPause()
        this.setStepAmount(this.options.stepAmount); // this.autoplay.stepamount
        this.setStepInterval(this.options.stepInterval); // this.autoplay.stepinterval
        this.autoplayPause();

        // get started!
        this.controlExpand();
        setTimeout(() => {
            this._addDateFiltersTovectorLayers();
            this.refreshUiAndFiltering();
            this.options.onReady.call(this);
        }, 0.1 * 1000);

        // done
        this._map = map;
        return container;
    },

    onRemove: function () {
        // stop autoplay if it's running
        this.autoplayPause();

        // remove our injected date filters
        this._removeDateFiltersFromvectorLayers();
    },

    //
    // the core functions for the slider and filtering by date inputs
    //
    getDate: function (asdecimal=false) {
        const thedate = this.state.date;
        return asdecimal ? decimaldate.iso2dec(thedate) : thedate;
    },
    setDate: function (newdatestring, redraw=true) {
        // validate, then set the date
        const ymd = this.splitYmdParts(newdatestring);
        if (! this.isValidDate(newdatestring)) {
            console.error(`OHMTimeSlider: setDate() invalid date: ${newdatestring}`);
            return;
        }
        this.state.date = newdatestring;

        // if the current date is outside of the new range, set the date to the start/end of this range
        // that would implicitly redraw the slider, so also handle the date being in range and trigger the redraw too
        const isoutofrange = this.checkDateOutOfRange();
        if (isoutofrange < 0) this.setRange([newdatestring, this.getRange()[1]], false);
        else if (isoutofrange > 0) this.setRange([this.getRange()[0], newdatestring], false);

        // done updating; refresh UI to this new state, and re-filter
        if (redraw) {
            this.refreshUiAndFiltering();
        }

        // call the onDateChange callback
        this.options.onDateChange.call(this, this.getDate());
    },
    getRange: function (asdecimal=false) {
        const therange = this.state.range.slice();
        if (asdecimal) {
            therange[0] = decimaldate.iso2dec(therange[0]);
            therange[1] = decimaldate.iso2dec(therange[1]);
        }
        return therange;
    },
    setRange: function (newdatepair, redraw=true) {
        // validate, then set the date range
        let newmindate = newdatepair[0];
        let newmaxdate = newdatepair[1];
        let ymdmin = this.splitYmdParts(newmindate);
        let ymdmax = this.splitYmdParts(newmaxdate);

        if (! this.isValidDate(newmindate)) {
            console.error(`OHMTimeSlider: setRange() invalid range: ${newmindate} - ${newmaxdate}`);
            return;
        }

        const decmin = decimaldate.iso2dec(newmindate);
        const decmax = decimaldate.iso2dec(newmaxdate);
        if (decmin >= decmax) {
            console.error(`OHMTimeSlider: setRange() min date must be less than max date: ${newmindate} - ${newmaxdate}`);
            return;
        }

        this.state.range[0] = newmindate;
        this.state.range[1] = newmaxdate;

        // if the current date is outside of the new range, set the date to the start/end of this range
        // that would implicitly redraw the slider, so also handle the date being in range and trigger the redraw too
        const isoutofrange = this.checkDateOutOfRange();
        if (isoutofrange < 0) this.setDate(newmaxdate, false);
        else if (isoutofrange > 0) this.setDate(newmindate, false);

        // done updating; refresh UI to this new state, and re-filter
        if (redraw) {
            this.refreshUiAndFiltering();
        }

        // call the onRangeChange callback
        this.options.onRangeChange.call(this, this.getRange());
    },
    setDateFromSlider: function (redraw=true) {
        const newdatestring = decimaldate.dec2iso(this.controls.slider.value);
        this.setDate(newdatestring, redraw);
    },
    setRangeFromSelectors: function () {
        // check that the year isn't out of range; if so, cap it
        let miny = parseInt(this.controls.rangeminyear.value);
        if (this.controls.rangemincebce.value == '-') miny *= -1;
        if (miny < this.constants.minYear) miny = this.constants.minYear;
        if (miny > this.constants.maxYear) miny = this.constants.maxYear;

        let maxy = parseInt(this.controls.rangemaxyear.value);
        if (this.controls.rangemaxcebce.value == '-') maxy *= -1;
        if (maxy < this.constants.minYear) maxy = this.constants.minYear;
        if (maxy > this.constants.maxYear) maxy = this.constants.maxYear;

        const minm = this.zeroPadToLength(this.controls.rangeminmonth.value, 2);
        const maxm = this.zeroPadToLength(this.controls.rangemaxmonth.value, 2);

        const mind = this.zeroPadToLength(this.controls.rangeminday.value, 2);
        const maxd = this.zeroPadToLength(this.controls.rangemaxday.value, 2);

        // concatenate to make the ISO string, since we already have them as 2-digit month & day, and year can be any number of digits
        // the internal ISO date, if BCE then subtract 1 from abs(year) because ISO 8601 is offset by 1: 0000 is 1 BCE (-1), -0001 is 2 BCE (-2), and so on...
        // conversely refreshUiAndFiltering() will -1 to get from ISO value (-499) to input value (500 BCE)
        const mindate = `${miny > 0 ? miny : miny + 1}-${minm}-${mind}`;
        const maxdate = `${maxy > 0 ? maxy : maxy + 1}-${maxm}-${maxd}`;

        if (! this.isValidDate(mindate)) return console.error(`OHMTimeSlider setRangeFromSelectors() invalid date: ${mindate}`);
        if (! this.isValidDate(maxdate)) return console.error(`OHMTimeSlider setRangeFromSelectors() invalid date: ${maxdate}`);

        this.setRange([ mindate, maxdate ]);
        this.setDateRangeFormAsOutOfSync(false);
    },
    adjustDateRangeInputsForSelectedMonthAndYear: function () {
        // cap the day picker to the number of days in that month, accounting for leap years and the CE/BCE picker
        // then trigger a change event, to change their value if it is now out of range
        let miny = parseInt(this.controls.rangeminyear.value);
        if (this.controls.rangemincebce.value == '-') miny *= -1;
        const minm = parseInt(this.controls.rangeminmonth.value);

        let maxy = parseInt(this.controls.rangemaxyear.value);
        if (this.controls.rangemaxcebce.value == '-') maxy *= -1;
        const maxm = parseInt(this.controls.rangemaxmonth.value);

        this.controls.rangeminday.max = decimaldate.daysinmonth(miny, minm);
        this.controls.rangemaxday.max = decimaldate.daysinmonth(maxy, maxm);
        this.controls.rangeminday.dispatchEvent(new Event('change'));
        this.controls.rangemaxday.dispatchEvent(new Event('change'));
    },
    setDateRangeFormAsOutOfSync: function (outofsync) {
        // color the Set button to show that they need to click it
        if (outofsync) {
            this.controls.rangesubmit.classList.add('leaflet-ohm-timeslider-outofsync');
        } else {
            this.controls.rangesubmit.classList.remove('leaflet-ohm-timeslider-outofsync');
        }
    },
    refreshUiAndFiltering: function () {
        // redraw the UI
        // set the range controls to the internal range
        // set the slider to the new date range & selected date
        // apply filtering

        // set the date selectors to show the new range: year, month, day for start & end of range
        const rangeminymd = this.splitYmdParts(this.state.range[0]);
        const rangemaxymd = this.splitYmdParts(this.state.range[1]);

        const mincebce = parseInt(rangeminymd[0]) < 0 ? '-' : '+';
        const maxcebce = parseInt(rangemaxymd[0]) < 0 ? '-' : '+';

        // for BCE dates, ISO 8601 is off by 1 from what we want to show: 1 BCE = 0000, 2 BCE = -0001, ... so -1 to the year for display purposes
        // conversely setRangeFromSelectors() will +1 to get from input value (500 BCE) to ISO value (-499)
        let minyshow = parseInt(rangeminymd[0]);
        let maxyshow = parseInt(rangemaxymd[0]);
        if (minyshow < 0) minyshow -= 1;
        if (maxyshow < 0) maxyshow -= 1;

        if (this.controls.rangeminyear.value != rangeminymd[0]) this.controls.rangeminyear.value = Math.abs(minyshow);
        if (this.controls.rangeminmonth.value != rangeminymd[1]) this.controls.rangeminmonth.value = this.zeroPadToLength(rangeminymd[1], 2);
        if (this.controls.rangeminday.value != rangeminymd[2]) this.controls.rangeminday.value = parseInt(rangeminymd[2]);
        if (this.controls.rangemincebce.value != mincebce) this.controls.rangemincebce.value = mincebce;

        if (this.controls.rangemaxyear.value != rangemaxymd[0]) this.controls.rangemaxyear.value = Math.abs(maxyshow);
        if (this.controls.rangemaxmonth.value != rangemaxymd[1]) this.controls.rangemaxmonth.value = this.zeroPadToLength(rangemaxymd[1], 2);
        if (this.controls.rangemaxday.value != rangemaxymd[2]) this.controls.rangemaxday.value = parseInt(rangemaxymd[2]);
        if (this.controls.rangemaxcebce.value != maxcebce) this.controls.rangemaxcebce.value = maxcebce;

        // adjust the slider and position the handle, to the current range & date
        const decrange = this.getRange(true);
        const deccurrent = this.getDate(true);
        this.controls.slider.min = decrange[0];
        this.controls.slider.max = decrange[1];
        this.controls.slider.value = deccurrent;

        // add color gradient to the slider to color before & after
        // thanks to https://stackoverflow.com/a/57153340
        const slidevalue = (this.controls.slider.value - this.controls.slider.min) / (this.controls.slider.max - this.controls.slider.min) * 100;
        this.controls.slider.style.background = `linear-gradient(to right, ${this.options.sliderColorBefore} 0%, ${this.options.sliderColorBefore} ${slidevalue}%, ${this.options.sliderColorAfter} ${slidevalue}%, ${this.options.sliderColorAfter} 100%)`;

        // fill in the date readouts, showing the range dates in mm/dd/yyyy format and the current date in long-word fprmat
        const ymdrange = this.getRange();
        const ymdcurrent = this.getDate();
        this.controls.rangestartreadout.innerText = this.formatDateShort(ymdrange[0]);
        this.controls.rangeendreadout.innerText = this.formatDateShort(ymdrange[1]);
        this.controls.datereadout.innerText = this.formatDateLong(ymdcurrent);

        // apply the filtering
        this.applyDateFiltering();
    },
    applyDateFiltering: function () {
        this._applyDateFilterToLayers();
    },

    //
    // the date filtering magic, adding new filter clauses to the vector style's layers
    // and then rewriting them on the fly to show features matching the date range
    //
    _getFilteredvectorLayers () {
        const mapstyle = this.getRealGlMap().getStyle();
        if (! mapstyle.sources[this.options.vectorSourceName]) throw `OHMTimeSlider: vector layer has no source named ${this.options.vectorSourceName}`;

        const filterlayers = mapstyle.layers.filter((layer) => layer.source == this.options.vectorSourceName);
        return filterlayers;
    },
    _addDateFiltersTovectorLayers: function () {
        // inject the osmfilteringclause, ensuring it falls into sequence as filters[1]
        // right now that filter is always true, but filters[1] will be rewritten by _applyDateFilterToLayers() to apply date filtering
        //
        // warning: we are mutating someone else's map style in-place, and they may not be expecting that
        // if they go and apply their own filters later, it could get weird
        const osmfilteringclause = ["==", "nodatefilter", ["literal", "nodatefilter"]];
        const vecmap = this.getRealGlMap();
        const layers = this._getFilteredvectorLayers();

        layers.forEach(function (layer) {
            const oldfilters = vecmap.getFilter(layer.id);
            layer.oldfiltersbackup = oldfilters ? oldfilters.slice() : oldfilters;  // keep a backup of the original filters for _removeDateFiltersFromvectorLayers()

            let newfilters;
            if (oldfilters === undefined) {  // no filter at all, so create one
                newfilters = [
                    "all",
                    osmfilteringclause,
                ];
                // console.debug([ `OHMTimeSlider: _addDateFiltersToVectorLayers() NoFilter ${layer.id}`, oldfilters, newfilters ]);
            }
            else if (oldfilters[0] === 'all') {  // all clause; we can just insert our clause into position as filters[1]
                newfilters = oldfilters.slice();
                newfilters.splice(1, 0, osmfilteringclause);
                // console.debug([ `OHMTimeSlider: _addDateFiltersToVectorLayers() AllFilter ${layer.id}`, oldfilters, newfilters ]);
            }
            else if (oldfilters[0] === 'any') {  // any clause; wrap theirs into a giant clause, prepend ours with an all
                newfilters = [
                    "all",
                    osmfilteringclause,
                    [ oldfilters ],
                ];
                // console.debug([ `OHMTimeSlider: _addDateFiltersToVectorLayers() AnyFilter ${layer.id}`, oldfilters, newfilters ]);
            }
            else if (Array.isArray(oldfilters)) {  // an array forming a single, simple-style filtering clause; rewrap as an "all"
                newfilters = [
                    "all",
                    osmfilteringclause,
                    oldfilters
                ];
                // console.debug([ `OHMTimeSlider: _addDateFiltersToVectorLayers() ArrayFilter ${layer.id}`, oldfilters, newfilters ]);
            }
            else {
                // some other condition I had not expected and need to figure out
                console.error(oldfilters);
                throw `OHMTimeSlider: _addDateFiltersToVectorLayers() got unexpected filtering condition on layer ${layer.id}`;
            }

            // apply the new filter, with the placeholder "eternal features" filter now prepended
            vecmap.setFilter(layer.id, newfilters);
        });
    },
    _removeDateFiltersFromvectorLayers: function () {
        // in _addDateFiltersToVectorLayers() we rewrote the layers' filters to support date filtering, but we also kept a backup
        // restore that backup now, so the layers are back where they started
        const vecmap = this.getRealGlMap();
        this._getFilteredvectorLayers().forEach((layer) => {
            vecmap.setFilter(layer.id, layer.oldfiltersbackup);
        });
    },
    _applyDateFilterToLayers: function () {
        // back in _addDateFiltersToVectorLayers() we prepended a filtering clause as filters[1] which filters for "eternal" features lacking a OSM ID
        // here in _applyDateFilterToLayers() we add a second part to that, for features with a start_date and end_date fitting our date
        // the new date filtering expression is:
        // numerical start date either absent (beginning/end of time) or else within range, and same for numerical end date
        const deccurrent = this.getDate(true);
        const datesubfilter = [
            'all',
            [
                'any',
                ['!', ['has', 'start_decdate']],
                ['<=', ['to-number', ['get', 'start_decdate'], -Infinity], ['literal', deccurrent]]
            ],
            [
                'any',
                ['!', ['has', 'end_decdate']],
                ['>=', ['to-number', ['get', 'end_decdate'], Infinity], ['literal', deccurrent]]
            ],
        ];

        const vecmap = this.getRealGlMap();
        const layers = this._getFilteredvectorLayers();
        layers.forEach((layer) => {
            const newfilters = vecmap.getFilter(layer.id).slice();
            newfilters[1] = datesubfilter.slice();
            vecmap.setFilter(layer.id, newfilters);
        });
    },

    //
    // playback functionality, to automagically move the slider
    //
    autoplayIsRunning: function () {
        return this.autoplay.timer ? true : false;
    },
    getStepAmount: function () {
        return this.autoplay.stepamount;
    },
    setStepAmount: function (newvalue) {
        // make sure this is a valid option
        const isoption = this.controls.stepamount.querySelector(`option[value="${newvalue}"]`);
        if (! isoption) return console.error(`OHMTimeSlider: setStepAmount() invalid option: ${newspeed}`);

        // set the picker and set the internal value
        this.controls.stepamount.value = newvalue;
        this.autoplay.stepamount = newvalue;

        // if we were playing, pause and restart at the new amount & interval
        if (this.autoplayIsRunning()) {
            this.autoplayPause();
            this.autoplayStart();
        }
    },
    getStepInterval: function () {
        return this.autoplay.stepinterval;
    },
    setStepInterval: function (newvalue) {
        // make sure this is a valid option
        const isoption = this.controls.stepinterval.querySelector(`option[value="${newvalue}"]`);
        if (! isoption) return console.error(`OHMTimeSlider: setStepInterval() invalid option: ${newvalue}`);

        // set the picker and set the internal value
        this.controls.stepinterval.value = newvalue;
        this.autoplay.stepinterval = parseFloat(newvalue);

        // if we were playing, pause and restart at the new amount & interval
        if (this.autoplayIsRunning()) {
            this.autoplayPause();
            this.autoplayStart();
        }
    },
    sliderForwardOneStep: function () {
        const step = this.getStepAmount();
        const amount = parseInt( step.match(/^(\d+)(\w+)$/)[1] );
        const unit = step.match(/^(\d+)(\w+)$/)[2];
        const olddate = this.getDate();
        const newdate = this.timeDelta(olddate, unit, amount);

        const oldvalue = this.controls.slider.value;
        const newvalue = decimaldate.iso2dec(newdate);
        if (newvalue != oldvalue) {
            this.controls.slider.value = newvalue;
            this.controls.slider.dispatchEvent(new Event('input'));
        }
    },
    sliderBackOneStep: function () {
        const step = this.getStepAmount();
        const amount = parseInt( step.match(/^(\d+)(\w+)$/)[1] );
        const unit = step.match(/^(\d+)(\w+)$/)[2];
        const olddate = this.getDate();
        const newdate = this.timeDelta(olddate, unit, -amount);

        const oldvalue = this.controls.slider.value;
        const newvalue = decimaldate.iso2dec(newdate);
        if (newvalue != oldvalue) {
            this.controls.slider.value = newvalue;
            this.controls.slider.dispatchEvent(new Event('input'));
        }
    },
    setAutoplayFromPickers: function () {
        // peek at the interval & amount select elements, call setStepAmount() and setStepInterval() to match
        this.setStepAmount(this.controls.stepamount.value);
        this.setStepInterval(this.controls.stepinterval.value);
        this.setAutoPlayFormAsOutOfSync();
    },
    setAutoPlayFormAsOutOfSync: function (outofsync) {
        // color the Set button to show that they need to click it
        if (outofsync) {
            this.controls.autoplaysubmit.classList.add('leaflet-ohm-timeslider-outofsync');
        } else {
            this.controls.autoplaysubmit.classList.remove('leaflet-ohm-timeslider-outofsync');
        }
    },
    autoplayStart: function () {
        this.controls.playbutton.style.display = 'none';
        this.controls.pausebutton.style.display = '';
        if (this.autoplay.timer) return; // already running

        this.autoplay.timer = setInterval(() => {
            this.sliderForwardOneStep();
        }, this.getStepInterval() * 1000);
    },
    autoplayPause: function () {
        this.controls.playbutton.style.display = '';
        this.controls.pausebutton.style.display = 'none';
        if (! this.autoplay.timer) return; // not running

        clearInterval(this.autoplay.timer);
        this.autoplay.timer = undefined;
    },

    //
    // expand/collapse the map control
    //
    controlToggle: function () {
        if (this.controlIsExpanded()) {
            this.controlCollapse();
        } else {
            this.controlExpand();
        }
    },
    controlIsExpanded: function () {
        return this.container.classList.contains('leaflet-ohm-timeslider-expanded');
    },
    controlExpand: function () {
        this.container.classList.add('leaflet-ohm-timeslider-expanded');
        this.container.classList.remove('leaflet-ohm-timeslider-collapsed');
    },
    controlCollapse: function () {
        this.container.classList.remove('leaflet-ohm-timeslider-expanded');
        this.container.classList.add('leaflet-ohm-timeslider-collapsed');
    },

    //
    // date picker modal
    //
    datepickerOpen: function () {
        // show the modal
        this._map._container.appendChild(this._datepickermodal);

        // set the date picker UI show the new range: year, month, day, bce/ce
        // for BCE dates, ISO 8601 is off by 1 from what we want to show: 1 BCE = 0000, 2 BCE = -0001, ... so -1 to the year for display purposes
        // conversely datepickerSubmit() will +1 to get from input value (500 BCE) to ISO value (-499)
        const datebits = this.splitYmdParts(this.getDate());
        const mincebce = parseInt(datebits[0]) < 0 ? '-' : '+';

        let minyshow = parseInt(datebits[0]);
        if (minyshow < 0) minyshow -= 1;

        if (this.controls.datepickeryear.value != datebits[0]) this.controls.datepickeryear.value = Math.abs(minyshow);
        if (this.controls.datepickermonth.value != datebits[1]) this.controls.datepickermonth.value = this.zeroPadToLength(datebits[1], 2);
        if (this.controls.datepickerday.value != datebits[2]) this.controls.datepickerday.value = parseInt(datebits[2]);
        if (this.controls.datepickercebce.value != mincebce) this.controls.datepickercebce.value = mincebce;

        // focus the month picker for easy access for keyboard users
        this.controls.datepickermonth.focus();
    },
    datepickerClose: function () {
        // hide the modal
        this._map._container.removeChild(this._datepickermodal);

        // focus the picker-open button, since that's probably how we got to the modal to close it
        this.controls.datepickeropen.focus();
    },
    datepickerSubmit: function () {
        // check that the year isn't out of range; if so, cap it
        let year = parseInt(this.controls.datepickeryear.value);
        if (this.controls.datepickercebce.value == '-') year *= -1;
        if (year < this.constants.yearear) year = this.constants.yearear;
        if (year > this.constants.maxYear) year = this.constants.maxYear;

        const month = this.zeroPadToLength(this.controls.datepickermonth.value, 2);

        const day = this.zeroPadToLength(this.controls.datepickerday.value, 2);

        // concatenate to make the ISO string, since we already have them as 2-digit month & day, and year can be any number of digits
        // the internal ISO date, if BCE then subtract 1 from abs(year) because ISO 8601 is offset by 1: 0000 is 1 BCE (-1), -0001 is 2 BCE (-2), and so on...
        // conversely datepickerOpen() will -1 to get from ISO value (-499) to input value (500 BCE)
        const yyyymmdd = `${year > 0 ? year : year + 1}-${month}-${day}`;
        if (! this.isValidDate(yyyymmdd)) return console.error(`OHMTimeSlider datepickerSubmit() invalid date: ${yyyymmdd}`);

        // set the date; this will implicitly set the slider as needed to include the date
        this.setDate(yyyymmdd);

        // close the datepicker
        this.datepickerClose();
    },
    adjustDatePickerInputsForSelectedMonthAndYear: function () {
        // cap the day picker to the number of days in that month, accounting for leap years and the CE/BCE picker
        // then trigger a change event, to change their value if it is now out of range
        let year = parseInt(this.controls.datepickeryear.value);
        if (this.controls.datepickercebce.value == '-') year *= -1;
        const month = parseInt(this.controls.datepickermonth.value);

        this.controls.datepickerday.max = decimaldate.daysinmonth(year, month);
        this.controls.datepickerday.dispatchEvent(new Event('change'));
    },

    //
    // other utility functions
    //
    isValidDate: function (datestring) {
        if (! datestring.match(/^\-?\d{1,4}-\d\d\-\d\d$/)) return false;

        const ymd = this.splitYmdParts(datestring);
        let y = parseInt(ymd[0]); if (y <= 0) y -= 1;
        const m = parseInt(ymd[1]);
        const d = parseInt(ymd[2]);
        if (! decimaldate.isvalidmonthday(y, m, d)) return false;

        return true;
    },
    zeroPadToLength: function (stringornumber, length) {
        const bits = (stringornumber + '').match(/^(\-?)(\d+)$/);
        let minus = '';

        if (bits.length == 2) {
            number = bits[1];
        }
        else if (bits.length == 3) {
            minus = bits[1];
            number = bits[2];
        }
        else throw `OHMTimeSlider: zeroPadToLength: invalid input ${stringornumber}`;

        let padded = number;
        while (padded.length < length) padded = '0' + padded;

        return minus + padded;
    },
    checkDateOutOfRange: function () {
        // return 0 if the current date is within the current range
        // return -1 if the current date is earlier than the range's min
        // return 1 if the current date is layer than the range's max
        const deccurrent = this.getDate(true);
        const decrange = this.getRange(true);

        if (deccurrent < decrange[0]) return -1;
        else if (deccurrent > decrange[1]) return 1;
        else return 0;
    },
    formatDateShort: function (yyyymmdd) {
        const [y, m, d] = this.splitYmdParts(yyyymmdd);
        const thedate = new Date(Date.UTC(y, m - 1, d, 12, 0, 0, 0));
        thedate.setUTCFullYear(y);

        const formatoptions = {timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric'};
        if (y <= 0) formatoptions.era = 'short';

        return new Intl.DateTimeFormat(navigator.languages, formatoptions).format(thedate);
    },
    formatDateLong: function (yyyymmdd) {
        const [y, m, d] = this.splitYmdParts(yyyymmdd);
        const thedate = new Date(Date.UTC(y, m - 1, d, 12, 0, 0, 0));
        thedate.setUTCFullYear(y);

        const formatoptions = {timeZone: 'UTC', year: 'numeric', month: 'long', day: 'numeric'};
        if (y <= 0) formatoptions.era = 'short';

        return new Intl.DateTimeFormat(navigator.languages, formatoptions).format(thedate);
    },
    getTextForBCE: function () {
        // use Intl.DateTimeFormat to generate BC/AD/BCE/CE text, so it matches to formatDateShort() et al which also use Intl.DateTimeFormat
        const testdate = new Date(Date.UTC(2020, 5, 15, 0, 0, 0, 0));
        testdate.setFullYear(-2000);

        const datebits = new Intl.DateTimeFormat(navigator.languages, {era: 'short'}).formatToParts(testdate);
        const era = datebits.filter(f => f.type == 'era')[0].value;
        return era;
    },
    getTextForCE: function () {
        // use Intl.DateTimeFormat to generate BC/AD/BCE/CE text, so it matches to formatDateShort() et al which also use Intl.DateTimeFormat
        const testdate = new Date(Date.UTC(2020, 5, 15, 0, 0, 0, 0));
        testdate.setFullYear(+2000);

        const datebits = new Intl.DateTimeFormat(navigator.languages, {era: 'short'}).formatToParts(testdate);
        const era = datebits.filter(f => f.type == 'era')[0].value;
        return era;
    },
    splitYmdParts: function (yyyymmdd) {
        // tease apart Y/M/D given possible - at the start
        let y, m, d;
        let bits = yyyymmdd.split('-');
        if (bits.length == 4) {
            y = -parseInt(bits[1]);
            m = parseInt(bits[2]);
            d = parseInt(bits[3]);
        } else {
            y = parseInt(bits[0]);
            m = parseInt(bits[1]);
            d = parseInt(bits[2]);
        }

        return [y, m, d];
    },
    timeDelta: function (yyyymmdd, units, amount) {
        const ymd = this.splitYmdParts(yyyymmdd);
        const y = ymd[0];
        const m = ymd[1];
        const d = ymd[2];

        // let JavaScript do the date calculation, wrapping years and months
        let newdate = new Date(y, m - 1, d);
        newdate.setFullYear(y); // JS treats <100 as 1900

        switch (units) {
            case 'year':
                newdate.setFullYear(y + amount);
                break;
            case 'month':
                newdate.setMonth(newdate.getMonth() + amount);
                break;
            case 'day':
                newdate.setDate(newdate.getDate() + amount);
                break;
        }

        // split out the yyyy-mm-dd part and hand it back
        return newdate.toISOString().split('T')[0];
    },
    getRealGlMap: function () {
        return this.options.vectorLayer._glMap;
    },
    listLanguages: function () {
        const langs = Object.keys(L.Control.OHMTimeSlider.Translations);
        langs.sort();
        return langs;
    },
});


L.Control.OHMTimeSlider.Translations = {};

L.Control.OHMTimeSlider.Translations['en'] = {
    close: "Close this panel",
    expandcollapse_title: "Maximize or minimize this panel",
    slider_description: "Select the date to display on the map",
    daterange_min_month_title: "Slider range, select starting month",
    daterange_min_day_title: "Slider range, select starting day",
    daterange_min_year_title: "Slider range, select starting year",
    daterange_min_cebce_title: "Slider range, select starting year as CE or BCE",
    daterange_max_month_title: "Slider range, select ending month",
    daterange_max_day_title: "Slider range, select ending day",
    daterange_max_year_title: "Slider range, select ending year",
    daterange_max_cebce_title: "Slider range, select ending year as CE or BCE",
    daterange_submit_text: "Set",
    daterange_submit_title: "Apply settings",
    range_title: "Range",
    stepamount_title: "Time Jump",
    stepamount_selector_title: "Select how much time to advance with each step",
    stepamount_1day: "1 day",
    stepamount_1month: "1 month",
    stepamount_1year: "1 year",
    stepamount_10year: "10 years",
    stepamount_100year: "100 years",
    stepinterval_title: "Speed",
    stepinterval_selector_title: "Select how often to step forward",
    stepinterval_5sec: "5 Seconds",
    stepinterval_2sec: "2 Seconds",
    stepinterval_1sec: "1 Second",
    playbutton_title: "Play",
    pausebutton_title: "Pause",
    forwardbutton_title: "Skip forward",
    backwardbutton_title: "Skip backward",
    resetbutton_title: "Go to the start of the range",
    autoplay_submit_text: "Set",
    autoplay_submit_title: "Apply settings",
    datepicker_month: "Month",
    datepicker_day: "Day",
    datepicker_year: "Year",
    datepicker_cebce: "BCE/BC or CE/AD",
    datepicker_submit_text: "Update Date",
    datepicker_cancel_text: "Cancel",
    datepicker_title: "Change Date",
    datepicker_format_text: "Date formats",
    datepicker_text: "Enter a new date to update the handle location and data displayed.",
    months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    ymd_placeholder_short: "dd/mm/yyyy",
};
L.Control.OHMTimeSlider.Translations['en-US'] = Object.assign({}, L.Control.OHMTimeSlider.Translations['en'], {
    ymd_placeholder_short: "mm/dd/yyyy",
});
L.Control.OHMTimeSlider.Translations['en-CA'] = L.Control.OHMTimeSlider.Translations['en-US'];

L.Control.OHMTimeSlider.Translations['es'] = {
    close: "Minimizar esta ventana",
    expandcollapse_title: "Minimizar o restaurar la ventana",
    slider_description: "Personaliza la fecha que deseas explorar",
    daterange_min_month_title: "Selecciona en que mes debe comenzar la barra cronológica",
    daterange_min_day_title: "Selecciona en que día debe comenzar la barra cronológica",
    daterange_min_year_title: "Selecciona en que año debe comenzar la barra cronológica",
    daterange_min_cebce_title: "Selecciona el año final de la barra cronológica inicio como a. C. o d. C.",
    daterange_max_month_title: "Selecciona en que mes debe terminar la barra cronológica",
    daterange_max_day_title: "Selecciona en que día debe terminar la barra cronológica",
    daterange_max_year_title: "Selecciona en que año debe terminar la barra cronológica",
    daterange_max_cebce_title: "Selecciona el año de inicio de la barra cronológica como a. C. o d. C.",
    daterange_submit_text: "Aplicar",
    daterange_submit_title: "Aplicar la configuración",
    range_title: "Intervalo",
    stepamount_title: "Intervalos de desplazamiento",
    stepamount_selector_title: "Personaliza a que paso debe desplazarse el tiempo en la barra cronologica",
    stepamount_1day: "1 día",
    stepamount_1month: "1 mes",
    stepamount_1year: "1 año",
    stepamount_10year: "10 años",
    stepamount_100year: "100 años",
    stepinterval_title: "Velocidad de reproducción",
    stepinterval_selector_title: "Seleccionar la escala de tiempo",
    stepinterval_5sec: "5 Segundos",
    stepinterval_2sec: "2 Segundos",
    stepinterval_1sec: "1 Segundo",
    playbutton_title: "Reproducir",
    pausebutton_title: "Pausa",
    forwardbutton_title: "Siguiente paso",
    backwardbutton_title: "Paso anterior",
    resetbutton_title: "Ir al inicio del alcance",
    autoplay_submit_text: "Aplicar",
    autoplay_submit_title: "Aplicar la configuración",
    datepicker_month: "Mes",
    datepicker_day: "Día",
    datepicker_year: "Año",
    datepicker_cebce: "a. C. o d. C.",
    datepicker_submit_text: "Aplicar fecha",
    datepicker_cancel_text: "Cancelar",
    datepicker_title: "Cambiar fecha",
    datepicker_format_text: "Formatos de fecha",
    datepicker_text: "Entra una nueva fecha para actualizar la ubicación del mango y los datos que se muestran.",
    months: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
    ymd_placeholder_short: "dd/mm/aaaa",
};

L.Control.OHMTimeSlider.Translations['fr'] = {
    close: "Fermer ce panneau",
    expandcollapse_title: "Maximiser ou minimiser ce panneau",
    slider_description: "Sélectionner la date à afficher sur la carte",
    daterange_min_month_title: "Plage du curseur, sélectionner le mois de début",
    daterange_min_day_title: "Plage du curseur, sélectionner le jour de début",
    daterange_min_year_title: "Plage du curseur, sélectionner l'année de début",
    daterange_min_cebce_title: "Plage du curseur, sélectionner l'année comme ap. J.-C. ou av. J.-C.",
    daterange_max_month_title: "Plage du curseur, sélectionner le mois de fin",
    daterange_max_day_title: "Plage du curseur, sélectionner le jour de fin",
    daterange_max_year_title: "Plage du curseur, sélectionner l'année de fin",
    daterange_max_cebce_title: "Plage du curseur, sélectionner l'année comme ap. J.-C. ou av. J.-C.",
    daterange_submit_text: "Définir",
    daterange_submit_title: "Appliquer les paramètres",
    range_title: "Plage",
    stepamount_title: "Saut de Temps",
    stepamount_selector_title: "Sélectionner de combien de temps avancer par intervalle",
    stepamount_1day: "1 jour",
    stepamount_1month: "1 mois",
    stepamount_1year: "1 an",
    stepamount_10year: "10 ans",
    stepamount_100year: "100 ans",
    stepinterval_title: "Vitesse",
    stepinterval_selector_title: "Sélectionner la fréquence d'avancement",
    stepinterval_5sec: "5 Secondes",
    stepinterval_2sec: "2 Secondes",
    stepinterval_1sec: "1 Seconde",
    playbutton_title: "Lecture",
    pausebutton_title: "Pause",
    forwardbutton_title: "Saut avant",
    backwardbutton_title: "Saut arrière",
    resetbutton_title: "Aller au début de la plage",
    autoplay_submit_text: "Définir",
    autoplay_submit_title: "Appliquer les paramètres",
    datepicker_month: "Mois",
    datepicker_day: "Jour",
    datepicker_year: "Année",
    datepicker_cebce: "ap. J.-C. ou av. J.-C.",
    datepicker_submit_text: "Appliquer la date",
    datepicker_cancel_text: "Annuler",
    datepicker_title: "Mettre à Jour Date",
    datepicker_format_text: "Formats de date",
    datepicker_text: "Saisissez une nouvelle date pour mettre à jour la position du curseur et les données affichées.",
    months: ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobere', 'Novembre', 'Décembre'],
    ymd_placeholder_short: "jj/mm/aaaa",
};
L.Control.OHMTimeSlider.Translations['fr-CA'] = L.Control.OHMTimeSlider.Translations['fr'];
L.Control.OHMTimeSlider.Translations['fr-BE'] = L.Control.OHMTimeSlider.Translations['fr'];
L.Control.OHMTimeSlider.Translations['fr-CH'] = L.Control.OHMTimeSlider.Translations['fr'];
L.Control.OHMTimeSlider.Translations['fr-LU'] = L.Control.OHMTimeSlider.Translations['fr'];
