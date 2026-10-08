export default function (map) {
  return {
    load() {
      map.setSidebarOverlaid(true);
      document.title = OSM.i18n.t("layouts.project_name.title");
    },

    init() {
      const params = new URLSearchParams(location.search);
      if (params.has("query")) {
        $("#sidebar .search_form input[name=query]").value(params.get("query"));
      }
      return map.getState();
    }
  };
};
