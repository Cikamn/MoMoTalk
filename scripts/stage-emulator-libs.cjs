const fs = require('node:fs');
const path = require('node:path');
// Hvigor ArkUI-X 4.24.4 stages ARM libraries only. Match its selected libraries
// against the SAME SDK's emulator architecture; never substitute ARM binaries.
function stageEmulatorLibraries(sdkRoot, libsRoot) {
  const selected = fs.readdirSync(path.join(libsRoot, 'arm64-v8a')).filter(n => n.endsWith('.so'));
  if (!selected.length) throw new Error('No ARM libraries staged; run ArkUI-X resource tasks first');
  const candidates = new Map();
  function scan(dir) {
    for (const entry of fs.readdirSync(dir, {withFileTypes:true})) {
      const file = path.join(dir, entry.name);
      if (entry.isDirectory()) scan(file);
      else if (entry.isFile() && path.basename(dir) === 'android-x86_64' && selected.includes(entry.name)) {
        if (candidates.has(entry.name) && !fs.readFileSync(candidates.get(entry.name)).equals(fs.readFileSync(file))) throw new Error('Ambiguous x86_64 library: ' + entry.name);
        candidates.set(entry.name, file);
      }
    }
  }
  scan(sdkRoot);
  for (const name of selected) if (!candidates.has(name)) throw new Error('Missing x86_64 library: ' + name);
  const destination = path.join(libsRoot, 'x86_64');
  fs.mkdirSync(destination, {recursive:true});
  for (const name of selected) fs.copyFileSync(candidates.get(name), path.join(destination, name));
  return selected.length;
}
module.exports = {stageEmulatorLibraries};
if (require.main === module) console.log('Staged x86_64 libraries: ' + stageEmulatorLibraries(process.argv[2], process.argv[3]));
