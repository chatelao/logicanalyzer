#!/bin/bash
set -e

# Create the hardware packages directly in the release_assets directory
zip -r release_assets/LogicAnalyzer-Gerber.zip Electronics/LogicAnalyzer/LogicAnalyzerV2/designs/jitx-design/kicad
zip -r release_assets/LogicAnalyzer-BOM.zip Electronics/LogicAnalyzer/LogicAnalyzerV2/designs/jitx-design/bom
zip -r release_assets/LogicAnalyzer-Enclosure.zip Enclosure/
