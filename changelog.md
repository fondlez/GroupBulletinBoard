# Changelog for "GroupBulletinBoard"

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-11-07

### Added
- added support for Wrath of the Lich King expansion (WotLK) content
- added a larger range of default Blacklist terms

## [1.1.1] - 2024-12-25

### Fixed
- correct some Interface options alignment and text formatting issues

## [1.1.0] - 2024-12-08

### Changed
- added the contents of a request message on mouseover to a tooltip at the top
of the main window. This allows seeing the full message without resizing the
main window

## [1.0.1] - 2024-11-30

### Fixed
- stop minimap button resetting position when Settings updated

## [1.0.0] - 2024-11-27

Initial public release.

### Added
- ported to the WotLK 3.3.5a client.
- README.md

### Fixed
- configuration error causing a UI error from assumed global channel called 
"world". Some servers use "global" channel instead. Assumed global channel 
removed.

### Changed
- removed all version broadcast code.
- removed all third party libraries (AceComm-3.0, CallbackHandler-1.0 and 
LibStub). These were only being used to support the version broadcast code.