/*
 * Open a menu.
 */
function openMenu(anchor, menu) {
  menu.style.display = "block";

  menu.clonePosition(anchor, {
    setLeft: true, setTop: true, setWidth: false, setHeight: false,
    offsetLeft: 0, offsetTop: anchor.getHeight()
  });
}

/*
 * Close a menu.
 */
function closeMenu(menu) {
  clearTimeout(menu.timer);
  menu.style.display = "none";
}

/*
 * Callback called when the mouse enters a menu anchor.
 */
function enterMenuAnchor(event, anchor, menu, delay) {
  if (!anchor.hasClassName("disabled")) {
    clearTimeout(menu.timer);

    if (delay > 0) {
      menu.timer = setTimeout(function () { openMenu(anchor, menu) }, delay);
    } else {
      openMenu(event, menu);
    }
  }
}

/*
 * Callback called when the mouse leaves a menu anchor.
 */
function leaveMenuAnchor(event, anchor, menu) {
  var to = event.relatedTarget;

  if (to != menu && !to.descendantOf(menu)) {
    menu.style.display = "none";
  }

  clearTimeout(menu.timer);
}

/*
 * Callback called when the mouse leaves a menu.
 */
function leaveMenu(event, anchor, menu) {
  var to = event.relatedTarget;

  if (to != anchor && !to.descendantOf(menu)) {
    menu.style.display = "none";
  }

  clearTimeout(menu.timer);
}

/*
 * Setup a menu, triggered by hovering over an anchor for a given time.
 */
function createMenu(anchorid, menuid, delay) {
  var anchor = $(anchorid);
  var menu = $(menuid);

  anchor.observe("mouseup", function (event) { closeMenu(menu) });
  anchor.observe("mouseover", function (event) { enterMenuAnchor(anchor, anchor, menu, delay) });
  anchor.observe("mouseout", function (event) { leaveMenuAnchor(event, anchor, menu) });
  menu.observe("mouseup", function (event) { closeMenu(menu) });
  menu.observe("mouseout", function (event) { leaveMenu(event, anchor, menu) });
}
