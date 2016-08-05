// OSRM car engine
// Doesn't yet support hints

function OSRMEngine() {
  var cachedHints = [];

  return {
    id: "osrm_car",
    creditline: '<a href="http://project-osrm.org/" target="_blank">OSRM</a>',
    draggable: true,

    _transformSteps: function(input_steps, line) {
      var INSTRUCTION_TEMPLATE = {
        'continue': 'javascripts.directions.instructions.continue',
        'merge right': 'javascripts.directions.instructions.merge_right',
        'merge left': 'javascripts.directions.instructions.merge_left',
        'off ramp right': 'javascripts.directions.instructions.offramp_right',
        'off ramp left': 'javascripts.directions.instructions.offramp_left',
        'on ramp right': 'javascripts.directions.instructions.onramp_right',
        'on ramp left': 'javascripts.directions.instructions.onramp_left',
        'fork right': 'javascripts.directions.instructions.fork_right',
        'fork left': 'javascripts.directions.instructions.fork_left',
        'end of road right': 'javascripts.directions.instructions.endofroad_right',
        'end of road left': 'javascripts.directions.instructions.endofroad_left',
        'turn straight': 'javascripts.directions.instructions.continue',
        'turn slight right': 'javascripts.directions.instructions.slight_right',
        'turn right': 'javascripts.directions.instructions.turn_right',
        'turn sharp right': 'javascripts.directions.instructions.sharp_right',
        'turn uturn': 'javascripts.directions.instructions.uturn',
        'turn sharp left': 'javascripts.directions.instructions.sharp_left',
        'turn left': 'javascripts.directions.instructions.turn_left',
        'turn slight left': 'javascripts.directions.instructions.slight_left',
        'trun straight': 'javascripts.directions.instructions.follow',
        'roundabout': 'javascripts.directions.instructions.roundabout',
        'rotary': 'javascripts.directions.instructions.roundabout',
        'depart': 'javascripts.directions.instructions.start',
        'arrive': 'javascripts.directions.instructions.destination',
      };
      var ICON_MAP = {
        'continue': 0,
        'merge right': 21,
        'merge left': 20,
        'off ramp right': 24,
        'off ramp left': 25,
        'on ramp right': 2,
        'on ramp left': 6,
        'fork right': 18,
        'fork left': 19,
        'end of road right': 22,
        'end of road left': 23,
        'turn straight': 0,
        'turn slight right': 1,
        'turn right': 2,
        'turn sharp right': 3,
        'turn uturn': 4,
        'turn slight left': 5,
        'turn left': 6,
        'turn sharp left': 7,
        'trun straight': 0,
        'roundabout': 10,
        'rotary': 10,
        'depart': 8,
        'arrive': 14
      };
      var transformed_steps = input_steps.map(function(step, idx) {
        var maneuver_id;

        // special case handling
        switch (step.maneuver.type) {
          case 'on ramp':
          case 'off ramp':
          case 'merge':
          case 'end of road':
          case 'fork':
            maneuver_id = step.maneuver.type + ' ' + (step.maneuver.modifier.indexOf('left') >= 0 ? 'left' : 'right');
            break;
          case 'depart':
          case 'arrive':
          case 'roundabout':
          case 'rotary':
            maneuver_id = step.maneuver.type;
            break;
          case 'roundabout turn':
          case 'turn':
            maneuver_id = "turn " + step.maneuver.modifier;
            break;
          // for unknown types the fallback is turn
          default:
            maneuver_id = "turn " + step.maneuver.modifier;
            break;
        }
        var template = INSTRUCTION_TEMPLATE[maneuver_id];

        // convert lat,lng pairs to LatLng objects
        var step_geometry = L.PolylineUtil.decode(step.geometry, { precision: 5 }).map(function(a) { return L.latLng(a); }) ;
        // append step_geometry on line
        Array.prototype.push.apply(line, step_geometry);

        var instText = "<b>" + (idx + 1) + ".</b> ";
        var name = step.name ? "<b>" + step.name + "</b>" : I18n.t('javascripts.directions.instructions.unnamed');
        if (step.maneuver.type.match(/rotary|roundabout/)) {
          instText += I18n.t(template + '_with_exit', { exit: step.maneuver.exit, name: name } );
        } else {
          instText += I18n.t(template + '_without_exit', { name: name });
        }
        return [[step.maneuver.location[1], step.maneuver.location[0]], ICON_MAP[maneuver_id], instText, step.distance, step_geometry];
      });

      return transformed_steps;
    },

    getRoute: function (points, callback) {

      var params = [
        { name: "overview", value: "false" },
        { name: "geometries", value: "polyline" },
        { name: "steps", value: true }
      ];


      if (cachedHints.length === points.length) {
        params.push({name: "hints", value: cachedHints.join(";")});
      } else {
        // invalidate cache
        cachedHints = [];
      }

      var encoded_coords = points.map(function(p) {
        return p.lng + ',' + p.lat;
      }).join(';');

      var req_url = document.location.protocol + OSM.OSRM_URL + encoded_coords;

      var onResponse = function (data) {
        if (data.code !== 'Ok')
          return callback(true);

        cachedHints = data.waypoints.map(function(wp) {
          return wp.hint;
        });

        var line = [];
        var transformLeg = function (leg) {
          return this._transformSteps(leg.steps, line);
        };

        var steps = [].concat.apply([], data.routes[0].legs.map(transformLeg.bind(this)));

        callback(false, {
          line: line,
          steps: steps,
          distance: data.routes[0].distance,
          time: data.routes[0].duration
        });
      };

      return $.ajax({
        url: req_url,
        data: params,
        dataType: "json",
        success: onResponse.bind(this),
        error: function () {
          callback(true);
        }
      });
    }
  };
}

OSM.Directions.addEngine(new OSRMEngine(), true);
