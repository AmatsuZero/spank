package core

import "time"

type DetectionEvent struct {
	Time      time.Time
	Amplitude float64
	Severity  string
}

type DetectionEngine struct {
	minAmplitude float64
	cooldown     time.Duration
	lastEvent    time.Time
	lastYell     time.Time
}

func NewDetectionEngine(minAmplitude float64, cooldown time.Duration) *DetectionEngine {
	return &DetectionEngine{
		minAmplitude: minAmplitude,
		cooldown:     cooldown,
	}
}

func (e *DetectionEngine) UpdateConfig(minAmplitude float64, cooldown time.Duration) {
	e.minAmplitude = minAmplitude
	e.cooldown = cooldown
}

func (e *DetectionEngine) Accept(ev DetectionEvent, now time.Time) bool {
	if ev.Time.Equal(e.lastEvent) {
		return false
	}
	e.lastEvent = ev.Time

	if !e.lastYell.IsZero() && now.Sub(e.lastYell) <= e.cooldown {
		return false
	}
	if ev.Amplitude < e.minAmplitude {
		return false
	}

	e.lastYell = now
	return true
}
