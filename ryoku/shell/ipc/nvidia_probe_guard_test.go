package main

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

// Every shell script that asks nvidia-smi about the card must first read the
// driver's runtime_status and go on only when it is "active". A suspended card
// is woken by nvidia-smi (about 10 W on a hybrid laptop). A card stuck between
// states ("resuming", "suspending") makes nvidia-smi block in uninterruptible
// sleep, and because these probes repeat, each poll leaves one more process that
// nothing can kill. Skipping only on "suspended" let that happen.
var nvidiaProbeScripts = []string{
	"../quickshell/stage/services/ResourceUsage.qml",
	"../quickshell/shell/modules/bar/barstyles/qsbar/Theme.qml",
	"../../hub/quickshell/Singletons/LiveStats.qml",
	"../../hub/quickshell/pages/GpuPage.qml",
}

// The guard is spelled the same way in each script: the status read from
// /sys/bus/pci/drivers/nvidia/*/power/runtime_status compared against active.
var activeGuard = regexp.MustCompile(`\$s\\?"?\s*!=\s*active`)

// The old guard skipped the probe only on "suspended".
var suspendedOnlyGuard = regexp.MustCompile(`\$s\\?"?\s*==?\s*suspended`)

func TestNVIDIAProbesRunOnlyOnAnActiveCard(t *testing.T) {
	for _, path := range nvidiaProbeScripts {
		raw, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		text := string(raw)
		if suspendedOnlyGuard.MatchString(text) {
			t.Errorf("%s: skips nvidia-smi only on a suspended card; skip unless runtime_status is active", path)
		}
		probes := 0
		for i := strings.Index(text, "nvidia-smi --query"); i >= 0; {
			probes++
			// the guard sits in the same script, ahead of the call
			start := strings.LastIndex(text[:i], "runtime_status")
			if start < 0 || !activeGuard.MatchString(text[start:i]) {
				t.Errorf("%s: nvidia-smi query at byte %d is not behind an active-only runtime_status guard", path, i)
			}
			next := strings.Index(text[i+1:], "nvidia-smi --query")
			if next < 0 {
				break
			}
			i += next + 1
		}
		if probes == 0 {
			t.Errorf("%s: no nvidia-smi query found; update nvidiaProbeScripts", path)
		}
	}
}

// The GPU model needs no probe at all: the NVIDIA driver publishes it in
// /proc/driver/nvidia/gpus/*/information without touching the card.
func TestStageGPUModelReadsTheDriverBeforeProbing(t *testing.T) {
	raw, err := os.ReadFile("../quickshell/stage/services/ResourceUsage.qml")
	if err != nil {
		t.Fatal(err)
	}
	text := string(raw)
	proc := strings.Index(text, "/proc/driver/nvidia/gpus/")
	probe := strings.Index(text, "nvidia-smi --query-gpu=name")
	if proc < 0 {
		t.Fatal("GPU model detection does not read /proc/driver/nvidia/gpus/*/information")
	}
	if probe >= 0 && probe < proc {
		t.Error("GPU model detection asks nvidia-smi before reading the driver's information file")
	}
}
