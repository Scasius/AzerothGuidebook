//go:build windows

package main

import (
	"fmt"
	"strings"
	"syscall"
	"unsafe"
)

const (
	th32csSnapProcess = 0x00000002
	processTerminate  = 0x0001
	synchronize       = 0x00100000
	waitObject0       = 0x00000000
	waitTimeout       = 0x00000102
	infinite          = 0xFFFFFFFF
)

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
	procOpenProcess              = kernel32.NewProc("OpenProcess")
	procTerminateProcess         = kernel32.NewProc("TerminateProcess")
	procWaitForSingleObject      = kernel32.NewProc("WaitForSingleObject")
	procCloseHandle              = kernel32.NewProc("CloseHandle")
)

func processesByName(name string) ([]uint32, error) {
	snap, _, callErr := procCreateToolhelp32Snapshot.Call(th32csSnapProcess, 0)
	if snap == ^uintptr(0) {
		return nil, fmt.Errorf("CreateToolhelp32Snapshot failed: %v", callErr)
	}
	defer procCloseHandle.Call(snap)

	var entry processEntry32
	entry.Size = uint32(unsafe.Sizeof(entry))
	ok, _, err := procProcess32FirstW.Call(snap, uintptr(unsafe.Pointer(&entry)))
	if ok == 0 {
		return nil, fmt.Errorf("Process32FirstW failed: %v", err)
	}

	var pids []uint32
	for {
		exe := syscall.UTF16ToString(entry.ExeFile[:])
		if strings.EqualFold(exe, name) {
			pids = append(pids, entry.ProcessID)
		}
		ok, _, err = procProcess32NextW.Call(snap, uintptr(unsafe.Pointer(&entry)))
		if ok == 0 {
			if errno, isErrno := err.(syscall.Errno); isErrno && errno == syscall.ERROR_NO_MORE_FILES {
				break
			}
			if err == syscall.Errno(0) {
				break
			}
			return nil, fmt.Errorf("Process32NextW failed: %v", err)
		}
	}
	return pids, nil
}

func terminateProcessesByName(name string) error {
	pids, err := processesByName(name)
	if err != nil {
		return err
	}
	for _, pid := range pids {
		handle, _, openErr := procOpenProcess.Call(processTerminate|synchronize, 0, uintptr(pid))
		if handle == 0 {
			return fmt.Errorf("OpenProcess(%d) failed: %v", pid, openErr)
		}
		terminated, _, termErr := procTerminateProcess.Call(handle, 0)
		if terminated == 0 {
			procCloseHandle.Call(handle)
			return fmt.Errorf("TerminateProcess(%d) failed: %v", pid, termErr)
		}
		waitResult, _, waitErr := procWaitForSingleObject.Call(handle, 5000)
		procCloseHandle.Call(handle)
		if waitResult != waitObject0 && waitResult != waitTimeout {
			return fmt.Errorf("WaitForSingleObject(%d) failed: result=%d err=%v", pid, waitResult, waitErr)
		}
	}
	return nil
}
