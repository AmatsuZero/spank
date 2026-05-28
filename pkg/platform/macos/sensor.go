//go:build darwin

package macos

import (
	"errors"
	"fmt"

	"github.com/taigrr/apple-silicon-accelerometer/sensor"
	"github.com/taigrr/apple-silicon-accelerometer/shm"
)

// AccelSource wraps the macOS shared-memory accelerometer pipeline.
//
// Note: sensor.Run has no external stop signal in the upstream library and is
// expected to live for the process lifetime. This adapter is therefore intended
// for long-lived CLI/session usage, not repeated start/stop cycles.
type AccelSource struct {
	ring  *shm.RingBuffer
	errCh chan error
}

// NewAccelSource creates the shared-memory ring and starts sensor.Run.
//
// Startup is asynchronous: this function returns once the worker goroutine is
// launched. Any runtime/startup error is reported via Errors().
func NewAccelSource() (*AccelSource, error) {
	accelRing, err := shm.CreateRing(shm.NameAccel)
	if err != nil {
		return nil, fmt.Errorf("creating accel shm: %w", err)
	}

	errCh := make(chan error, 1)
	go func() {
		if err := sensor.Run(sensor.Config{
			AccelRing: accelRing,
			Restarts:  0,
		}); err != nil {
			errCh <- err
		}
	}()

	return &AccelSource{ring: accelRing, errCh: errCh}, nil
}

func (s *AccelSource) ReadNew(lastAccelTotal uint64) ([]shm.Sample, uint64) {
	return s.ring.ReadNew(lastAccelTotal, shm.AccelScale)
}

func (s *AccelSource) Errors() <-chan error {
	return s.errCh
}

func (s *AccelSource) Close() error {
	if s == nil || s.ring == nil {
		return nil
	}
	return errors.Join(s.ring.Close(), s.ring.Unlink())
}
