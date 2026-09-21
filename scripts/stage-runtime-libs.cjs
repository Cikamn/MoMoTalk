const fs = require('node:fs');
const path = require('node:path');
const JSON5 = require('json5');
// Bytecode HAR imports and UIContext-internal APIs are not all detected by Hvigor.
// Resolve their explicit modules and dependencies using the installed SDK metadata.
function stageRuntimeLibraries(sdkRoot, libsRoot, modules) {
  const registry = new Map();
  for (const part of ['engine', 'plugins/api']) {
    for (const item of JSON5.parse(fs.readFileSync(path.join(sdkRoot,part,'apiConfig.json'),'utf8'))) {
      registry.set(item.module,{...item,base:path.join(sdkRoot,part)});
    }
  }
  const visited = new Set(), copies = new Map();
  function visit(name) {
    if (visited.has(name)) return;
    const item = registry.get(name);
    if (!item) throw new Error('Unknown runtime module: '+name);
    visited.add(name);
    for (const dep of item.deps?.android || []) visit(dep);
    for (const relative of item.library?.android || []) {
      for (const [sdkArch,apkArch] of [['android-arm64-release','arm64-v8a'],['android-x86_64','x86_64']]) {
        const source = path.resolve(item.base,relative.replace('arch_type',sdkArch));
        if (!source.startsWith(path.resolve(sdkRoot)+path.sep) || !fs.existsSync(source)) throw new Error('Missing runtime library: '+source);
        const destination = path.join(libsRoot,relative.endsWith('.so')?apkArch:'',path.basename(source));
        copies.set(destination,source);
      }
    }
  }
  modules.forEach(visit);
  for (const [destination,source] of copies) {
    fs.mkdirSync(path.dirname(destination),{recursive:true});
    fs.copyFileSync(source,destination);
  }
  return copies.size;
}
module.exports = {stageRuntimeLibraries};
if (require.main === module) {
  const modules = JSON5.parse(fs.readFileSync(path.join(__dirname,'../platforms/android/runtime-modules.json'),'utf8'));
  console.log('Staged indirect runtime libraries: '+stageRuntimeLibraries(process.argv[2],process.argv[3],modules));
}
