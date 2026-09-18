# MoMoTalk ArkUI-X Migration Implementation Plan

> Execute inline, preserving existing application behavior and Git history.

**Goal:** Prepare the existing app for HarmonyOS and Android using ArkUI-X.
**Architecture:** Shared ArkTS app plus official platform hosts and explicit API adapters.
**Tech Stack:** ArkTS/ArkUI, ArkUI-X, Hvigor/OHPM, Android Gradle.
**Spec:** ../specs/2026-09-18-arkuix-migration-design.md

## Global constraints
No new product features. No destructive Git operations. Preserve preference names, app identity, roles and history. Never claim platform support based on scaffold generation alone.

## Tasks
- [ ] Establish the HarmonyOS baseline with the installed Hvigor; record toolchain versions and failures.
- [ ] Obtain and verify official ArkUI-X SDK, inspect its migration templates and API analysis tool; inventory direct and transitive unsupported APIs.
- [ ] Generate native hosts and configure cross-platform build using the official toolchain; keep SDK paths and signing material local.
- [ ] Adapt incompatible calls while preserving their behavior. Test new adapter logic for platform routing/error behavior before using it.
- [ ] Compile and test HarmonyOS and Android; validate existing user flows on available simulators. Do not generate an iOS host.
- [ ] Update project/build documentation and review the full diff and secret scan. Commit and push the migration branch; integrate only verified work, preserving the original baseline.

