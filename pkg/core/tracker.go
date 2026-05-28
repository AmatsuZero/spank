package core

import (
	"math"
	"math/rand"
	"sync"
	"time"
)

type PlayMode int

const (
	ModeRandom PlayMode = iota
	ModeEscalation
)

const decayHalfLife = 30.0

type SlapTracker struct {
	mu       sync.Mutex
	score    float64
	lastTime time.Time
	total    int
	halfLife float64
	scale    float64
	mode     PlayMode
	files    []string
}

func NewSlapTracker(files []string, mode PlayMode, cooldown time.Duration) *SlapTracker {
	cooldownSec := cooldown.Seconds()
	scale := 1.0
	if len(files) > 0 {
		ssMax := 1.0 / (1.0 - math.Pow(0.5, cooldownSec/decayHalfLife))
		scale = (ssMax - 1) / math.Log(float64(len(files)+1))
	}

	return &SlapTracker{
		halfLife: decayHalfLife,
		scale:    scale,
		mode:     mode,
		files:    files,
	}
}

func (st *SlapTracker) Record(now time.Time) (int, float64) {
	st.mu.Lock()
	defer st.mu.Unlock()

	if !st.lastTime.IsZero() {
		elapsed := now.Sub(st.lastTime).Seconds()
		st.score *= math.Pow(0.5, elapsed/st.halfLife)
	}
	st.score += 1.0
	st.lastTime = now
	st.total++
	return st.total, st.score
}

func (st *SlapTracker) GetFile(score float64) string {
	if len(st.files) == 0 {
		return ""
	}

	if st.mode == ModeRandom {
		return st.files[rand.Intn(len(st.files))]
	}

	maxIdx := len(st.files) - 1
	if st.scale <= 0 || math.IsNaN(st.scale) || math.IsInf(st.scale, 0) {
		return st.files[maxIdx]
	}

	idx := minInt(int(float64(len(st.files))*(1.0-math.Exp(-(score-1)/st.scale))), maxIdx)
	if idx < 0 {
		idx = 0
	}
	return st.files[idx]
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}
