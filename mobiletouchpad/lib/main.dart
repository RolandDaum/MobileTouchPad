import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity/connectivity.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';


InternetAddress serverAddress = InternetAddress('0.0.0.0');
int port = 12345;
late RawDatagramSocket serverSocket;
bool _activeserverSocket = false;
Map<String, int> connectedClients = {"10.10.10.10": 12346};

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
  double deltaX = 0;
  double deltaY = 0;

  bool leftclick = false;
  bool rightclick = false;
  bool leftclickdown = false;

  bool vertscroll = false;
  double vertscrolldelta = 0;
  bool horzscroll = false;
  double horzscrolldelta = 0;

  // bool threeFvertscroll = false;
  // double threeFvertscrollDelta = 0;
  // bool threeFhorzscroll = false;
  // double threeFhorzscrollDelta = 0;

  DateTime doubletapdown = DateTime(0);

  late String data;

  //  NetworkInfo().getWifiIP().then((value) => print(value));
  

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

  void sendData() {
    
    data = '{"x": $deltaX, "y": $deltaY, "leftclick": $leftclick, "rightclick": $rightclick, "leftclickdown": $leftclickdown, "vertscroll": $vertscroll, "vertscrolldelta": $vertscrolldelta, "horzscroll": $horzscroll, "horzscrolldelta": $horzscrolldelta, "threeFvertscroll": $threeFvertscroll, "threeFvertscrollDelta": $threeFvertscrollDelta, "threeFhorzscroll": $threeFhorzscroll, "threeFhorzscrollDelta":$threeFhorzscrollDelta}';
    print(data);
    // print(data);

    if (_activeserverSocket) {
      connectedClients.forEach((key, value) {
        serverSocket.send(data.codeUnits, InternetAddress(key), value);
      });
      leftclick = false;
      rightclick = false;
      deltaX = 0;
      deltaY = 0;
      horzscrolldelta = 0;
      vertscrolldelta = 0;
      // threeFvertscrollDelta = 0;
      // threeFhorzscrollDelta = 0;
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
                // onPanDown: (details) {
                //   print('pan down');
                // },
                // onPanUpdate: (details) {
                //   deltaX = details.delta.dx;
                //   deltaY = details.delta.dy;
                //   sendData();
                // },
                // onPanEnd:(details) {
                //   print('pan end');
                //   leftclickdown = false;
                //   sendData();
                // },
                // onPanCancel: () {
                //   print('pan cancel');
                //   leftclickdown = false;
                //   sendData();
                // },

                onDoubleTapDown: (details) {
                  print('double tap down');
                  leftclickdown = true;
                  doubletapdown = DateTime.now();
                  sendData();
                },
                onDoubleTap: () {
                  print('double tap');
                  leftclickdown = false;
                  if ((DateTime.now().millisecondsSinceEpoch - doubletapdown.millisecondsSinceEpoch) < 200 && !leftclickdown && !leftclick && !rightclick) {
                    leftclick = true;
                  } 
                  sendData();
                },

                onTap:() {
                  print('tap');
                  leftclick = true;
                  leftclickdown = false;
                  sendData();
                },

                onLongPress: () {
                  print('long press');
                  rightclick = true;
                  sendData();
                },

                onScaleStart: (details) {
                  switch (details.pointerCount) {
                    case 2:
                      break;
                    case 3:
                      break;
                  }
                },
                onScaleUpdate: (details) {
                  switch (details.pointerCount) {
                    case 1:
                      deltaX = details.focalPointDelta.dx;
                      deltaY = details.focalPointDelta.dy;
                      break;
                    case 2:
                      if (horzscroll == false && vertscroll == false && details.focalPointDelta.dy.abs() < details.focalPointDelta.dx.abs()) {
                        horzscroll = true;
                        vertscroll = false;
                      } else if (horzscroll == false && vertscroll == false && details.focalPointDelta.dy.abs() > details.focalPointDelta.dx.abs()) {
                        vertscroll = true;
                        horzscroll = false;
                      }

                      if (vertscroll) {
                        vertscrolldelta = details.focalPointDelta.dy; 
                      } else if (horzscroll) {
                        horzscrolldelta = details.focalPointDelta.dx*-1;
                      }
                      break;
                    // case 3:
                    //   if (!threeFvertscroll && !threeFhorzscroll && details.focalPointDelta.dy.abs() > details.focalPointDelta.dx.abs()) {
                    //     threeFvertscroll = true;
                    //   } else if (!threeFvertscroll && !threeFhorzscroll && details.focalPointDelta.dy.abs() < details.focalPointDelta.dx.abs()) {
                    //     threeFhorzscroll = true;
                    //   }

                    //   if (threeFvertscroll) {
                    //     threeFvertscrollDelta = details.focalPointDelta.dy;
                    //     // print('3x vert $threeFvertscrollDelta');

                    //   } else if (threeFhorzscroll) {
                    //     threeFhorzscrollDelta = details.focalPointDelta.dx;
                    //     // print('3x horz $threeFhorzscrollDelta');

                    //   }
                    //   break;
                  }
                  sendData();
                },
                onScaleEnd: (details) {
                  leftclickdown = false;
                  horzscroll = false;
                  vertscroll = false;

                  // threeFvertscroll = false;
                  // threeFhorzscroll = false;

                  sendData();
                },             
              ),
            ],
          )
        ),
      ),
    );
  }
}