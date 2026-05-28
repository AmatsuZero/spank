package mobile

import "testing"

func TestMobileExportsSmoke(t *testing.T) {
	if got := DefaultMinAmplitude(); got <= 0 || got >= 1 {
		t.Fatalf("DefaultMinAmplitude=%f out of expected range", got)
	}

	if v := AmplitudeToVolume(0.4); v < -3.0 || v > 0.0 {
		t.Fatalf("AmplitudeToVolume(0.4)=%f out of range [-3,0]", v)
	}
}

func TestGateAcceptAndUpdateSmoke(t *testing.T) {
	g := NewGate(0.5, 2000)
	base := int64(1_700_000_000_000_000_000)

	if ok := g.Accept(base, 0.6, "shock", base); !ok {
		t.Fatal("first event should pass gate")
	}

	// Update to lower threshold and shorter cooldown.
	g.Update(0.1, 200)

	if ok := g.Accept(base+300_000_000, 0.2, "shock", base+300_000_000); !ok {
		t.Fatal("event should pass after gate update")
	}
}
