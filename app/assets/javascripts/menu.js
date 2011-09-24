/*
 * Open a menu.
 */
function openMenu(anchor, menu, align) {
  var offset;

  if (align == "left") {
    offset = 0;
  } else if (align == "right") {
    offset = anchor.getWidth() - menu.getWidth();
  }

  menu.clonePosition(anchor, {
    setLeft: true, setTop: true, setWidth: false, setHeight: false,
    offsetLeft: offset, offsetTop: anchor.getHeight()
  });

  menu.style.display = "block";
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
function enterMenuAnchor(event, anchor, menu, delay, align) {
  if (!anchor.hasClassName("disabled")) {
    clearTimeout(menu.timer);

    if (delay > 0) {
      menu.timer = setTimeout(function () { openMenu(anchor, menu, align) }, delay);
    } else {
      openMenu(event, menu, align);
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
function createMenu(anchorid, menuid, delay, align) {
  var anchor = $(anchorid);
  var menu = $(menuid);

  anchor.observe("mouseup", function (event) { closeMenu(menu) });
  anchor.observe("mouseover", function (event) { enterMenuAnchor(anchor, anchor, menu, delay, align) });
  anchor.observe("mouseout", function (event) { leaveMenuAnchor(event, anchor, menu) });
  menu.observe("mouseup", function (event) { closeMenu(menu) });
  menu.observe("mouseout", function (event) { leaveMenu(event, anchor, menu) });
}
