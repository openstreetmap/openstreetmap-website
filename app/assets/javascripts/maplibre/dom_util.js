OSM.MapLibre.Marker = class extends maplibregl.Marker {
  constructor({ icon = "dot", color = "var(--marker-red)", autoPan = false, ...options } = {}) {
    const element = document.createElement("div");
    element.className = "maplibre-gl-marker";
    element.style.width = "25px";
    element.style.height = "40px";

    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("viewBox", "0 0 25 40");
    svg.setAttribute("width", "25");
    svg.setAttribute("height", "40");
    svg.classList.add("pe-none");
    svg.style.overflow = "visible";

    // Use the marker icons from NoteMarker.svg
    const use1 = document.createElementNS("http://www.w3.org/2000/svg", "use");
    use1.setAttribute("href", "#pin-shadow");

    const use2 = document.createElementNS("http://www.w3.org/2000/svg", "use");
    use2.setAttribute("href", `#pin-${icon}`);
    use2.setAttribute("color", color);
    use2.classList.add("pe-auto");

    svg.appendChild(use1);
    svg.appendChild(use2);
    element.appendChild(svg);

    super({
      element,
      anchor: "bottom",
      offset: [0, 0],
      ...options
    });

    if (autoPan && options.draggable) this._enableAutoPan();
  }

  _enableAutoPan() {
    const edgeDistance = 50,
          maxPanStep = 10;

    let frame = null;

    const step = () => {
      frame = requestAnimationFrame(step);

      const map = this._map;
      if (!map) return;

      const point = map.project(this.getLngLat()),
            { clientWidth, clientHeight } = map.getContainer();

      let dx = 0,
          dy = 0;
      if (point.x < edgeDistance) dx = point.x - edgeDistance;
      else if (point.x > clientWidth - edgeDistance) dx = point.x - (clientWidth - edgeDistance);
      if (point.y < edgeDistance) dy = point.y - edgeDistance;
      else if (point.y > clientHeight - edgeDistance) dy = point.y - (clientHeight - edgeDistance);
      if (!dx && !dy) return;

      const clamp = (v) => Math.max(-maxPanStep, Math.min(maxPanStep, v));
      map.panBy([clamp(dx), clamp(dy)], { duration: 0 });
      this.setLngLat(map.unproject(point));
      this.fire("drag");
    };

    this.on("dragstart", () => {
      if (frame === null) frame = requestAnimationFrame(step);
    });
    this.on("dragend", () => {
      if (frame !== null) cancelAnimationFrame(frame);
      frame = null;
    });
  }
};

OSM.MapLibre.Popup = class extends maplibregl.Popup {
  constructor(options) {
    // General offset 5px for each side, but the offset depends on the popup position:
    // Popup above the marker -> lift it by height + 5px = 45px
    // Popup left the marker -> lift it by width/2 + 5px = 22.5px ~= 17px
    const offset = {
      "bottom": [0, -45],
      "bottom-left": [0, -45],
      "bottom-right": [0, -45],
      "top": [0, 5],
      "top-left": [0, 5],
      "top-right": [0, 5],
      // our marker is bigger at the top, but this does not attach there -> tucked 2px more
      "right": [-15, -10],
      "left": [15, -10]
    };
    super({ offset, ...options });
  }
};
