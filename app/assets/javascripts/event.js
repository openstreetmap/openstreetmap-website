function init_event_form() {
    var map = L.map("event_map_form", {
        attributionControl: false,
    });
    map.addLayer(new L.OSM.Mapnik());

    var lat_field = document.getElementById('latitude')
    var lon_field = document.getElementById('longitude')

    if (lat_field.value) {
        map.setView([lat_field.value, lon_field.value], 12);
    } else {
        map.setView([0, 0], 0);
    }

    L.Control.  Watermark = L.Control.extend({
        onAdd: function(map) {
            var container = map.getContainer();
            var img = L.DomUtil.create('img');
            img.src = '/assets/marker-blue.png';   // 25x41 px
            // img.style.width = '200px';
            img.style["margin-left"] = ((container.offsetWidth / 2) - 12) +  'px';
            img.style["margin-bottom"] = ((container.offsetHeight / 2) - 20) + 'px';
            return img;
        },
        onRemove: function(map) {
            // Nothing to do here
        }
    });
    L.control.watermark = function(opts) {
        return new L.Control.Watermark(opts);
    }
    L.control.watermark({ position: 'bottomleft' }).addTo(map);

    map.on("move", function (e) {
        var center = map.getCenter();
        $("#latitude").val(center.lat);
        $("#longitude").val(center.lng);
    });
}


function init_event_show() {
    var el = document.querySelector("#event_map_show");
    var event = JSON.parse(el.dataset.event);
    var map = L.map("event_map_show", {
        center: [event.latitude, event.longitude],
        zoom: 15
    });
    map.addLayer(new L.OSM.Mapnik());
    var marker = L.marker([event.latitude, event.longitude], { icon: OSM.getUserIcon() }).addTo(map);

    // if (OSM.home) {
    //     marker.setLatLng([OSM.home.lat, OSM.home.lon]);
    //     marker.addTo(map);
    // }

}

$(document).ready(function () {
    if ($("#event_map_form").length) {
        init_event_form();
    } else if ($("#event_map_show").length) {
        init_event_show();
    }
});
