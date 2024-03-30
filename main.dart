import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ignore: deprecated_member_use
  final List<BluetoothDevice> _devicesList = [];
  List<BluetoothService> _servicesList = [];
  final Map<Guid, List<int>> _readValues = {};

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (!_devicesList.contains(result.device)) {
          setState(() {
            _devicesList.add(result.device);
          });
        }
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    if (!_devicesList.contains(device)) {
      return;
    }
    await device.connect();
    _discoverServices(device);
  }

  void _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    setState(() {
      _servicesList = services;
    });
  }

  void _readCharacteristic(BluetoothCharacteristic characteristic) async {
    List<int> value = await characteristic.read();
    setState(() {
      _readValues[characteristic.uuid] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter BLE Demo'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  // ignore: deprecated_member_use
                  title: Text(_devicesList[index].name),
                  // ignore: deprecated_member_use
                  subtitle: Text(_devicesList[index].id.toString()),
                  onTap: () {
                    _connectToDevice(_devicesList[index]);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _servicesList.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        _servicesList[index].uuid.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListView.builder(
                      itemCount:
                          _servicesList[index].characteristics.length,
                      itemBuilder: (BuildContext context, int index2) {
                        return ListTile(
                          title: Text(
                            _servicesList[index]
                                .characteristics[index2]
                                .uuid
                                .toString(),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.file_download),
                            onPressed: () {
                              _readCharacteristic(_servicesList[index]
                                  .characteristics[index2]);
                            },
                          ),
                        );
                      },
                      shrinkWrap: true,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
