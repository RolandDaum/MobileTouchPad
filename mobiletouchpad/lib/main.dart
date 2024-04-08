import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

InternetAddress serverAddress = InternetAddress('0.0.0.0');
late int serverport;
late int clientport;
late RawDatagramSocket serverSocket;
bool _activeserverSocket = false;
late List<String> clientlist;
String dataversion = '1.0.1';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized

  await Hive.initFlutter();

  await Hive.openBox('appdata').then((box) {
    if (box.isEmpty) {
      // init data
      print('INIT - HIVE DATA');
      box.put('devicelist', []);
      box.put('serverport', 12345);
      box.put('clientport', 12346);
      box.put('dataversion', dataversion);
    } else if (box.get('dataversion') != dataversion) {
      // reinit data
      print('REINIT - HIVE DATA');
      box.put('devicelist', []);
      box.put('serverport', 12345);
      box.put('clientport', 12346);
      box.put('dataversion', dataversion);
    }
    // load data
    print('LOAD - HIVE DATA');
    serverport = box.get('serverport');
    clientport = box.get('clientport');
    List<String>? tmp_clientlist = box.get('clientlist');
    if (tmp_clientlist == null || tmp_clientlist.isEmpty) {
      clientlist = [];
    } else {
      clientlist = tmp_clientlist;
    }

  });

  await createServer();
  
  runApp(const MainApp());
}

Future<void> createServer() async {
  final NetworkInfo netInfo = NetworkInfo();
  String? ipaddress = await netInfo.getWifiIP();
  // print(ipaddress);
  if (ipaddress != null) {
    serverAddress = InternetAddress(ipaddress);
  } else {
    _activeserverSocket ? serverSocket.close() : {};
    return;
  }

  await RawDatagramSocket.bind(serverAddress, serverport)
    .then((socket) {
      serverSocket = socket;
      _activeserverSocket = true;
      print('UDP-Server gestartet: ${socket.address.address}:${socket.port}');
    }).catchError((e) {
      _activeserverSocket ? serverSocket.close() : {};
      print('Fehler beim Starten des Servers: $e');
    });
  
  _activeserverSocket ? serverSocket.listen((RawSocketEvent event) {
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
  Box HIVE_appdata = Hive.box('appdata');

  double deltaX = 0;
  double deltaY = 0;
  bool leftclick = false;
  bool rightclick = false;
  bool leftclickdown = false;
  bool vertscroll = false;
  double vertscrolldelta = 0;
  bool horzscroll = false;
  double horzscrolldelta = 0;
  DateTime doubletapdown = DateTime(0);
  late String data;

  double vertDragDelta = 0;

  bool showsettings = false;

  void sendData() {
    data = '{"x": $deltaX, "y": $deltaY, "leftclick": $leftclick, "rightclick": $rightclick, "leftclickdown": $leftclickdown, "vertscroll": $vertscroll, "vertscrolldelta": $vertscrolldelta, "horzscroll": $horzscroll, "horzscrolldelta": $horzscrolldelta}';
    // print('active udp server: $_activeserverSocket');
    if (_activeserverSocket) {
      clientlist.forEach((value) {
        serverSocket.send(data.codeUnits, InternetAddress(value), clientport);
      });
      leftclick = false;
      rightclick = false;
      deltaX = 0;
      deltaY = 0;
      horzscrolldelta = 0;
      vertscrolldelta = 0;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        // colorSchemeSeed: Colors.green[900],
        colorSchemeSeed: const Color(0xff31BAF2),
        useMaterial3: true,
        brightness: Brightness.dark
      ),

      home: Scaffold(
        extendBody: true,

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              showsettings = !showsettings;
            });
          },
          child: const Icon(
            Icons.settings_rounded
          ),
        ),

        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text(
                  serverAddress.address,
                ),
              ),
              GestureDetector(
                onDoubleTapDown: (details) {
                  // print('double tap down');
                  leftclickdown = true;
                  doubletapdown = DateTime.now();
                  sendData();
                },
                onDoubleTap: () {
                  // print('double tap');
                  leftclickdown = false;
                  if ((DateTime.now().millisecondsSinceEpoch - doubletapdown.millisecondsSinceEpoch) < 200 && !leftclickdown && !leftclick && !rightclick) {
                    leftclick = true;
                  } 
                  sendData();
                },

                onTap:() {
                  // print('tap');
                  leftclick = true;
                  leftclickdown = false;
                  sendData();
                },

                onLongPress: () {
                  // print('long press');
                  rightclick = true;
                  sendData();
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
                    case 4:
                      vertDragDelta += details.focalPointDelta.dy;
                      break;
                  }
                  sendData();
                },
                onScaleEnd: (details) {
                  leftclickdown = false;
                  horzscroll = false;
                  vertscroll = false;

                  if (vertDragDelta > 500) {
                    createServer().then((value) => setState(() {}));
                  }
                  vertDragDelta = 0;

                  sendData();
                },             
              ),
              SettingsOverlay()
            ],
          )
        ),
      ),
    );
  }

  Widget SettingsOverlay() {
    if (!showsettings) {
      return const SizedBox(height: 0, width: 0,);
    }
    return Center(
      child: TapRegion(
        onTapOutside: (event) {
          setState(() {
            showsettings = !showsettings;
          });
        },
        child: Card.filled(
          child: SizedBox(
            width: 300,
            height: 350,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
              children: [
                TextFormField(
                  onFieldSubmitted: (value) {
                    if (InternetAddress(value).type == InternetAddressType.IPv4) {
                      if (clientlist.contains(value)) {
                        return;
                      }
                      setState(() {
                        clientlist.add(value);
                        HIVE_appdata.put('clientlist', clientlist);
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    filled: true,
                    border: UnderlineInputBorder(),
                    labelText: 'IP address',
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: clientlist.length,
                    separatorBuilder: (context, index) {
                      return Divider(
                        color: Theme.of(context).dividerColor
                      );
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        leading: const Icon(
                          Icons.dns_rounded
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            setState(() {
                              clientlist.removeAt(index);
                              HIVE_appdata.put('clientlist', clientlist);
                            });
                          },
                          child: const Icon(
                            Icons.close_rounded
                          ),
                        ),
                        title: Text(clientlist[index]),
                      );
                    },
                    
                  ),
                )
              ],),
            )
          ),
        )
      )
    );
  }
}