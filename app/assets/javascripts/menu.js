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
 * Setup a menu, triggered by hovering over an anchor for a given time.
 */
function createMenu(anchorid, menuid, align) {
  var $anchor = $("#" + anchorid);
  var $arrow = $("#" + anchorid + " .menuicon");
  var $menu = $("#" + menuid);
  var $page = $(":not(#" + menuid + ", #" + anchorid + ")");

  function hide() {
    $menu.hide();
    $page.off("click", hide);
  }

  $arrow.click(function(e) {
    if ($anchor.is(":not(.disabled)")) {
      e.stopPropagation();
      e.preventDefault();
      if ($menu.is(":visible")) {
        $menu.hide();
        $page.off("click", hide);
      } else {
        openMenu($anchor, $menu.show(), align);
        $page.on("click", hide);
      }
    }
  });
}
