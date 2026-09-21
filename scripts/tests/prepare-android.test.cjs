const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { prepareAndroid } = require('../prepare-android.cjs');
function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'momotalk-build-test-'));
  function put(file, text) { fs.mkdirSync(path.dirname(path.join(root,file)), {recursive:true}); fs.writeFileSync(path.join(root,file),text); }
  put('build-profile.json5', '{app:{signingConfigs:[{name:"private-signing"}], products:[{name:"default",signingConfig:"private-signing"}]},modules:[]}');
  put('oh-package.json5', '{}');
  put('products/phone/src/main/module.json5','{module:{extensionAbilities:[{name:"Backup"}],abilities:[]}}');
  put('products/phone/src/main/ets/pages/Index.ets', 'shared-screen');
  put('products/phone/build/private.txt','generated output');
  put('components/lib_common/src/main/ets/utils/FileUtils.ets','harmony-api');
  put('platforms/android/overrides/FileUtils.ets','android-api');
  put('platforms/android/overrides.json', JSON.stringify({'components/lib_common/src/main/ets/utils/FileUtils.ets':'FileUtils.ets'}));
  put('platforms/android/native/settings.gradle', 'android-host');
  return root;
}
test('Android preparation retains shared screens, selects explicit adapters, and leaves Harmony source intact', () => {
  const root=fixture(); const out=prepareAndroid(root);
  assert.equal(fs.readFileSync(path.join(out,'products/phone/src/main/ets/pages/Index.ets'),'utf8'),'shared-screen');
  assert.equal(fs.readFileSync(path.join(out,'components/lib_common/src/main/ets/utils/FileUtils.ets'),'utf8'),'android-api');
  assert.equal(fs.readFileSync(path.join(root,'components/lib_common/src/main/ets/utils/FileUtils.ets'),'utf8'),'harmony-api');
  assert.equal(fs.existsSync(path.join(out,'products/phone/build')),false);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(out,'build-profile.json5'),'utf8')).app.signingConfigs,[]);
  const cross=JSON.parse(fs.readFileSync(path.join(out,'.arkui-x/arkui-x-config.json5'),'utf8'));
  assert.equal(cross.buildOption.ignoreCrossPlatform,false);
});
test('rejects traversal in adapter manifest before preparing any output', () => {
  const root=fixture();
  fs.writeFileSync(path.join(root,'platforms/android/overrides.json'),JSON.stringify({'../outside.ets':'FileUtils.ets'}));
  assert.throws(()=>prepareAndroid(root),/adapter target/);
  assert.equal(fs.existsSync(path.join(root,'build/arkuix')),false);
});
test('rejects a missing adapter rather than silently keeping an incompatible source file', () => {
  const root=fixture();
  fs.writeFileSync(path.join(root,'platforms/android/overrides.json'),JSON.stringify({'components/lib_common/missing.ets':'missing.ets'}));
  assert.throws(()=>prepareAndroid(root),/adapter source/);
});
