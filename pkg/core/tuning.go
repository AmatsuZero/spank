package core

import "time"

const (
	DefaultMinAmplitude       = 0.05
	DefaultCooldown           = 750 * time.Millisecond
	DefaultSensorPollInterval = 10 * time.Millisecond
	DefaultMaxSampleBatch     = 200
)

type RuntimeTuning struct {
	MinAmplitude float64
	Cooldown     time.Duration
	PollInterval time.Duration
	MaxBatch     int
}

func DefaultTuning() RuntimeTuning {
	return RuntimeTuning{
		MinAmplitude: DefaultMinAmplitude,
		Cooldown:     DefaultCooldown,
		PollInterval: DefaultSensorPollInterval,
		MaxBatch:     DefaultMaxSampleBatch,
	}
}

func ApplyFastOverlay(base RuntimeTuning) RuntimeTuning {
	base.PollInterval = 4 * time.Millisecond
	base.Cooldown = 350 * time.Millisecond
	if base.MinAmplitude > 0.18 {
		base.MinAmplitude = 0.18
	}
	if base.MaxBatch < 320 {
		base.MaxBatch = 320
	}
	return base
}
