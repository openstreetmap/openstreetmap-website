//= require OpenLayers
//= require OpenStreetMap

OpenLayers.Util.imageURLs = {
    "img/404.png": "<%= asset_path '404.png' %>",
    "img/blank.gif": "<%= asset_path 'blank.gif' %>",
    "img/cloud-popup-relative.png": "<%= asset_path 'cloud-popup-relative.png' %>",
    "img/drag-rectangle-off.png": "<%= asset_path 'drag-rectangle-off.png' %>",
    "img/drag-rectangle-on.png": "<%= asset_path 'drag-rectangle-on.png' %>",
    "img/east-mini.png": "<%= asset_path 'east-mini.png' %>",
    "img/layer-switcher-maximize.png": "<%= asset_path 'layer-switcher-maximize.png' %>",
    "img/layer-switcher-minimize.png": "<%= asset_path 'layer-switcher-minimize.png' %>",
    "img/marker-blue.png": "<%= asset_path 'marker-blue.png' %>",
    "img/marker-gold.png": "<%= asset_path 'marker-gold.png' %>",
    "img/marker-green.png": "<%= asset_path 'marker-green.png' %>",
    "img/marker.png": "<%= asset_path 'marker.png' %>",
    "img/measuring-stick-off.png": "<%= asset_path 'measuring-stick-off.png' %>",
    "img/measuring-stick-on.png": "<%= asset_path 'measuring-stick-on.png' %>",
    "img/north-mini.png": "<%= asset_path 'north-mini.png' %>",
    "img/panning-hand-off.png": "<%= asset_path 'panning-hand-off.png' %>",
    "img/panning-hand-on.png": "<%= asset_path 'panning-hand-on.png' %>",
    "img/slider.png": "<%= asset_path 'slider.png' %>",
    "img/south-mini.png": "<%= asset_path 'south-mini.png' %>",
    "img/west-mini.png": "<%= asset_path 'west-mini.png' %>",
    "img/zoombar.png": "<%= asset_path 'zoombar.png' %>",
    "img/zoom-minus-mini.png": "<%= asset_path 'zoom-minus-mini.png' %>",
    "img/zoom-plus-mini.png": "<%= asset_path 'zoom-plus-mini.png' %>",
    "img/zoom-world-mini.png": "<%= asset_path 'zoom-world-mini.png' %>"
};

OpenLayers.Util.origCreateImage = OpenLayers.Util.createImage;

OpenLayers.Util.createImage = function(id, px, sz, imgURL, position, border,
                                       opacity, delayDisplay) {
    imgURL = OpenLayers.Util.imageURLs[imgURL] || imgURL;

    return OpenLayers.Util.origCreateImage(id, px, sz, imgURL, position,
                                           border, opacity, delayDisplay);
};
