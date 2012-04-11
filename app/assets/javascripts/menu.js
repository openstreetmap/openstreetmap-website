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
  var $anchor = $("#" + anchorid),
      $arrow = $("#" + anchorid + ' .arrow'),
      $menu = $("#" + menuid),
      $page = $(':not(#' + menuid + ', #' + anchorid + ')');

  function hide() {
    $menu.hide();
    $page.unbind('click', hide);
  }

  $arrow.click(function(e) {
      e.stopPropagation();
      e.preventDefault();
      if ($menu.is(':visible')) {
          $menu.hide();
          $page.unbind('click', hide);
      } else {
          openMenu($anchor, $menu.show(), 'left');
          $page.bind('click', hide);
      }
  });
}
