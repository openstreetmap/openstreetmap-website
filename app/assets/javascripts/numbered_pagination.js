(function () {
  $(document).on("click", "a[href='#versions-navigation-active-page-item']", function (e) {
    $(document).trigger("numbered_pagination:center");
    $("#versions-navigation-active-page-item a.page-link").trigger("focus");
    e.preventDefault();
  });

  $(document).on("numbered_pagination:center", function () {
    const [scrollableList] = $("#versions-navigation-list-middle");

    if (!scrollableList) return;

    const [activeStartItem] = $("#versions-navigation-list-start #versions-navigation-active-page-item");
    const [activeScrollableItem] = $("#versions-navigation-list-middle #versions-navigation-active-page-item");

    if (activeStartItem) {
      scrollableList.scrollLeft = 0;
    } else if (activeScrollableItem) {
      scrollableList.scrollLeft = Math.round(activeScrollableItem.offsetLeft - (scrollableList.offsetWidth / 2) + (activeScrollableItem.offsetWidth / 2));
    } else {
      scrollableList.scrollLeft = scrollableList.scrollWidth - scrollableList.offsetWidth;
    }
  });
}());
