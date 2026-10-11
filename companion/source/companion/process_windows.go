//go:build windows

package main

import (
	"fmt"
	"strings"
	"syscall"
	"unsafe"
)

const th32csSnapProcess = 0x00000002

type processEntry32 struct {
	Size            uint32
	CntUsage        uint32
	ProcessID       uint32
	DefaultHeapID   uintptr
	ModuleID        uint32
	CntThreads      uint32
	ParentProcessID uint32
	PriClassBase    int32
	Flags           uint32
	ExeFile         [syscall.MAX_PATH]uint16
}

var (
	kernel32                     = syscall.NewLazyDLL("kernel32.dll")
	procCreateToolhelp32Snapshot = kernel32.NewProc("CreateToolhelp32Snapshot")
	procProcess32FirstW          = kernel32.NewProc("Process32FirstW")
	procProcess32NextW           = kernel32.NewProc("Process32NextW")
	procCloseHandle              = kernel32.NewProc("CloseHandle")
)

func processPIDMatchesName(pid int, name string) (bool, error) {
	snap, _, callErr := procCreateToolhelp32Snapshot.Call(th32csSnapProcess, 0)
	if snap == ^uintptr(0) {
		return false, fmt.Errorf("CreateToolhelp32Snapshot failed: %v", callErr)
	}
	defer procCloseHandle.Call(snap)

	var entry processEntry32
	entry.Size = uint32(unsafe.Sizeof(entry))
	ok, _, err := procProcess32FirstW.Call(snap, uintptr(unsafe.Pointer(&entry)))
	if ok == 0 {
		return false, fmt.Errorf("Process32FirstW failed: %v", err)
	}
	for {
		if int(entry.ProcessID) == pid {
			return strings.EqualFold(syscall.UTF16ToString(entry.ExeFile[:]), name), nil
		}
		ok, _, err = procProcess32NextW.Call(snap, uintptr(unsafe.Pointer(&entry)))
		if ok == 0 {
			if errno, isErrno := err.(syscall.Errno); isErrno && errno == syscall.ERROR_NO_MORE_FILES {
				return false, nil
			}
			if err == syscall.Errno(0) {
				return false, nil
			}
			return false, fmt.Errorf("Process32NextW failed: %v", err)
		}
	}
}
