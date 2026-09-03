describe("Leaflet worldCopyJump", function () {
  let container, map;

  beforeEach(function () {
    container = document.createElement("div");
    container.style.width = "512px";
    container.style.height = "512px";
    document.body.appendChild(container);

    map = L.map(container, {
      fadeAnimation: false,
      inertia: false,
      worldCopyJump: true,
      zoomAnimation: false
    }).setView([0, 0], 2);
  });

  afterEach(function () {
    map.remove();
    container.remove();
  });

  it("rebases retained tiles from every zoom level", function () {
    const layer = L.gridLayer().addTo(map),
          zoomTwoTile = document.createElement("div"),
          zoomThreeTile = document.createElement("div"),
          zoomTwoCoords = L.point(1, 1),
          zoomThreeCoords = L.point(2, 2),
          zoomTwo = { coords: zoomTwoCoords, el: zoomTwoTile },
          zoomThree = { coords: zoomThreeCoords, el: zoomThreeTile };

    zoomTwoCoords.z = 2;
    zoomThreeCoords.z = 3;
    L.DomUtil.setPosition(zoomTwoTile, L.point(10, 20));
    L.DomUtil.setPosition(zoomThreeTile, L.point(30, 40));
    layer._tiles = {
      "1:1:2": zoomTwo,
      "2:2:3": zoomThree
    };

    const dragging = map.dragging;
    dragging._onDragStart();
    dragging._draggable._newPos = L.point(600, 0);
    dragging._onPreDragWrap();
    dragging._onDrag({});

    expect(zoomTwoCoords.x).to.equal(5);
    expect(zoomThreeCoords.x).to.equal(10);
    expect(L.DomUtil.getPosition(zoomTwoTile)).to.deep.equal(L.point(1034, 20));
    expect(L.DomUtil.getPosition(zoomThreeTile)).to.deep.equal(L.point(2078, 40));
    expect(layer._tiles["5:1:2"]).to.equal(zoomTwo);
    expect(layer._tiles["10:2:3"]).to.equal(zoomThree);
  });
});
