# MoMoTalk ArkUI-X migration

## Authorized scope
Migrate existing MoMoTalk towards HarmonyOS and Android with ArkUI-X. Preserve the current screens, role data, provider settings, lore, history and avatar flows. Add no product features. Retain Git history, baseline tag and the Cikamn/MoMoTalk remote. Publish reviewed changes without force pushing.

## Architecture
Keep products/phone as the shared ArkTS entry and retain the eight existing HAR modules. Keep the Android host under platforms/android/native. Generate build/arkuix from shared sources plus explicitly mapped Android overlays; the repository root stays a normal Harmony project. Use supported APIs and native bridges for platform services. Do not suppress compatibility diagnostics globally merely to obtain a successful build. Preserve existing preference keys and HarmonyOS bundle identity.

## Verification and completion
Establish the original HarmonyOS build result first. Check the complete dependency graph against the pinned ArkUI-X SDK. Build shared ArkTS and Android with the actual toolchains, then exercise existing navigation, character editing, settings and avatar paths on available devices. Live AI calls require existing user configuration and must not expose credentials. iOS is explicitly excluded by the user. Document any unverified platform accurately. Unvalidated migration code stays on the migration branch, not the stable baseline.

## Toolchain
Verified toolchain: ArkUI-X 6.1.1.100 (API 24), Hvigor cross-platform plugin 4.24.4, DevEco Harmony SDK 6.1.1.125 (API 24), Android SDK 35, Gradle 8.9 / AGP 8.7.3. SDK 22 was rejected during compatibility verification. SDKs and generated outputs are local ignored files, never vendored into Git. Existing dependencies remain pinned unless migration requires a documented replacement.


Android mock login is explicitly authorized and labeled. Current runtime verification is API28 x86_64, text chat with a local mock endpoint, persisted history/settings/roles, and image selection/cropping. No real provider credentials, ARM device, or optional Huawei speech service verification is claimed.
