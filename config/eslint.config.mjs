import globals from "globals";
import js from "@eslint/js";
import erb from "eslint-plugin-erb";
import stylisticJs from "@stylistic/eslint-plugin-js";

export default [
  js.configs.recommended,
  erb.configs.recommended,
  {
    ignores: [
      "app/assets/javascripts/i18n/",
      "coverage/assets/",
      "public/assets/",
      "vendor/"
    ]
  },
  {
    plugins: {
      "@stylistic": stylisticJs
    },
    languageOptions: {
      ecmaVersion: 2021,
      sourceType: "script",
      globals: {
        ...globals.browser,
        ...globals.jquery,
        Cookies: "readonly",
        I18n: "readonly",
        L: "readonly",
        Matomo: "readonly",
        OSM: "writable",
        Turbo: "readonly",
        plurals: "readonly",
        updateLinks: "readonly"
      }
    },
    linterOptions: {
      // The "unused disable directive" is set to "warn" by default.
      // For the ERB plugin to work correctly, you must disable
      // this directive to avoid issues described here
      // https://github.com/eslint/eslint/discussions/18114
      // If you're using the CLI, you might also use the following flag:
      // --report-unused-disable-directives-severity=off
      reportUnusedDisableDirectives: "off"
    },
    rules: {
      "@stylistic/array-bracket-newline": ["error", "consistent"],
      "@stylistic/array-bracket-spacing": "error",
      "@stylistic/block-spacing": "error",
      "@stylistic/brace-style": ["error", "1tbs", { allowSingleLine: true }],
      "@stylistic/comma-dangle": "error",
      "@stylistic/comma-spacing": "error",
      "@stylistic/comma-style": "error",
      "@stylistic/computed-property-spacing": "error",
      "@stylistic/dot-location": ["error", "property"],
      "@stylistic/eol-last": "error",
      "@stylistic/func-call-spacing": "error",
      "@stylistic/indent": ["error", 2, {
        CallExpression: { arguments: "first" },
        FunctionDeclaration: { parameters: "first" },
        FunctionExpression: { parameters: "first" },
        SwitchCase: 1,
        VariableDeclarator: "first"
      }],
      "@stylistic/key-spacing": "error",
      "@stylistic/keyword-spacing": "error",
      "@stylistic/max-statements-per-line": "error",
      "@stylistic/no-floating-decimal": "error",
      "@stylistic/no-mixed-operators": "error",
      "@stylistic/no-multi-spaces": "error",
      "@stylistic/no-multiple-empty-lines": "error",
      "@stylistic/no-trailing-spaces": "error",
      "@stylistic/no-whitespace-before-property": "error",
      "@stylistic/object-curly-newline": ["error", { consistent: true }],
      "@stylistic/object-curly-spacing": ["error", "always"],
      "@stylistic/object-property-newline": ["error", { allowAllPropertiesOnSameLine: true }],
      "@stylistic/one-var-declaration-per-line": "error",
      "@stylistic/operator-linebreak": ["error", "after"],
      "@stylistic/padded-blocks": ["error", "never"],
      "@stylistic/quote-props": ["error", "consistent-as-needed", { keywords: true, numbers: true }],
      "@stylistic/quotes": ["error", "double"],
      "@stylistic/semi": ["error", "always"],
      "@stylistic/semi-spacing": "error",
      "@stylistic/semi-style": "error",
      "@stylistic/space-before-blocks": "error",
      "@stylistic/space-before-function-paren": ["error", { named: "never" }],
      "@stylistic/space-in-parens": "error",
      "@stylistic/space-infix-ops": "error",
      "@stylistic/space-unary-ops": "error",
      "@stylistic/switch-colon-spacing": "error",
      "@stylistic/wrap-iife": "error",
      "@stylistic/wrap-regex": "error",

      "accessor-pairs": "error",
      "array-callback-return": "error",
      "block-scoped-var": "error",
      "curly": ["error", "multi-line", "consistent"],
      "dot-notation": "error",
      "eqeqeq": ["error", "smart"],
      "no-alert": "error",
      "no-array-constructor": "error",
      "no-caller": "error",
      "no-console": "warn",
      "no-div-regex": "error",
      "no-eq-null": "error",
      "no-eval": "error",
      "no-extend-native": "error",
      "no-extra-bind": "error",
      "no-extra-label": "error",
      "no-implicit-coercion": "warn",
      "no-implicit-globals": "error",
      "no-implied-eval": "error",
      "no-invalid-this": "error",
      "no-iterator": "error",
      "no-label-var": "error",
      "no-labels": "error",
      "no-lone-blocks": "error",
      "no-lonely-if": "error",
      "no-loop-func": "error",
      "no-multi-str": "error",
      "no-negated-condition": "error",
      "no-nested-ternary": "error",
      "no-new": "error",
      "no-new-func": "error",
      "no-new-wrappers": "error",
      "no-object-constructor": "error",
      "no-octal-escape": "error",
      "no-param-reassign": "error",
      "no-proto": "error",
      "no-script-url": "error",
      "no-self-compare": "error",
      "no-sequences": "error",
      "no-throw-literal": "error",
      "no-undef-init": "error",
      "no-undefined": "error",
      "no-unmodified-loop-condition": "error",
      "no-unneeded-ternary": "error",
      "no-unused-expressions": "off",
      "no-unused-vars": ["error", { caughtErrors: "none" }],
      "no-use-before-define": ["error", { functions: false }],
      "no-useless-call": "error",
      "no-useless-concat": "error",
      "no-useless-return": "error",
      "no-var": "error",
      "no-void": "error",
      "no-warning-comments": "warn",
      "operator-assignment": "error",
      "prefer-const": "error",
      "prefer-object-spread": "error",
      "radix": ["error", "always"],
      "yoda": "error"
    }
  },
  {
    // Additional configuration for test files
    files: ["test/**/*.js"],
    languageOptions: {
      globals: {
        ...globals.mocha,
        expect: "readonly",
        assert: "readonly",
        should: "readonly"
      }
    }
  },
  {
    files: ["config/eslint.config.mjs"],
    languageOptions: {
      sourceType: "module"
    },
    rules: {
      "sort-keys": ["error", "asc", { minKeys: 5 }]
    }
  }
];
