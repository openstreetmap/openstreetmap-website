class CombinedControlGroup {
  constructor(controls) {
    // array of MapLibre controls
    this.controls = controls;
    // DOM containers returned by onAdd()
    this.containers = [];
  }

  onAdd(map) {
    this._container = document.createElement("div");
    this._container.className = "maplibregl-ctrl maplibregl-ctrl-group";

    for (const ctrl of this.controls) {
      const ctrlContainer = ctrl.onAdd(map);
      this.containers.push(ctrlContainer);

      // Extract buttons from the control's container and add to our wrapper
      const buttons = ctrlContainer.querySelectorAll("button");
      buttons.forEach(button => {
        this._container.appendChild(button);
      });
    }

    return this._container;
  }

  onRemove() {
    for (const ctrl of this.controls) ctrl.onRemove?.();

    if (this._container) this._container.remove();
  }
}

OSM.MapLibre.CombinedControlGroup = CombinedControlGroup;
