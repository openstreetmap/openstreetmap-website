$(function () {
  const $tagstring = $("#trace_tagstring");
  const $help = $tagstring.siblings(".form-text");
  const help = $help.text();
  const $tags = $("<ul>")
    .addClass("list-unstyled d-inline-flex flex-wrap column-gap-1 ms-1 mb-0")
    .appendTo($tagstring.parent());

  function updateTags() {
    const tagstring = $tagstring.val();
    let names, delimitedHelp;

    // Split the tags the same way as Trace#tagstring= does, which
    // only counts ASCII whitespace, unlike \s and trim()
    if (tagstring.includes(",")) {
      names = tagstring.split(",")
        .map(name => name.replace(/^[\t\n\v\f\r ]+|[\t\n\v\f\r ]+$/g, ""))
        .filter(name => name);
      delimitedHelp = OSM.i18n.t("javascripts.traces.tagstring.comma_delimited");
    } else {
      names = tagstring.split(/[\t\n\v\f\r ]+/).filter(name => name);
      delimitedHelp = OSM.i18n.t("javascripts.traces.tagstring.space_delimited");
    }

    // Nothing to show unless there's more than one tag
    if (names.length < 2) names = [];

    $help.text(names.length > 0 ? delimitedHelp : help);

    const items = names
      .map(name => $("<li>").addClass("badge text-bg-secondary mt-1").text(name));
    $tags.empty().append(...items);
  }

  $tagstring.on("input", updateTags);
  updateTags();
});
