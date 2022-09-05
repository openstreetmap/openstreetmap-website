(function () {
  var isTokenField = /^\{name/;

  var isLanguageField = /^name:/;

  function adaptPropertyLanguageWithLegacySupport(
    isLangField,
    property,
    languageFieldName,
  ) {
    if (
      property.length === 4 &&
      property[0] === 'coalesce' &&
      typeof property[3] === 'string' &&
      isTokenField.test(property[3])
    ) {
      // Back to original format string for legacy
      property = property[3];
    }

    if (typeof property === 'string') {
      // Only support legacy format string at top level
      if (languageFieldName !== 'name' && isTokenField.test(property)) {
        var splitLegacity = splitLegacityFormat(property);
        // The last is not used, it is the original value to be restore
        return [
          'coalesce',
          adaptLegacyExpression(splitLegacity, languageFieldName),
          splitLegacity,
          property,
        ];
      } else {
        return property;
      }
    } else {
      return adaptPropertyLanguage(isLangField, property, languageFieldName);
    }
  }

  function splitLegacityFormat(s) {
    var ret = ['concat'];
    var sub = '';
    for (var i = 0; i < s.length; i++) {
      if (s[i] === '{') {
        if (sub) {
          ret.push(sub);
        }
        sub = '';
      } else if (s[i] === '}') {
        if (sub) {
          ret.push(['get', sub]);
        }
        sub = '';
      } else {
        sub += s[i];
      }
    }

    if (sub) {
      ret.push(sub);
    }

    return ret;
  }

  function adaptLegacyExpression(expressions, languageFieldName) {
    // Kepp only first get name express
    var isName = false;
    var ret = [];
    expressions.forEach(function (expression) {
      // ['get', 'name:.*']
      if (
        Array.isArray(expression) &&
        expression.length >= 2 &&
        typeof expression[1] === 'string' &&
        isLanguageField.test(expression[1])
      ) {
        if (!isName) {
          isName = true;
          ret.push(['coalesce', ['get', languageFieldName], expression]);
        }
      } else {
        ret.push(expression);
      }
    });

    return ret;
  }

  function adaptNestedExpressionField(
    isLangField,
    properties,
    languageFieldName,
  ) {
    properties.forEach(function (property) {
      if (Array.isArray(property)) {
        if (isFlatExpressionField(isLangField, property)) {
          property[1] = languageFieldName;
        }
        adaptNestedExpressionField(isLangField, property, languageFieldName);
      }
    });
  }

  function adaptPropertyLanguage(
    isLangField,
    property,
    languageFieldName,
  ) {
    if (isFlatExpressionField(isLangField, property)) {
      property[1] = languageFieldName;
    }

    adaptNestedExpressionField(isLangField, property, languageFieldName);

    // handle special case of bare ['get', 'name'] expression by wrapping it in a coalesce statement
    if (property[0] === 'get' && property[1] === 'name') {
      var defaultProp = property.slice();
      var adaptedProp = ['get', languageFieldName];
      property = ['coalesce', adaptedProp, defaultProp];
    }

    return property;
  }

  function isFlatExpressionField(isLangField, property) {
    var isGetExpression = property.length >= 2 && property[0] === 'get';
    if (isGetExpression && typeof property[1] === 'string' && isTokenField.test(property[1])) {
      console.warn(
        'This plugin no longer supports the use of token syntax (e.g. {name}). Please use a get expression. See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/ for more details.',
      );
    }

    return isGetExpression && typeof property[1] === 'string' && isLangField.test(property[1]);
  }

  function getLanguageField(language) {
    return language === 'mul' ? 'name' : `name:${language}`;
  }

  maplibregl.Map.prototype.setLanguage = function(language) {
    var self = this;

    this.getStyle().layers
      .filter(function (layer) { return layer.type === 'symbol'})
      .forEach(function (layer) {
        if (layer.layout && typeof layer.layout['text-field'] === 'string') {
          self.setLayoutProperty(
            layer.id,
            'text-field',
            adaptPropertyLanguageWithLegacySupport(
              /^name:/,
              layer.layout['text-field'],
              getLanguageField(language),
            ),
          );
        }
      });
  }
})();


