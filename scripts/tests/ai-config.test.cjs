const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
if (!process.env.DEVECO_STUDIO_HOME) throw new Error('Set DEVECO_STUDIO_HOME to run ArkTS configuration tests using the installed DevEco TypeScript compiler');
const ts = require(path.join(process.env.DEVECO_STUDIO_HOME, 'tools/hvigor/hvigor/node_modules/typescript'));
const source = fs.readFileSync(path.resolve(__dirname, '../../products/phone/src/main/ets/common/AIConfig.ets'), 'utf8');
const code = ts.transpileModule(source, {compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020}}).outputText;
function loadModule(saved, bundled) {
  const exports = {};
  const preferences = {get: () => saved};
  const resourceManager = {getRawFileContentSync: (name) => {
    assert.equal(name, 'ai_defaults.local.json');
    if (bundled === undefined) throw new Error('No local development resource');
    return Buffer.from(bundled);
  }};
  vm.runInNewContext(code, {exports, getContext: () => ({resourceManager}), require: (name) => {
    if (name === 'lib_common') return {PreferenceUtils: {getInstance: () => preferences}};
    if (name === '@kit.ArkTS') return {util: {TextDecoder: {create: () => ({decodeToString: (bytes) => Buffer.from(bytes).toString('utf8')})}}};
    throw new Error('Unexpected import: ' + name);
  }});
  return exports;
}
function load(saved, bundled) {
  return loadModule(saved, bundled).AIConfigStore.load();
}
const builtin = JSON.stringify({apiKey: 'offline-development-fixture'});
test('fresh install loads the bundled DeepSeek development credential', () => {
  const config = load('', builtin);
  assert.equal(config.apiKey, 'offline-development-fixture');
  assert.equal(config.provider, 'deepseek');
  assert.equal(config.baseUrl, 'https://api.deepseek.com');
  assert.ok(config.model);
});
test('complete user configuration overrides the bundled service as a unit', () => {
  const config = load(JSON.stringify({provider: 'custom', baseUrl: 'https://example.invalid/v1', model: 'custom-model', apiKey: 'user-fixture'}), builtin);
  assert.equal(config.baseUrl, 'https://example.invalid/v1');
  assert.equal(config.apiKey, 'user-fixture');
  assert.equal(config.model, 'custom-model');
});
test('incomplete custom settings never send the development key to the custom endpoint', () => {
  const config = load(JSON.stringify({provider: 'custom', baseUrl: 'https://example.invalid/v1', model: 'custom-model', apiKey: ' ', assistantName: 'Existing role'}), builtin);
  assert.equal(config.baseUrl, 'https://api.deepseek.com');
  assert.equal(config.apiKey, 'offline-development-fixture');
  assert.equal(config.assistantName, 'Existing role');
});
test('malformed saved settings fall back to the bundled service', () => {
  assert.equal(load('{broken', builtin).apiKey, 'offline-development-fixture');
  assert.equal(load('null', builtin).apiKey, 'offline-development-fixture');
});
test('public checkout without a local key and malformed local resources remain unconfigured', () => {
  for (const bundled of [undefined, '{broken', 'null', '{"apiKey":24}', '{"apiKey":"  "}']) {
    assert.equal(load('', bundled).apiKey, '');
  }
});

test('switching providers clears the previous credential, reselecting the same provider preserves it', () => {
  const module = loadModule('', builtin);
  const config = module.AIConfigStore.load();
  module.AIConfigStore.applyProvider(config, 'deepseek');
  assert.equal(config.apiKey, 'offline-development-fixture');
  module.AIConfigStore.applyProvider(config, 'custom');
  assert.equal(config.apiKey, '');
});

test('changing the endpoint clears its credential before model lookup or saving', () => {
  const module = loadModule('', builtin);
  const config = module.AIConfigStore.load();
  module.AIConfigStore.applyBaseUrl(config, ' https://api.deepseek.com/ ');
  assert.equal(config.apiKey, 'offline-development-fixture');
  module.AIConfigStore.applyBaseUrl(config, 'https://example.invalid/v1');
  assert.equal(config.apiKey, '');
  assert.equal(config.baseUrl, 'https://example.invalid/v1');
});
