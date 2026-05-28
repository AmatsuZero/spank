package mobile

import (
	"sync"
	"time"

	"github.com/AmatsuZero/spank/pkg/core"
)

// DefaultMinAmplitude returns the default detection threshold.
func DefaultMinAmplitude() float64 {
	return core.DefaultMinAmplitude
}

// AmplitudeToVolume maps amplitude to a volume factor in range [-3.0, 0.0].
func AmplitudeToVolume(amplitude float64) float64 {
	return core.AmplitudeToVolume(amplitude)
}

// Gate is a minimal mobile-facing detection gate wrapper.
type Gate struct {
	mu    sync.Mutex
	inner *core.DetectionEngine
}

// NewGate creates a detection gate.
func NewGate(minAmplitude float64, cooldownMs int64) *Gate {
	return &Gate{inner: core.NewDetectionEngine(minAmplitude, time.Duration(cooldownMs)*time.Millisecond)}
}

// Update updates gate configuration at runtime.
func (g *Gate) Update(minAmplitude float64, cooldownMs int64) {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.inner.UpdateConfig(minAmplitude, time.Duration(cooldownMs)*time.Millisecond)
}

// Accept evaluates one detection event.
// eventUnixNanos and nowUnixNanos should both be Unix nanoseconds.
func (g *Gate) Accept(eventUnixNanos int64, amplitude float64, severity string, nowUnixNanos int64) bool {
	g.mu.Lock()
	defer g.mu.Unlock()
	ev := core.DetectionEvent{
		Time:      time.Unix(0, eventUnixNanos),
		Amplitude: amplitude,
		Severity:  severity,
	}
	return g.inner.Accept(ev, time.Unix(0, nowUnixNanos))
}
