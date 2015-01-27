//= require owl/config
//= require owl/TileLayer.GeoJSON
//= require owl/layer
//= require owl/utils
//= require templates/owl/sidebar_layout
//= require templates/owl/changeset_list
//= require templates/owl/changes
OSM.OWL = function(map) {
  var page = {};
  var currentlyShownChangeset;
  var currentlySelectedChange;
  var gotMoreChangesets = true;
  var loadingInProgress = false;

  var owlGeoJsonLayer = new L.OWL.Layer({
    styles: OWL.geoJsonStyles
  });

  owlGeoJsonLayer.on('notloading', function(geojson) {
    $("#sidebar_content").html('<span class="pleasezoomin">Please zoom in<br>to see history</span>');
  });

  owlGeoJsonLayer.on('loading', function(geojson) {
    console.log('loading')
    $('#history-sidebar-loadmore').show();
    loadingInProgress = true;
  });

  owlGeoJsonLayer.on('reset', function(geojson) {
    $('#sidebar_content').html(JST["templates/owl/sidebar_layout"]());
    gotMoreChangesets = true;
    loadingInProgress = false;
  });

  owlGeoJsonLayer.on('change_clicked', onChangeClicked);

  owlGeoJsonLayer.on('loaded', function(data) {
    if (!data.loadedAllTiles) {
      return;
    }

    $('#history-sidebar-loadmore').hide();
    gotMoreChangesets = data.gotMore;
    loadingInProgress = false;

    var changesets = owlGeoJsonLayer._getChangesetsFromTiles();//data.changesets;
    var userIds = [];

    $.each(changesets, function(index, changeset) {
      prepareChangesetInfo(changeset);
      if (changeset.user_id) {
        userIds.push(changeset.user_id);
      }
    });

    fetchUserDetails($.unique(userIds), function(user) {
      $('.user_avatar_' + user.user_id).attr('src', user.img_href);
    });

    var existing = $('#history-sidebar').html();
    $('#history-sidebar').html(
      JST["templates/owl/changeset_list"]({
        changesets: changesets,
        owlLayer: owlGeoJsonLayer
      }));

    $('.changeset-info').click(function(e) {
      toggleChanges(findChangesetId(e.target));
      return false;
    });

    $('.changeset-comment').click(function(e) {
      toggleChanges(findChangesetId(e.target));
      return false;
    });

    $('.show-changes').click(function(e) {
      toggleChanges(findChangesetId(e.target));
      return false;
    });

    $('abbr.timeago').timeago();

    $('#sidebar_content').scroll(function(e) {
      if (isLoadMoreInView() && gotMoreChangesets && !loadingInProgress) {
        owlGeoJsonLayer.nextPage();
      }
    });

    $('.changeset-info').hover(
      function(e) {
        owlGeoJsonLayer.highlightChangesetFeatures(findChangesetId(e.target));
      }, function(e) {
        owlGeoJsonLayer.unhighlightChangesetFeatures(findChangesetId(e.target));
      }
    );

    $('#sidebar_title').html(
      'History <a target="_blank" href="" class="rsssmall owl_feed_link"><img alt="RSS" border="0" height="16" src="/assets/RSS.png" width="16"></a>'
    );

    owlUpdateFeedLink();
  });

  owlGeoJsonLayer.on('changemouseover', function(data) {
    highlightChangesetItem(data.change.changeset_id);
    highlightChange(data.change.uid, false, false);
  });

  owlGeoJsonLayer.on('changemouseout', function(data) {
    unhighlightChangesetItem(data.change.changeset_id);
    unhighlightChange(false);
  });

  function highlightChangesetItem(changeset_id) {
    $('div[data-changeset-id=' + changeset_id + '] > .changeset-info').addClass('changeset-item-highlight');
  }

  function unhighlightChangesetItem(changeset_id) {
    $('div[data-changeset-id=' + changeset_id + '] > .changeset-info').removeClass('changeset-item-highlight');
  }

  function highlightChange(changeId, addSelectedClass, select) {
    if (currentlySelectedChange != null && select) {
      unhighlightChange(true);
    }
    if (addSelectedClass) {
      $('div[data-change-id="' + changeId + '"]').addClass('change-selected');
    } else {
      $('div[data-change-id="' + changeId + '"]').addClass('change-highlight');
    }
    if (select) {
      $('div[data-change-id="' + changeId + '"] > .change-tags').show();
      currentlySelectedChange = changeId;
    }
  }

  function unhighlightChange(deselect) {
    if (currentlySelectedChange != null) {
      $('div[data-change-id="' + currentlySelectedChange + '"]').removeClass('change-highlight');
      if (deselect) {
        $('div[data-change-id="' + currentlySelectedChange + '"]').removeClass('change-selected');
        $('div[data-change-id="' + currentlySelectedChange + '"] > .change-tags').hide();
        currentlySelectedChange = null;
      }
    }
  }

  function showChanges(changesetId, changeToHighlight) {
    if (currentlyShownChangeset != null && changesetId != currentlyShownChangeset) {
      hideChanges(currentlyShownChangeset);
    }
    currentlyShownChangeset = changesetId;
    $('div[data-changeset-id=' + changesetId + '] > div[class=change-list]').html(JST["templates/owl/changes"]({
      changeset: owlGeoJsonLayer.getChangeset(changesetId)
    }));

    $("abbr.timeago").timeago();

    $('.show-prev-geom').hover(function(e) {
      owlGeoJsonLayer.showPrevGeom(findChangeId(e.target));
    }, function(e) {
      owlGeoJsonLayer.showCurrentGeom(findChangeId(e.target));
    });

    $('.change').click(function(e) {
      highlightChange(findChangeId(e.target), false, true);
    });

    $('.change').hover(function(e) {
      owlGeoJsonLayer.highlightChangeFeature(findChangeId(e.target));
    }, function(e) {
      owlGeoJsonLayer.unhighlightChangeFeature(findChangeId(e.target));
    });

    $('.more_link > a').click(function(e) {
      owlGeoJsonLayer.nextPage();
      return false;
    });

    $('div[data-changeset-id=' + changesetId + '] > div[class=change-list]').show('fast', function() {
      if (changeToHighlight) {
        highlightChange(changeToHighlight, true, true);
        $('div[data-change-id="' + changeToHighlight + '"]').scrollIntoView(false);
      }
    });
  }

  function hideChanges(changesetId) {
    unhighlightChange(true);
    currentlyShownChangeset = null;
    $('div[data-changeset-id=' + changesetId + '] > div[class=change-list]').hide('fast', function() {
      $('div[data-changeset-id=' + changesetId + '] > div[class=change-list]').html('');
    });
  }

  function toggleChanges(changesetId) {
    if (changesetId != currentlyShownChangeset) {
      showChanges(changesetId, null);
    } else {
      hideChanges(changesetId);
    }
  }

  function onChangeClicked(data) {
    showChanges(data.clickedChange.changeset_id, data.clickedChange.uid);
  }

  page.pushstate = page.popstate = function(path) {
    $("#history_tab").addClass("current");
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function() {
    map.addLayer(owlGeoJsonLayer);

    if (window.location.pathname === '/history') {
      //map.on("moveend", update);
    }

    //update();
  };

  page.unload = function() {
    map.removeLayer(owlGeoJsonLayer);
    //map.off("moveend", update);

    $("#history_tab").removeClass("current");
  };

  return page;
};