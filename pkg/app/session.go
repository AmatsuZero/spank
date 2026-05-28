package app

import "time"

type Tracker interface {
	Record(now time.Time) (int, float64)
	GetFile(score float64) string
}

type SlapResult struct {
	Timestamp  time.Time
	SlapNumber int
	Score      float64
	Amplitude  float64
	Severity   string
	File       string
}

type Session struct {
	tracker Tracker
}

func NewSession(tracker Tracker) *Session {
	return &Session{tracker: tracker}
}

func (s *Session) OnSlap(now time.Time, amplitude float64, severity string) SlapResult {
	num, score := s.tracker.Record(now)
	file := s.tracker.GetFile(score)
	return SlapResult{
		Timestamp:  now,
		SlapNumber: num,
		Score:      score,
		Amplitude:  amplitude,
		Severity:   severity,
		File:       file,
	}
}
