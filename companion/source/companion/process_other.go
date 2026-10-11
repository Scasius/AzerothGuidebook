//go:build !windows

package main

import "runtime"

func processPIDMatchesName(pid int, name string) (bool, error) {
	// Preserve conservative lock behavior during non-Windows test/development
	// runs. The production binary uses native Windows process enumeration.
	return runtime.GOOS != "windows", nil
}
