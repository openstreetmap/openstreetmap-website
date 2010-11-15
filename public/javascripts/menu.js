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
 * Callback called when the mouse enters a menu anchor.
 */
function enterMenuAnchor(event, anchor, menu, delay) {
  clearTimeout(menu.timer);

  if (delay > 0) {
    menu.timer = setTimeout(function () { openMenu(anchor, menu) }, delay);
  } else {
    openMenu(event, menu);
  }
}

/*
 * Callback called when the mouse leaves a menu anchor.
 */
function leaveMenuAnchor(event, anchor, menu) {
  var to = event.relatedTarget || event.toElement;

  if (to != menu && !to.descendantOf(menu)) {
    menu.style.display = "none";
  }

  clearTimeout(menu.timer);
}

/*
 * Callback called when the mouse leaves a menu.
 */
function leaveMenu(event, anchor, menu) {
  var to = event.relatedTarget || event.toElement;

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

  anchor.onmouseover = function (event) { enterMenuAnchor(anchor, anchor, menu, delay) };
  anchor.onmouseout = function (event) { leaveMenuAnchor(event, anchor, menu) };
  menu.onmouseout = function (event) { leaveMenu(event, anchor, menu) };
}
