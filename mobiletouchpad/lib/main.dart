import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity/connectivity.dart';
import 'dart:io';


InternetAddress serverAddress = InternetAddress('0.0.0.0');
int port = 12345;
late RawDatagramSocket serverSocket;
bool _activeserverSocket = false;
Map<String, int> connectedClients = {};

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Transparente Benachrichtigungsleiste
    systemNavigationBarColor: Colors.transparent, // Transparente Navigationsleiste
  ));

  runApp(const MainApp());
}

void createServer() async {
  _activeserverSocket ? serverSocket.close() : {};

  await RawDatagramSocket.bind(serverAddress, port)
    .then((socket) {
      serverSocket = socket;
      _activeserverSocket = true;
      print('UDP-Server gestartet: ${socket.address.address}:${socket.port}');
    }).catchError((e) {
      _activeserverSocket ? serverSocket.close() : {};
      print('Fehler beim Starten des Servers: $e');
    });
  
  _activeserverSocket ? serverSocket.listen((RawSocketEvent event) {

    // if a device sends a message its will be added to the list of connected devices
    if (event == RawSocketEvent.read) {
      Datagram? datagram = serverSocket.receive();
      if (datagram != null) {
        if (!connectedClients.containsKey((datagram.address.address))) {
          connectedClients[datagram.address.address] = datagram.port;
        }
      }
    }
    
    if (event == RawSocketEvent.closed) {
      print('UDP-Server geschlossen');
      _activeserverSocket = false;
    }
  }) : {};
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  late String _localipAddress;
  Future<void> _checkLocalIPAddress() async {
    
    if (_connectionStatus != 'ConnectivityResult.wifi') {
      _localipAddress = 'No wifi connection';
      _activeserverSocket ? serverSocket.close() : {};
      setState(() {});
      return;
    }
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        // Überprüfe, ob es sich um eine IPv4-Adresse handelt und nicht um eine Loopback-Adresse
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          _localipAddress = addr.address;
          _activeserverSocket ? serverSocket.close() : {};
          serverAddress = InternetAddress(_localipAddress);
          setState(() {});
          createServer();
          return;
        }
      }
    }
    _localipAddress = 'No IP-Address has been found';
    _activeserverSocket ? serverSocket.close() : {};
    setState(() {});
    return;
  }

  String _connectionStatus = 'Unknown';
  late Connectivity _connectivity;
  Future<void> _checkConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    setState(() {
      _connectionStatus = connectivityResult.toString();
    });
  }

  void sendData(String data) {
    if (_activeserverSocket) {
      connectedClients.forEach((key, value) {
        serverSocket.send(data.codeUnits, InternetAddress(key), value);
      });
    }
  }

  @override
  void initState() {

    _connectivity = Connectivity();
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result.toString();
        _checkLocalIPAddress();
      });
    });
    _checkConnection();
    _checkLocalIPAddress();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool holdleftclick = false;

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      home: Scaffold(
        extendBody: true,

        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blueGrey[900]
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                  _activeserverSocket ? _localipAddress + ':' + serverSocket.port.toString() : _localipAddress,
                  style: const TextStyle(
                    color: Colors.white54
                  ),
                ),
              ),
              GestureDetector(
                onScaleStart: (details) {
                  // print('pointer count ' + details.pointerCount.toString());
                  switch (details.pointerCount) {
                    case 2:
                      // print('rightclick');
                      break;
                    case 1:
                      break;
                  }
                },
                onScaleUpdate: (details) {
                  switch (details.pointerCount) {
                    case 2:
                      // print('two finger scale/scroll ' + details.scale.toString());
                      break;
                    case 1:
                      // print('one finger delta ' + details.focalPointDelta.toString());
                      double xdelta = details.focalPointDelta.dx;
                      double ydelta = details.focalPointDelta.dy;

                      sendData('{"x": "$xdelta", "y": "$ydelta", "leftclick": false, "rightclick": false, "holdleftclick": $holdleftclick}');
                      break;
                  }
                },
                onTap: () {
                  sendData('{"x": "0", "y": "0", "leftclick": true, "rightclick": false, "holdleftclick": $holdleftclick}');
                },
                // onDoubleTap: () {
                //   holdleftclick = true;
                //   sendData('{"x": "0", "y": "0", "leftclick": true, "rightclick": false, "holdleftclick": $holdleftclick}');
                // },
                // onDoubleTapCancel: () {
                //   holdleftclick = false;
                //   sendData('{"x": "0", "y": "0", "leftclick": true, "rightclick": false, "holdleftclick": $holdleftclick}');
                // },
                onLongPress: () {
                  sendData('{"x": "0", "y": "0", "leftclick": false, "rightclick": true, "holdleftclick": $holdleftclick}');
                },
              ),
            ],
          )
        ),
      ),
    );;
  }
}




