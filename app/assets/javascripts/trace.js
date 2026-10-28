$(function () {
  const $tagstring = $("#trace_tagstring");
  const $tags = $("<ul>")
    .addClass("list-unstyled d-flex flex-wrap column-gap-1 mb-0")
    .appendTo($tagstring.parent());

  // Split the tags the same way as Trace#tagstring= does, which
  // only counts ASCII whitespace, unlike \s and trim()
  function tagNames(tagstring) {
    if (tagstring.includes(",")) {
      return tagstring.split(",")
        .map(name => name.replace(/^[\t\n\v\f\r ]+|[\t\n\v\f\r ]+$/g, ""))
        .filter(name => name);
    } else {
      return tagstring.split(/[\t\n\v\f\r ]+/).filter(name => name);
    }
  }

  function updateTags() {
    const items = tagNames($tagstring.val())
      .map(name => $("<li>").addClass("badge text-bg-secondary mt-1").text(name));
    $tags.empty().append(...items);
  }

  $tagstring.on("input", updateTags);
  updateTags();
});
