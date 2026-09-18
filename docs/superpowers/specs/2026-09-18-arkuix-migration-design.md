# MoMoTalk ArkUI-X migration

## Authorized scope
Migrate existing MoMoTalk towards HarmonyOS and Android with ArkUI-X. Preserve the current screens, role data, provider settings, lore, history and avatar flows. Add no product features. Retain Git history, baseline tag and the Cikamn/MoMoTalk remote. Publish reviewed changes without force pushing.

## Architecture
Keep products/phone as the shared ArkTS entry and retain the eight existing HAR modules. Add official ArkUI-X native host projects under .arkui-x. Use supported ArkUI-X APIs wherever possible; put unavoidable platform differences behind explicit platform checks or native bridges. Do not suppress compatibility diagnostics globally merely to obtain a successful build. Preserve existing preference keys and HarmonyOS bundle identity.

## Verification and completion
Establish the original HarmonyOS build result first. Check the complete dependency graph against the pinned ArkUI-X SDK. Build shared ArkTS and Android with the actual toolchains, then exercise existing navigation, character editing, settings and avatar paths on available devices. Live AI calls require existing user configuration and must not expose credentials. iOS is explicitly excluded by the user. Document any unverified platform accurately. Unvalidated migration code stays on the migration branch, not the stable baseline.

## Toolchain
Official ArkUI-X 6.0.2.118 (API 22) is the candidate pending compatibility with the installed DevEco toolchain (API 24). SDKs and generated outputs are local ignored files, never vendored into Git. Existing dependencies remain pinned unless migration requires a documented replacement.

