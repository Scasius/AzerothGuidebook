//go:build !windows

package main

func processesByName(name string) ([]uint32, error) {
	return nil, nil
}

func terminateProcessesByName(name string) error {
	return nil
}
