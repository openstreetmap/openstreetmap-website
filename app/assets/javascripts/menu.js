/*
 * Open a menu.
 */
function openMenu(anchor, menu, align) {
  var anchorPosition = anchor.offset();
  var offset;

  if (align == "left") {
    offset = 0;
  } else if (align == "right") {
    offset = menu.outerWidth() - anchor.outerWidth();
  }

  menu.show();

  menu.offset({
    top: anchorPosition.top + anchor.outerHeight(),
    left: anchorPosition.left - offset
  });
}

/*
 * Close a menu.
 */
function closeMenu(menu) {
  clearTimeout(menu.timer);
  menu.hide();
}

/*
 * Callback called when the mouse enters a menu anchor.
 */
function enterMenuAnchor(event, anchor, menu, delay, align) {
  if (!anchor.hasClass("disabled")) {
    clearTimeout(menu.timer);

    if (delay > 0) {
      menu.timer = setTimeout(function () { openMenu(anchor, menu, align); }, delay);
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

  if (!menu.is(to) && menu.has(to).length === 0) {
    menu.hide();
  }

  clearTimeout(menu.timer);
}

/*
 * Callback called when the mouse leaves a menu.
 */
function leaveMenu(event, anchor, menu) {
  var to = event.relatedTarget;

  if (!anchor.is(to) && menu.has(to).length === 0) {
    menu.hide();
  }

  clearTimeout(menu.timer);
}

/*
 * Setup a menu, triggered by hovering over an anchor for a given time.
 */
function createMenu(anchorid, menuid, delay, align) {
  var anchor = $("#" + anchorid);
  var menu = $("#" + menuid);

  anchor.mouseup(function (event) { closeMenu(menu); });
  anchor.mouseover(function (event) { enterMenuAnchor(anchor, anchor, menu, delay, align); });
  anchor.mouseout(function (event) { leaveMenuAnchor(event, anchor, menu); });
  menu.mouseup(function (event) { closeMenu(menu); });
  menu.mouseout(function (event) { leaveMenu(event, anchor, menu); });
}
