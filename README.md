# Karen-CharMap

Karen-CharMap is a macOS app for browsing and inserting Karen and related Unicode characters in a fast, visual way.

## Overview

The app provides a searchable character map for:

- Myanmar characters
- Myanmar Extended-A and Extended-B ranges
- Basic Latin letters and numbers
- Special punctuation and symbols

Users can:

- browse characters by Unicode group
- filter by search term, hex code, or Unicode name
- inspect metadata such as character name and code point
- insert a character directly into a composed text field
- copy characters or code values to the clipboard

## Features

- Visual Unicode map with grouped character sets
- Search across character names and code points
- Hex and decimal lookup
- Character inspector panel with metadata
- Designed for Karen text workflows and script exploration
- Uses the bundled Padauk font for script-friendly display

## Requirements

- macOS
- Xcode 15 or later
- SwiftUI-supported macOS environment

## Run the project

1. Open `Karen-CharMap.xcodeproj` in Xcode.
2. Select a Mac target or the app scheme.
3. Build and run the project.

## Project structure

- `Karen-CharMap/` — SwiftUI app source files
- `Karen-CharMap.xcodeproj/` — Xcode project configuration
- `Karen-CharMap/Padauk-Regular.ttf` — bundled font used for script display
- `Karen-CharMap/Padauk-OFL.txt` — license text for the Padauk font

## Notes

This project is intended as a local utility for exploring Unicode characters used in Karen and related scripts. It is best suited for desktop use on macOS and can be extended with additional character groups or export features if needed.
