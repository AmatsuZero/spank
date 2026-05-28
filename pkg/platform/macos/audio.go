//go:build darwin

package macos

import (
	"bytes"
	"embed"
	"fmt"
	"io"
	"os"
	"sync"
	"time"

	"github.com/gopxl/beep/v2"
	"github.com/gopxl/beep/v2/effects"
	"github.com/gopxl/beep/v2/mp3"
	"github.com/gopxl/beep/v2/speaker"
	"github.com/taigrr/spank/pkg/core"
)

type AudioSource struct {
	Custom bool
	FS     embed.FS
}

type PlaybackOptions struct {
	VolumeScaling bool
	SpeedRatio    float64
}

type AudioPlayer struct {
	mu          sync.Mutex
	initialized bool
}

func NewAudioPlayer() *AudioPlayer {
	return &AudioPlayer{}
}

func (p *AudioPlayer) Play(source AudioSource, path string, amplitude float64, opts PlaybackOptions) error {
	var streamer beep.StreamSeekCloser
	var format beep.Format

	if source.Custom {
		file, err := os.Open(path)
		if err != nil {
			return fmt.Errorf("open %s: %w", path, err)
		}
		defer file.Close()

		streamer, format, err = mp3.Decode(file)
		if err != nil {
			return fmt.Errorf("decode %s: %w", path, err)
		}
	} else {
		data, err := source.FS.ReadFile(path)
		if err != nil {
			return fmt.Errorf("read %s: %w", path, err)
		}
		streamer, format, err = mp3.Decode(io.NopCloser(bytes.NewReader(data)))
		if err != nil {
			return fmt.Errorf("decode %s: %w", path, err)
		}
	}
	defer streamer.Close()

	p.mu.Lock()
	if !p.initialized {
		speaker.Init(format.SampleRate, format.SampleRate.N(time.Second/10))
		p.initialized = true
	}
	p.mu.Unlock()

	var playSource beep.Streamer = streamer
	if opts.VolumeScaling {
		playSource = &effects.Volume{
			Streamer: streamer,
			Base:     2,
			Volume:   core.AmplitudeToVolume(amplitude),
			Silent:   false,
		}
	}

	if opts.SpeedRatio != 1.0 && opts.SpeedRatio > 0 {
		fakeRate := beep.SampleRate(int(float64(format.SampleRate) * opts.SpeedRatio))
		playSource = beep.Resample(4, fakeRate, format.SampleRate, playSource)
	}

	done := make(chan struct{})
	speaker.Play(beep.Seq(playSource, beep.Callback(func() {
		close(done)
	})))
	<-done
	return nil
}
