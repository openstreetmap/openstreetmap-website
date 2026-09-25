(function () {
  class ShadowEffect {
    constructor(target) {
      const [startList, scrollableList, endList] = $(target).children();
      const [scrollableFirstItem] = $(scrollableList).children().first();
      const [scrollableLastItem] = $(scrollableList).children().last();

      if (scrollableFirstItem) {
        this.scrollStartObserver = createScrollObserver(startList, "2px 0px");
        this.scrollStartObserver.observe(scrollableFirstItem);
      }

      if (scrollableLastItem) {
        this.scrollEndObserver = createScrollObserver(endList, "-2px 0px");
        this.scrollEndObserver.observe(scrollableLastItem);
      }

      function createScrollObserver(shadowTarget, shadowOffset) {
        const threshold = 0.95;
        return new IntersectionObserver(([entry]) => {
          const floating = entry.intersectionRatio < threshold;
          $(shadowTarget)
            .css("box-shadow", floating ? `rgba(0, 0, 0, 0.075) ${shadowOffset} 2px` : "")
            .css("z-index", floating ? "5" : ""); // floating z-index should be larger than z-index of Bootstrap's .page-link:focus, which is 3
        }, { threshold });
      }
    }

    disable() {
      this.scrollStartObserver?.disconnect();
      this.scrollEndObserver?.disconnect();
    }
  }

  $(document).on("click", "a.numbered_pagination_link", function (e) {
    const targetItemId = $(this).attr("href");
    const $targetItem = $(targetItemId);
    $targetItem.trigger("numbered_pagination:center");
    $targetItem.find("a.page-link").trigger("focus");
    e.preventDefault();
  });

  $(document).on("numbered_pagination:enable", ".numbered_pagination", function () {
    $(this).data("shadow-effect", new ShadowEffect(this));
    $(this).trigger("numbered_pagination:center");
  });

  $(document).on("numbered_pagination:disable", ".numbered_pagination", function () {
    $(this).data("shadow-effect")?.disable();
    $(this).removeData("shadow-effect");
  });

  $(document).on("numbered_pagination:center", ".numbered_pagination", function () {
    const [startList, scrollableList] = $(this).children();

    if (!scrollableList) return;

    const [activeStartItem] = $(startList).find(".page-item.active");
    const [activeScrollableItem] = $(scrollableList).find(".page-item.active");

    if (activeStartItem) {
      scrollableList.scrollLeft = 0;
    } else if (activeScrollableItem) {
      scrollableList.scrollLeft = Math.round(activeScrollableItem.offsetLeft - (scrollableList.offsetWidth / 2) + (activeScrollableItem.offsetWidth / 2));
    } else {
      scrollableList.scrollLeft = scrollableList.scrollWidth - scrollableList.offsetWidth;
    }
  });
}());
