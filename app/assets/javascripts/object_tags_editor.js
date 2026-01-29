(function () {
  function parseTags(text) {
    const lines = text.split("\n");
    const tags = new Map();
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line === "") {
        continue;
      }
      const eqPos = line.indexOf("=");
      if (eqPos <= 0 || eqPos === line.length - 1) {
        throw new Error(`= not found on ${i + 1} line`);
      }
      const k = line.substring(0, eqPos).trim();
      if (k === "") {
        throw new Error(`empty key on ${i + 1} line`);
      }
      const v = line.substring(eqPos + 1).trim();
      if (v === "") {
        throw new Error(`empty value on ${i + 1} line`);
      }
      tags.set(k, v.replaceAll("\\\\", "\n"));
    }
    return tags;
  }

  function makeChangesSummary(objectType, objectId, prevTags, newTags) {
    const addedTags = new Map();
    const changedTags = new Map();
    const removedTags = new Map();
    prevTags.entries().forEach(([k, v]) => {
      if (!newTags.has(k)) {
        removedTags.set(k, v);
      } else if (newTags.get(k) !== v) {
        changedTags.set(k, v);
      }
    });
    newTags.entries().forEach(([k, v]) => {
      if (!prevTags.has(k)) {
        addedTags.set(k, v);
      }
    });
    if (addedTags.size + changedTags.size + removedTags.size === 0) {
      return;
    }

    function makeDetailedPrefix() {
      let res = "";
      if (addedTags.size) {
        res += "Add " + addedTags.entries().map(([k, v]) => `${k}=${v}`).toArray().join(", ") + "; ";
      }
      if (changedTags.size) {
        res += "Changed " + changedTags.entries().map(([k, v]) => `${k}=${v}\u200b→\u200b${newTags.get(k)}`).toArray().join(", ") + "; ";
      }
      if (removedTags.size) {
        res += "Removed " + removedTags.entries().map(([k, v]) => `${k}=${v}`).toArray().join(", ");
      }
      return res;
    }

    function makeOnlyKeysPrefix() {
      let text = "";
      if (addedTags.size) {
        text += "Add " + addedTags.map(([k]) => k).join(", ") + "; ";
      }
      if (changedTags.size) {
        text += "Changed " + changedTags.map(([k]) => k).join(", ") + "; ";
      }
      if (removedTags.size) {
        text += "Removed " + removedTags.map(([k]) => k).join(", ");
      }
      return text;
    }

    function makeUniversalSummary() {
      return `Update tags of ${objectType}/${objectId}`;
    }

    function makeMainTagsHint() {
      const mainTags = new Set([
        "shop", "building", "amenity", "man_made", "highway", "natural",
        "aeroway", "historic", "railway", "tourism", "landuse", "leisure"
      ]);
      let mainTagsHint = "";

      for (const [k, v] of prevTags.entries()) {
        if (mainTags.has(k) && !removedTags.has(k) && !changedTags.has(k)) {
          mainTagsHint += ` ${k}=${v}`;
          break;
        }
      }
      for (const [k, v] of prevTags.entries()) {
        if (k === "name" && !removedTags.has("name") && !changedTags.has("name")) {
          mainTagsHint += ` ${k}=${v}`;
          break;
        }
      }
      return mainTagsHint;
    }

    let summary = makeDetailedPrefix();
    const mainTagsHint = makeMainTagsHint();
    if (summary.length > 200 || changedTags.size > 1) {
      summary = makeOnlyKeysPrefix();
    }
    summary = summary.replace(/; $/, "");
    if (mainTagsHint === "") {
      summary += ` for ${objectType}/${objectId}`;
    } else if (removedTags.size) {
      summary += " from" + mainTagsHint;
    } else if (changedTags.size) {
      summary += " of" + mainTagsHint;
    } else if (addedTags.size) {
      summary += " to" + mainTagsHint;
    }
    return summary && summary.length < 255 ? summary : makeUniversalSummary();
  }

  function makeAuthHeaders() {
    return { Authorization: `Bearer ${document.head.dataset.oauthToken}` };
  }

  async function openOsmChangeset(comment) {
    const changesetPayload = document.implementation.createDocument(null, "osm");
    const changesetElem = changesetPayload.createElement("changeset");
    changesetPayload.documentElement.appendChild(changesetElem);

    Object.entries({
      created_by: "Tags editor on osm.org",
      comment: comment
    }).forEach(([k, v]) => {
      const tag = changesetPayload.createElement("tag");
      tag.setAttribute("k", k);
      tag.setAttribute("v", v);
      changesetElem.appendChild(tag);
    });

    const res = await fetch("/api/0.6/changeset/create", {
      method: "PUT",
      headers: makeAuthHeaders(),
      body: new XMLSerializer().serializeToString(changesetPayload)
    });
    if (!res.ok) {
      throw new Error("Failed changeset creation");
    }
    return await res.text();
  }

  async function uploadNewVersion(objectType, objectId, objectInfo, changesetId) {
    try {
      objectInfo.children[0].children[0].setAttribute("changeset", changesetId);
      const objectInfoStr = new XMLSerializer().serializeToString(objectInfo).replace(/xmlns="[^"]+"/, "");
      const res = await fetch(`/api/0.6/${objectType}/${objectId}`, {
        method: "PUT",
        headers: makeAuthHeaders(),
        body: objectInfoStr
      });
      if (!res.ok) {
        throw new Error(`Error when uploading changes: HTTP ${res.status}`);
      }
    } finally {
      await fetch(`/api/0.6/changeset/${changesetId}/close`, {
        method: "PUT",
        headers: makeAuthHeaders()
      });
    }
  }

  function applyNewTags(objectInfo, newTags) {
    const objectXML = objectInfo.querySelector("node,way,relation");
    objectXML.querySelectorAll("tag").forEach(i => i.remove());
    newTags.entries().forEach(([k, v]) => {
      const tag = objectInfo.createElement("tag");
      tag.setAttribute("k", k);
      tag.setAttribute("v", v);
      objectXML.appendChild(tag);
    });
  }

  async function downloadObjectInfo(type, id) {
    const res = await fetch(`/api/0.6/${type}/${id}.xml`);
    const objectInfo = new DOMParser().parseFromString(await res.text(), "text/xml");
    if (objectInfo.querySelector("parsererror")) {
      throw new Error("invalid API response");
    }
    return objectInfo;
  }

  function extractTagsFromObjectInfo(objectInfo) {
    const tags = new Map();
    objectInfo.querySelectorAll("tag").forEach(t => {
      tags.set(t.getAttribute("k"), t.getAttribute("v"));
    });
    return tags;
  }

  $(document).on("click", "a.edit_object_tags", async function (e) {
    e.preventDefault();
    e.stopPropagation();

    e.target.setAttribute("disabled", true);

    const [, type, id] = location.pathname.match(/\/(node|way|relation)\/([0-9]+)/);
    const objectInfo = await downloadObjectInfo(type, id);
    const currentTags = extractTagsFromObjectInfo(objectInfo);

    const $browseSection = $("#sidebar_content h2 + div").first();

    const $errorBox = $("<p>");

    const $editorTextarea = $("<textarea>")
      .addClass("form-control font-monospace mb-3")
      .prop({
        rows: 10,
        cols: 40
      });

    $editorTextarea.val(
      currentTags
        .entries()
        .map(([k, v]) => `${k} = ${v.replaceAll("\n", "\\\\")}`)
        .toArray()
        .join("\n")
    );

    async function submitTags() {
      const newTags = parseTags($editorTextarea.val());
      const summary = makeChangesSummary(type, id, currentTags, newTags);
      if (!summary) {
        throw OSM.i18n.t("javascripts.object_tags_editor.no_changes");
      }
      const changesetId = await openOsmChangeset(summary);
      applyNewTags(objectInfo, newTags);
      await uploadNewVersion(type, id, objectInfo, changesetId);
    }

    const $editorWrapper = $("<form>")
      .on("submit", async (e) => {
        e.preventDefault();
        $errorBox.text("");
        try {
          await submitTags();
          location.reload();
        } catch (e) {
          $errorBox.text(e);
        }
      });

    const $saveButton = $("<input>")
      .prop({
        type: "submit",
        name: "save",
        value: OSM.i18n.t("javascripts.object_tags_editor.save")
      })
      .addClass("btn btn-primary");

    const $cancelButton = $("<input>")
      .prop({
        type: "submit",
        name: "cancel",
        value: OSM.i18n.t("javascripts.object_tags_editor.cancel")
      })
      .addClass("btn btn-danger")
      .on("click", () => {
        e.target.removeAttribute("disabled");
        $editorWrapper.replaceWith($browseSection);
      });

    const $buttonsWrapper = $("<div>")
      .addClass("d-flex gap-2 mt-3");

    $buttonsWrapper.append($saveButton, $cancelButton);

    $editorWrapper.append($editorTextarea, $errorBox, $buttonsWrapper);
    $browseSection.replaceWith($editorWrapper);
    $editorTextarea.focus();
  });
}());
