export default function (map) {
  const page = {};

  page.load = function () {
    map.setSidebarOverlaid(true);
    document.title = OSM.i18n.t("layouts.project_name.title");
  };

  page.init = function () {
    const params = new URLSearchParams(location.search);
    if (params.has("query")) {
      $("#sidebar .search_form input[name=query]").value(params.get("query"));
    }
    return map.getState();
  };

  return page;
};
