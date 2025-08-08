(function () {
  let shadowEffect;

  class ShadowEffect {
    constructor() {
      const $scrollableList = $("#versions-navigation-list-middle");
      const [scrollableFirstItem] = $scrollableList.children().first();
      const [scrollableLastItem] = $scrollableList.children().last();

      if (scrollableFirstItem) {
        this.scrollStartObserver = createScrollObserver("#versions-navigation-list-start", "2px 0px");
        this.scrollStartObserver.observe(scrollableFirstItem);
      }

      if (scrollableLastItem) {
        this.scrollEndObserver = createScrollObserver("#versions-navigation-list-end", "-2px 0px");
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

  $(document).on("click", "a[href='#versions-navigation-active-page-item']", function (e) {
    $(document).trigger("numbered_pagination:center");
    $("#versions-navigation-active-page-item a.page-link").trigger("focus");
    e.preventDefault();
  });

  $(document).on("numbered_pagination:enable", function () {
    shadowEffect = new ShadowEffect();
    $(document).trigger("numbered_pagination:center");
  });

  $(document).on("numbered_pagination:disable", function () {
    shadowEffect?.disable();
    shadowEffect = null;
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
