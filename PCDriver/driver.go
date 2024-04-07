package main

import (
	"fmt"
	"math"
	"syscall"
	"time"

	"encoding/json"
	"net"

	"github.com/go-vgo/robotgo"
)

// Windows System Stuff
const (
	MOUSEEVENTF_WHEEL  = 0x0800
	MOUSEEVENTF_HWHEEL = 0x01000

	MOUSEEVENTF_LEFTDOWN   = 0x0002
	MOUSEEVENTF_LEFTUP     = 0x0004
	MOUSEEVENTF_RIGHTDOWN  = 0x0008
	MOUSEEVENTF_RIGHTUP    = 0x0010
	MOUSEEVENTF_MIDDLEDOWN = 0x0020
	MOUSEEVENTF_MIDDLEUP   = 0x0040
)

// Windows System stuff (GPT is kind a genius)
var (
	user32           = syscall.NewLazyDLL("user32.dll")
	procSetCursorPos = user32.NewProc("SetCursorPos")
	procMouseEvent   = user32.NewProc("mouse_event")
	// sendInput        = user32.NewProc("SendInput")
)

// Set coursor to fixed Position
func setCursorPos(x, y int) {
	procSetCursorPos.Call(uintptr(x), uintptr(y))
}

// Scroll Mousewheel with a delta value
func scrollMouseWheel(delta int, isHorizontal bool) {
	var flags uint32
	if isHorizontal {
		flags = MOUSEEVENTF_HWHEEL
	} else {
		flags = MOUSEEVENTF_WHEEL
	}

	// Simulated Mouse Scroll
	procMouseEvent.Call(
		uintptr(flags),
		0,
		0,
		uintptr(delta),
		0,
	)
}

// Click the
func clickMouseButton(buttonFlags uint32) {
	// Simulated Mouse Click
	procMouseEvent.Call(
		uintptr(buttonFlags),
		0,
		0,
		0,
		0,
	)
}

// JSON Data Structure
type MouseEvent struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`

	LeftClick     bool `json:"leftclick"`
	RightClick    bool `json:"rightclick"`
	LeftClickDown bool `json:"leftclickdown"`

	VertScroll      bool    `json:"vertscroll"`
	HorzScroll      bool    `json:"horzscroll"`
	VertScrollDelta float64 `json:"vertscrolldelta"`
	HorzScrollDelta float64 `json:"horzscrolldelta"`
}

func main() {

	// -- UDP SERVER STUFF -- //
	// UDP Server Address
	addr, err := net.ResolveUDPAddr("udp", ":12346")
	if err != nil {
		fmt.Println("Error while resolving the IP Address:", err)
		return
	}
	// Establish UDP - Connection
	conn, err := net.ListenUDP("udp", addr)
	if err != nil {
		fmt.Println("Fehler beim Erstellen der UDP-Verbindung:", err)
		return
	}
	defer conn.Close()
	fmt.Println("Started UDP Server...")
	// Puffer Size
	buffer := make([]byte, 1024)

	mousedown := false
	for {
		// Recive Data
		n, addr, err := conn.ReadFromUDP(buffer)
		if err != nil {
			fmt.Println("Error while recieving data:", err)
			continue
		}
		// Read Data (Json)
		var event MouseEvent
		if err := json.Unmarshal(buffer[:n], &event); err != nil {
			fmt.Println("Error while reading Json data:", err)
			continue
		}
		fmt.Println(addr.String())

		// Mouse Logic
		roundedX := math.Round(event.X * 2)
		roundedY := math.Round(event.Y * 2)
		if event.X == 0 {
			roundedX = 0
		}
		if event.Y == 0 {
			roundedY = 0
		}
		x, y := robotgo.GetMousePos()
		setCursorPos(int(roundedX)+x, int(roundedY)+y)

		if event.LeftClick {
			clickMouseButton(MOUSEEVENTF_LEFTDOWN)
			time.Sleep(time.Duration(100) * time.Millisecond)
			clickMouseButton(MOUSEEVENTF_LEFTUP)
		} else if event.RightClick {
			clickMouseButton(MOUSEEVENTF_RIGHTDOWN)
			time.Sleep(time.Duration(100) * time.Millisecond)
			clickMouseButton(MOUSEEVENTF_RIGHTUP)
		} else if event.LeftClickDown {
			if !mousedown {
				clickMouseButton(MOUSEEVENTF_LEFTDOWN)
				mousedown = true
			}
		} else if !event.LeftClickDown {
			clickMouseButton(MOUSEEVENTF_LEFTUP)
			mousedown = false
		}
		if event.HorzScroll {
			scrollMouseWheel(int(event.HorzScrollDelta)*2, true)
		} else if event.VertScroll {
			scrollMouseWheel(int(event.VertScrollDelta)*2, false)
		}
	}
}
