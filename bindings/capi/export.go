package main

/*
#include <stdint.h>
*/
import "C"

import "github.com/taigrr/spank/pkg/core"

// SpankCoreDefaultMinAmplitude returns the default detection threshold.
//
//export SpankCoreDefaultMinAmplitude
func SpankCoreDefaultMinAmplitude() C.double {
	return C.double(core.DefaultMinAmplitude)
}

// SpankCoreAmplitudeToVolume maps amplitude to volume in range [-3.0, 0.0].
//
//export SpankCoreAmplitudeToVolume
func SpankCoreAmplitudeToVolume(amplitude C.double) C.double {
	return C.double(core.AmplitudeToVolume(float64(amplitude)))
}

func main() {}
