# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0](https://github.com/dmnktoe/httpjpg-ios/compare/v1.3.0...v1.4.0) (2026-10-18)


### Added

* **nav:** liquid glass tab bar and a native info title ([#107](https://github.com/dmnktoe/httpjpg-ios/issues/107)) ([b264791](https://github.com/dmnktoe/httpjpg-ios/commit/b264791d619861db317e8f28621657b8c055fa6a))
* **search:** precise highlighting and tappable, cited-only sources ([#106](https://github.com/dmnktoe/httpjpg-ios/issues/106)) ([8ce166f](https://github.com/dmnktoe/httpjpg-ios/commit/8ce166f5cd348c84e7fa4577fae7e721dd037ade))

## [1.3.0](https://github.com/dmnktoe/httpjpg-ios/compare/v1.2.0...v1.3.0) (2026-10-18)


### Added

* **search:** polish the ask/search sheet ([#99](https://github.com/dmnktoe/httpjpg-ios/issues/99)) ([3e81a01](https://github.com/dmnktoe/httpjpg-ios/commit/3e81a01d66feecbb24371c18e843591ac8f6312c))


### Fixed

* **divider:** paint ascii dividers at full strength ([#97](https://github.com/dmnktoe/httpjpg-ios/issues/97)) ([320044d](https://github.com/dmnktoe/httpjpg-ios/commit/320044dc7f41f613c3dc2d6cf15c0bda5f1d086d))
* **richtext:** render Storyblok tables instead of dropping them ([#98](https://github.com/dmnktoe/httpjpg-ios/issues/98)) ([5eb385e](https://github.com/dmnktoe/httpjpg-ios/commit/5eb385e32689fd0274cc23a2d8a57cea29ef58b8))
* **search:** let results scroll beneath the sheet header ([#105](https://github.com/dmnktoe/httpjpg-ios/issues/105)) ([3b577c2](https://github.com/dmnktoe/httpjpg-ios/commit/3b577c2b9b84469e4acb66c2e2566edd12237d2b))
* **work:** keep the masthead from shifting when content loads ([#104](https://github.com/dmnktoe/httpjpg-ios/issues/104)) ([39c8614](https://github.com/dmnktoe/httpjpg-ios/commit/39c861415b1e60ff38f5f948390d25ea5846e397))


### Tooling

* derive the build number from the repository's commit count ([#103](https://github.com/dmnktoe/httpjpg-ios/issues/103)) ([d6941e8](https://github.com/dmnktoe/httpjpg-ios/commit/d6941e85576cbaa64399e723eb337b29d6b7ad34))
* raise the simulator app-size baseline to 82744 KiB ([#101](https://github.com/dmnktoe/httpjpg-ios/issues/101)) ([68aba1b](https://github.com/dmnktoe/httpjpg-ios/commit/68aba1b4c8bb9eb739e2d36d6f4949d7ed73e5a4))

## [1.2.0](https://github.com/dmnktoe/httpjpg-ios/compare/v1.1.0...v1.2.0) (2026-10-13)


### Added

* **layout:** responsive spacing, container, grid, prose width ([#90](https://github.com/dmnktoe/httpjpg-ios/issues/90)) ([ab4dce7](https://github.com/dmnktoe/httpjpg-ios/commit/ab4dce784df9ebdda9c13390f648f0133fae6ba8))

## [1.1.0](https://github.com/dmnktoe/httpjpg-ios/compare/v1.0.2...v1.1.0) (2026-10-13)


### Added

* **divider:** honor CMS thickness ([#88](https://github.com/dmnktoe/httpjpg-ios/issues/88)) ([1827845](https://github.com/dmnktoe/httpjpg-ios/commit/1827845d9cd062ffd1bddbd48c44d25a67893f24))
* native Ask · Search command palette with Liquid Glass ([#86](https://github.com/dmnktoe/httpjpg-ios/issues/86)) ([657cb57](https://github.com/dmnktoe/httpjpg-ios/commit/657cb57bc8676f77e6c2d0fcab2a3e21e0622080))
* **slideshow:** enable swipe on fade carousel ([#87](https://github.com/dmnktoe/httpjpg-ios/issues/87)) ([a5594a5](https://github.com/dmnktoe/httpjpg-ios/commit/a5594a576a7fd052918e8a827dfbf452e6e72743))
* **work_list:** honor gap, responsive columns, divider chrome ([#89](https://github.com/dmnktoe/httpjpg-ios/issues/89)) ([a455cde](https://github.com/dmnktoe/httpjpg-ios/commit/a455cdec1a1ac9fbe33a53128b9e988bce2bca01))


### Fixed

* **ui:** keep external ↗ as text instead of ↗️ emoji ([#91](https://github.com/dmnktoe/httpjpg-ios/issues/91)) ([87fb7fe](https://github.com/dmnktoe/httpjpg-ios/commit/87fb7fe7308294b85b2476368f16f366d6ef9db3))
* **widgets:** keep photos full-color under iOS tinted home screen ([#81](https://github.com/dmnktoe/httpjpg-ios/issues/81)) ([94f3172](https://github.com/dmnktoe/httpjpg-ios/commit/94f31725a76ca9863f1ac293b86046f6249bcc70))
* **xcode:** pin Package.resolved and DEVELOPMENT_TEAM ([#93](https://github.com/dmnktoe/httpjpg-ios/issues/93)) ([71db5c4](https://github.com/dmnktoe/httpjpg-ios/commit/71db5c44bc8718f169778cba290e4c4a0034dcd0))


### Changed

* remove redundant comments and dead code ([#94](https://github.com/dmnktoe/httpjpg-ios/issues/94)) ([306fedd](https://github.com/dmnktoe/httpjpg-ios/commit/306fedd9452d11502cb61971489608ba126f3aea))


### Tooling

* simulator tooling without a developer account ([#77](https://github.com/dmnktoe/httpjpg-ios/issues/77)) ([3ec0ec1](https://github.com/dmnktoe/httpjpg-ios/commit/3ec0ec180a20a69331615a355cd0d3ea078c0266))
* **snapshots:** pin render scale for macos-26 runners ([#95](https://github.com/dmnktoe/httpjpg-ios/issues/95)) ([f78ba41](https://github.com/dmnktoe/httpjpg-ios/commit/f78ba41c539db6c187cd9eeaec4ff42666c4b1d8))


### Dependencies

* pin dependencies ([#83](https://github.com/dmnktoe/httpjpg-ios/issues/83)) ([9e744e4](https://github.com/dmnktoe/httpjpg-ios/commit/9e744e4a5bee147d108d511c962533a44d6a2c5d))
* update dependency storyblok/storyblok-swift to v1 ([#92](https://github.com/dmnktoe/httpjpg-ios/issues/92)) ([271b112](https://github.com/dmnktoe/httpjpg-ios/commit/271b11297a817c8cad8c3ecb8a3688fab27c76f6))
* update swift packages ([#84](https://github.com/dmnktoe/httpjpg-ios/issues/84)) ([ce25bbd](https://github.com/dmnktoe/httpjpg-ios/commit/ce25bbdb6e72b262bb9f4264cc397360270d6a39))

## [1.0.2](https://github.com/dmnktoe/httpjpg-ios/compare/v1.0.1...v1.0.2) (2026-09-22)


### Tooling

* empty release-please component so merged release PRs tag ([#79](https://github.com/dmnktoe/httpjpg-ios/issues/79)) ([ca8519a](https://github.com/dmnktoe/httpjpg-ios/commit/ca8519a6df5c719cedfdb8cad5114a3964af8f6f))

## [1.0.1](https://github.com/dmnktoe/httpjpg-ios/compare/v1.0.0...v1.0.1) (2026-09-22)


### Fixed

* **ios:** drop stray vertical margin on pre code blocks ([#73](https://github.com/dmnktoe/httpjpg-ios/issues/73)) ([6e1a2f1](https://github.com/dmnktoe/httpjpg-ios/commit/6e1a2f16490215211bf2dbfcaab3ab2ccfc4a340))


### Tooling

* plastic README badges + iOS pull request template ([#74](https://github.com/dmnktoe/httpjpg-ios/issues/74)) ([d2eabba](https://github.com/dmnktoe/httpjpg-ios/commit/d2eabbaa14dab623a7c3dcf66153f2284d4c68cb))
* skip Blok registry and Build & test on release PRs ([#78](https://github.com/dmnktoe/httpjpg-ios/issues/78)) ([37d8c4e](https://github.com/dmnktoe/httpjpg-ios/commit/37d8c4ef54320607c4fb90ca79e4df80f05a96b5))

## [1.0.0](https://github.com/dmnktoe/httpjpg-ios/releases/tag/v1.0.0) (2026-09-22)

### Added

* Native SwiftUI reader for the httpjpg.com portfolio (Storyblok, widgets, watchOS companion)
