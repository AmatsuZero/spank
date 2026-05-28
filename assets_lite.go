//go:build lite && !with_assets

package spank

import "embed"

var painAudio embed.FS
var sexyAudio embed.FS
var haloAudio embed.FS
var lizardAudio embed.FS

const builtInAssetsEnabled = false
