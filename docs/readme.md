# Mobile Touchpad

![Project Banner](https://github.com/RolandDaum/MobileTouchPad/blob/main/docs/mbtp_banner.png?raw=true)

Transform your Android device into a versatile touchpad for your Windows PC or laptop.

## Features
- Mouse movement (single finger)
- Left click (one finger touch)
- Right click (long touch)
- Hold left click (double touch down and hold)
- Scroll horizontal/vertical (double finger movement horizontal/vertical)
- Restart UDP server in app with fast four finger vertical pull-down over the entire screen

## Content
- [Mobile Touchpad](#mobile-touchpad)
  - [Features](#features)
  - [Content](#content)
- [Setup](#setup)
  - [Requirements](#requirements)
  - [Installation](#installation)
- [Implementation](#implementation)
  - [Android App](#android-app)
  - [PC Driver](#pc-driver)

# Setup

## Requirements
- Android device
- Windows device
- WiFi connection for your Android device
- Both devices must be on the same network

## Installation
1. Install the latest APK from the [releases section](https://github.com/RolandDaum/MobileTouchPad/releases/tag/v1.0.0) on your mobile device.

2. Download the driver.go.exe from the latest [release section](https://github.com/RolandDaum/MobileTouchPad/releases/tag/v1.0.0) file and execute it.
2.1 Optionally, you can place the driver in the Windows autostart folder.
```
C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
```

3. In the app, click on the settings in the bottom right corner.
3.1 Add the local IPV4 Address to the list (e.g., '10.10.10.37').

4. If you have completed all the steps correctly, the mouse cursor on your PC should move according to your touch movements on the Android device screen.

# Implementation
## Android App
The Android App is made with Flutter, a cross-platform tool to develop Apps. Under the hood, it is using a basic GestureDetector widget, which tracks the touch movement and sends it to every device which is saved in the list. The data itself is formatted as JSON.
```
{
  "x": $deltaX, "y": $deltaY, 
  "leftclick": $leftclick, "rightclick": $rightclick, 
  "leftclickdown": $leftclickdown, 
  "vertscroll": $vertscroll, "vertscrolldelta": $vertscrolldelta, 
  "horzscroll": $horzscroll, "horzscrolldelta": $horzscrolldelta
}
```
For sending the data I'm using a UDP Connection. The server port (unused) is 12345 and the client port is 12346.
## PC Driver
The PC Driver is written in go, for its excellent performance and efficiency. With the help of ChatGPT I was able to get access to the native Windows API I think, which allows me to move the mouse and all the different implemented actions.
