#!/usr/bin/env bash
set -e

flatpak-builder --force-clean --repo=repo build-dir io.flatscrew.RasterFlow.yml
flatpak build-bundle repo rasterflow.flatpak io.flatscrew.RasterFlow
flatpak install rasterflow.flatpak
# flatpak run io.flatscrew.RasterFlow