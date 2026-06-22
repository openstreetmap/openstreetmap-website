export default function (map) {
  const page = {};

  page.pushstate = page.popstate = function () {
    map.setSidebarOverlaid(true);
    document.title = OSM.i18n.t("layouts.project_name.title");
  };

  page.load = function () {
    const params = new URLSearchParams(location.search);
    if (params.has("query")) {
      $("#sidebar .search_form input[name=query]").value(params.get("query"));
    }
    return map.getState();
  };

  return page;
};
