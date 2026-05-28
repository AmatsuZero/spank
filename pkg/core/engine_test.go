package core

import (
	"testing"
	"time"
)

func TestDetectionEngineAcceptFlow(t *testing.T) {
	engine := NewDetectionEngine(0.10, 500*time.Millisecond)

	now := time.Unix(100, 0)
	first := DetectionEvent{Time: now, Amplitude: 0.20, Severity: "shock"}
	if !engine.Accept(first, now) {
		t.Fatal("first event should be accepted")
	}

	// Duplicate event timestamp should be ignored.
	if engine.Accept(first, now.Add(1*time.Second)) {
		t.Fatal("duplicate event should be rejected")
	}

	// New event inside cooldown window should be ignored.
	insideCooldown := DetectionEvent{Time: now.Add(10 * time.Millisecond), Amplitude: 0.30, Severity: "shock"}
	if engine.Accept(insideCooldown, now.Add(100*time.Millisecond)) {
		t.Fatal("event inside cooldown should be rejected")
	}

	// Event below threshold should be ignored.
	belowThreshold := DetectionEvent{Time: now.Add(2 * time.Second), Amplitude: 0.05, Severity: "light"}
	if engine.Accept(belowThreshold, now.Add(2*time.Second)) {
		t.Fatal("event below threshold should be rejected")
	}

	// New event after cooldown and above threshold should be accepted.
	afterCooldown := DetectionEvent{Time: now.Add(3 * time.Second), Amplitude: 0.25, Severity: "shock"}
	if !engine.Accept(afterCooldown, now.Add(3*time.Second)) {
		t.Fatal("event after cooldown should be accepted")
	}
}

func TestDetectionEngineUpdateConfig(t *testing.T) {
	engine := NewDetectionEngine(0.50, 2*time.Second)
	base := time.Unix(200, 0)

	first := DetectionEvent{Time: base, Amplitude: 0.60, Severity: "shock"}
	if !engine.Accept(first, base) {
		t.Fatal("first event should be accepted")
	}

	// Update to lower threshold and shorter cooldown.
	engine.UpdateConfig(0.10, 200*time.Millisecond)

	updated := DetectionEvent{Time: base.Add(300 * time.Millisecond), Amplitude: 0.20, Severity: "shock"}
	if !engine.Accept(updated, base.Add(300*time.Millisecond)) {
		t.Fatal("event should be accepted after config update")
	}
}
