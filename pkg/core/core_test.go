package core

import (
	"math"
	"testing"
	"time"
)

func TestDefaultTuning(t *testing.T) {
	tuning := DefaultTuning()
	if tuning.MinAmplitude != DefaultMinAmplitude {
		t.Fatalf("MinAmplitude=%v, want %v", tuning.MinAmplitude, DefaultMinAmplitude)
	}
	if tuning.Cooldown != DefaultCooldown {
		t.Fatalf("Cooldown=%v, want %v", tuning.Cooldown, DefaultCooldown)
	}
	if tuning.PollInterval != DefaultSensorPollInterval {
		t.Fatalf("PollInterval=%v, want %v", tuning.PollInterval, DefaultSensorPollInterval)
	}
	if tuning.MaxBatch != DefaultMaxSampleBatch {
		t.Fatalf("MaxBatch=%d, want %d", tuning.MaxBatch, DefaultMaxSampleBatch)
	}
}

func TestApplyFastOverlay(t *testing.T) {
	base := RuntimeTuning{
		MinAmplitude: 0.5,
		Cooldown:     2 * time.Second,
		PollInterval: 10 * time.Millisecond,
		MaxBatch:     200,
	}
	got := ApplyFastOverlay(base)

	if got.PollInterval != 4*time.Millisecond {
		t.Fatalf("PollInterval=%v, want 4ms", got.PollInterval)
	}
	if got.Cooldown != 350*time.Millisecond {
		t.Fatalf("Cooldown=%v, want 350ms", got.Cooldown)
	}
	if got.MinAmplitude != 0.18 {
		t.Fatalf("MinAmplitude=%v, want 0.18", got.MinAmplitude)
	}
	if got.MaxBatch != 320 {
		t.Fatalf("MaxBatch=%d, want 320", got.MaxBatch)
	}
}

func TestSlapTrackerRecordAndEscalation(t *testing.T) {
	files := []string{"1.mp3", "2.mp3", "3.mp3", "4.mp3"}
	tracker := NewSlapTracker(files, ModeEscalation, 750*time.Millisecond)

	n1, s1 := tracker.Record(time.Now())
	if n1 != 1 {
		t.Fatalf("first slap number=%d, want 1", n1)
	}
	if s1 <= 0 {
		t.Fatalf("first score=%f, want > 0", s1)
	}

	n2, s2 := tracker.Record(time.Now().Add(1 * time.Second))
	if n2 != 2 {
		t.Fatalf("second slap number=%d, want 2", n2)
	}
	if s2 <= s1 {
		t.Fatalf("second score=%f, want > first score=%f", s2, s1)
	}

	if got := tracker.GetFile(1.0); got != "1.mp3" {
		t.Fatalf("GetFile(1.0)=%q, want first file", got)
	}
	if got := tracker.GetFile(1000.0); got != "4.mp3" {
		t.Fatalf("GetFile(1000)=%q, want last file", got)
	}
}

func TestSlapTrackerRandomModeReturnsKnownFile(t *testing.T) {
	files := []string{"a.mp3", "b.mp3", "c.mp3"}
	tracker := NewSlapTracker(files, ModeRandom, 750*time.Millisecond)

	known := map[string]bool{
		"a.mp3": true,
		"b.mp3": true,
		"c.mp3": true,
	}

	for i := 0; i < 30; i++ {
		got := tracker.GetFile(1.0)
		if !known[got] {
			t.Fatalf("GetFile(random) returned unknown file %q", got)
		}
	}
}

func TestAmplitudeToVolumeBoundsAndMonotonic(t *testing.T) {
	if got := AmplitudeToVolume(0.0); got != -3.0 {
		t.Fatalf("AmplitudeToVolume(0)=%f, want -3.0", got)
	}
	if got := AmplitudeToVolume(10.0); got != 0.0 {
		t.Fatalf("AmplitudeToVolume(10)=%f, want 0.0", got)
	}

	prev := AmplitudeToVolume(0.05)
	for amp := 0.10; amp <= 0.80; amp += 0.05 {
		cur := AmplitudeToVolume(amp)
		if cur < prev-1e-9 {
			t.Fatalf("non-monotonic at amp=%f: cur=%f < prev=%f", amp, cur, prev)
		}
		prev = cur
	}

	for _, amp := range []float64{0.0, 0.05, 0.1, 0.5, 0.8, 1.0, 10.0} {
		v := AmplitudeToVolume(amp)
		if math.IsNaN(v) || math.IsInf(v, 0) {
			t.Fatalf("AmplitudeToVolume(%f) returned invalid value %f", amp, v)
		}
	}
}
