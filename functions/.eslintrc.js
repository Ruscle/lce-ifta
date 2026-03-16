module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
  ],
  parserOptions: {
    ecmaVersion: 2020,
  },
  rules: {
    "max-len": "off",
    "require-jsdoc": "off",
    "indent": "off",
    "comma-dangle": "off",
    "padded-blocks": "off",
    "object-curly-spacing": "off",
  },
};
