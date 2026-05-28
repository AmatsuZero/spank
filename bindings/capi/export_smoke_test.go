//go:build darwin && cgo

package main

import "testing"

func TestCAPIExportsSmoke(t *testing.T) {
	if got := float64(SpankCoreDefaultMinAmplitude()); got <= 0 || got >= 1 {
		t.Fatalf("SpankCoreDefaultMinAmplitude=%f out of expected range", got)
	}

	v := float64(SpankCoreAmplitudeToVolume(0.4))
	if v < -3.0 || v > 0.0 {
		t.Fatalf("SpankCoreAmplitudeToVolume(0.4)=%f out of range [-3,0]", v)
	}
}
