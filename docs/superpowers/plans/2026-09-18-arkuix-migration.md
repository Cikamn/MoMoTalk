# MoMoTalk ArkUI-X Migration Implementation Plan

> Execute inline, preserving existing application behavior and Git history.

**Goal:** Prepare the existing app for HarmonyOS and Android using ArkUI-X.
**Architecture:** Shared ArkTS app plus official platform hosts and explicit API adapters.
**Tech Stack:** ArkTS/ArkUI, ArkUI-X, Hvigor/OHPM, Android Gradle.
**Spec:** ../specs/2026-09-18-arkuix-migration-design.md

## Global constraints
No new product features. No destructive Git operations. Preserve preference names, app identity, roles and history. Never claim platform support based on scaffold generation alone.

## Tasks
- [x] Establish the HarmonyOS baseline with the installed Hvigor; record toolchain versions and failures.
- [x] Obtain and verify official ArkUI-X SDK, inspect its migration templates and API analysis tool; inventory direct and transitive unsupported APIs.
- [x] Generate native hosts and configure cross-platform build using the official toolchain; keep SDK paths and signing material local.
- [x] Adapt incompatible calls while preserving their behavior. Test new adapter logic for platform routing/error behavior before using it.
- [x] Compile and test HarmonyOS and Android; validate existing user flows on available simulators. Do not generate an iOS host.
- [x] Update project/build documentation and review the full diff and secret scan. Commit and push the migration branch; integrate only verified work, preserving the original baseline.


2026-09-21: implementation uses Android overlays and native host under platforms/android, generated build/arkuix, strict cross-platform checking, API24 SDK. API28 emulator verified actual user flows. Review and credential-pattern checks passed. Implementation commit 04972a1 was pushed to codex/arkuix-migration and fast-forwarded into local and remote develop. main and baseline-2026-09-18 remain at the original presentation baseline.
