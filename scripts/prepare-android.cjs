const fs = require('node:fs');
const path = require('node:path');
const JSON5 = require('json5');
const SKIP = new Set(['build','oh_modules','node_modules','.hvigor','.preview','.idea','.gradle']);
function readJson(file) { return JSON5.parse(fs.readFileSync(file,'utf8')); }
function writeJson(file, data) { fs.mkdirSync(path.dirname(file),{recursive:true}); fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n'); }
function copy(source, destination) {
  if (!fs.existsSync(source)) return;
  const stat=fs.lstatSync(source);
  if (stat.isSymbolicLink()) throw new Error('Source symlinks are not copied: '+source);
  if (stat.isDirectory()) {
    fs.mkdirSync(destination,{recursive:true});
    for (const name of fs.readdirSync(source)) {
      if (!SKIP.has(name) && name !== 'BuildProfile.ets' && name !== 'local.properties') copy(path.join(source,name),path.join(destination,name));
    }
  } else fs.copyFileSync(source,destination);
}
function prepareAndroid(projectRoot) {
  const root=fs.realpathSync(projectRoot);
  const adapters=readJson(path.join(root,'platforms/android/overrides.json'));
  for (const [target,source] of Object.entries(adapters)) {
    if (!/^(components|products)\/[a-zA-Z0-9_./-]+\.ets$/.test(target) || target.split('/').includes('..')) throw new Error('Invalid adapter target: '+target);
    if (!/^[a-zA-Z0-9_-]+\.ets$/.test(source) || !fs.existsSync(path.join(root,'platforms/android/overrides',source))) throw new Error('Missing or invalid adapter source: '+source);
    if (!fs.existsSync(path.join(root,target))) throw new Error('Adapter target does not exist: '+target);
  }
  // Only the fixed generated directory inside this project can be recreated.
  const build=path.join(root,'build');
  const output=path.join(build,'arkuix');
  if (fs.existsSync(build) && (fs.lstatSync(build).isSymbolicLink() || fs.realpathSync(build)!==build)) throw new Error('Unsafe build directory');
  if (fs.existsSync(output)) {
    if (fs.lstatSync(output).isSymbolicLink() || fs.realpathSync(output)!==output) throw new Error('Unsafe generated directory');
    fs.rmSync(output,{recursive:true});
  }
  fs.mkdirSync(output,{recursive:true});
  for (const entry of ['AppScope','components','products','oh-package.json5','oh-package-lock.json5','build-profile.json5']) copy(path.join(root,entry),path.join(output,entry));
  for (const [target,source] of Object.entries(adapters)) fs.copyFileSync(path.join(root,'platforms/android/overrides',source),path.join(output,target));
  const profile=readJson(path.join(output,'build-profile.json5'));
  profile.app.signingConfigs=[];
  for (const product of profile.app.products) delete product.signingConfig;
  writeJson(path.join(output,'build-profile.json5'),profile);
  const moduleFile=path.join(output,'products/phone/src/main/module.json5');
  const module=readJson(moduleFile);
  delete module.module.extensionAbilities;
  writeJson(moduleFile,module);
  writeJson(path.join(output,'hvigor/hvigor-config.json5'),{modelVersion:'5.0.5',dependencies:{'@ohos/hvigor-ohos-arkui-x-plugin':'4.24.4'}});
  fs.writeFileSync(path.join(output,'hvigorfile.ts'),"import { AppTasksForArkUIX } from '@ohos/hvigor-ohos-arkui-x-plugin';\nexport default { system: AppTasksForArkUIX, plugins: [] };\n");
  fs.writeFileSync(path.join(output,'products/phone/hvigorfile.ts'),"import { HapTasks } from '@ohos/hvigor-ohos-arkui-x-plugin';\nexport default { system: HapTasks, plugins: [] };\n");
  writeJson(path.join(output,'.arkui-x/arkui-x-config.json5'),{crossplatform:true,modules:['phone'],buildOption:{ignoreCrossPlatform:false}});
  copy(path.join(root,'platforms/android/native'),path.join(output,'.arkui-x/android'));
  const tools = path.join(output,'.arkui-x/android/tools');
  fs.mkdirSync(tools,{recursive:true});
  for (const name of ['stage-native.cjs','stage-runtime-libs.cjs','stage-emulator-libs.cjs']) {
    copy(path.join(root,'scripts',name),path.join(tools,name));
  }
  copy(path.join(root,'platforms/android/runtime-modules.json'),path.join(tools,'runtime-modules.json'));
  return output;
}
module.exports={prepareAndroid};
if(require.main===module) console.log(prepareAndroid(path.resolve(__dirname,'..')));
