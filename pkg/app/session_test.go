package app

import (
	"testing"
	"time"
)

type fakeTracker struct {
	recordCalls int
	lastRecord  time.Time
	lastScore   float64
}

func (f *fakeTracker) Record(now time.Time) (int, float64) {
	f.recordCalls++
	f.lastRecord = now
	return 7, 3.14
}

func (f *fakeTracker) GetFile(score float64) string {
	f.lastScore = score
	return "audio/sexy/07.mp3"
}

func TestSessionOnSlap(t *testing.T) {
	trk := &fakeTracker{}
	s := NewSession(trk)
	now := time.Unix(200, 123)

	res := s.OnSlap(now, 0.42, "CHOC_MOYEN")

	if trk.recordCalls != 1 {
		t.Fatalf("Record called %d times, want 1", trk.recordCalls)
	}
	if !trk.lastRecord.Equal(now) {
		t.Fatalf("Record called with %v, want %v", trk.lastRecord, now)
	}
	if trk.lastScore != 3.14 {
		t.Fatalf("GetFile called with score %f, want 3.14", trk.lastScore)
	}

	if res.SlapNumber != 7 {
		t.Fatalf("SlapNumber=%d, want 7", res.SlapNumber)
	}
	if res.Score != 3.14 {
		t.Fatalf("Score=%f, want 3.14", res.Score)
	}
	if res.File != "audio/sexy/07.mp3" {
		t.Fatalf("File=%q, want audio/sexy/07.mp3", res.File)
	}
	if res.Amplitude != 0.42 {
		t.Fatalf("Amplitude=%f, want 0.42", res.Amplitude)
	}
	if res.Severity != "CHOC_MOYEN" {
		t.Fatalf("Severity=%q, want CHOC_MOYEN", res.Severity)
	}
	if !res.Timestamp.Equal(now) {
		t.Fatalf("Timestamp=%v, want %v", res.Timestamp, now)
	}
}
