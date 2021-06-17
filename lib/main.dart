import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_speed_test/callbacks_enum.dart';
import 'package:internet_speed_test/internet_speed_test.dart';
import 'package:location/location.dart';
import 'package:sim_info/sim_info.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Opto Band',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Opto Band'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print("Error");
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.title,
                  style: TextStyle(color: Colors.blueGrey),
                ),
                backgroundColor: Colors.white,
                elevation: 0.0,
              ),
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(color: Colors.white),
                child: Center(child: AddData()
                    // Text(
                    //   widget.title,
                    //   style: TextStyle(color: Colors.blueGrey),
                    // ),
                    ),
              ));
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return Container(child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class AddData extends StatefulWidget {
  @override
  _AddDataState createState() => _AddDataState();
}

class _AddDataState extends State<AddData> {
  String textLog = "";
  bool progressIndicator = false;
  CollectionReference data = FirebaseFirestore.instance.collection('data');

  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> uploadData = {};

  @override
  void initState() {
    super.initState();
  }

  Future<LocationData> getLocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    _locationData = await location.getLocation();
    return _locationData;
  }

  Future<Map<String, dynamic>> getSimInfo() async {
    String allowsVOIP = await SimInfo.getAllowsVOIP;
    String carrierName = await SimInfo.getCarrierName;
    String isoCountryCode = await SimInfo.getIsoCountryCode;
    String mobileCountryCode = await SimInfo.getMobileCountryCode;
    String mobileNetworkCode = await SimInfo.getMobileNetworkCode;

    return <String, dynamic>{
      "allowsVOIP": allowsVOIP,
      "carrierName": carrierName,
      "isoCountryCode": isoCountryCode,
      "mobileCountryCode": mobileCountryCode,
      "mobileNetworkCode": mobileNetworkCode
    };
  }

  Future<Map<String, dynamic>> initPlatformState() async {
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return {};

    var now = new DateTime.now();
    deviceData.addAll({"date": now.toString()});
    return deviceData;
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'androidId': build.androidId,
      'systemFeatures': build.systemFeatures,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  Future<void> addData() async {
    // Call the user's CollectionReference to add a new user
    final internetSpeedTest = InternetSpeedTest();
    LocationData loc;
    setState(() {
      textLog = "Getting Sim Info";
      progressIndicator = true;
    });
    uploadData.addAll(await getSimInfo());
    setState(() {
      textLog = "Getting Device Info";
      progressIndicator = true;
    });
    uploadData.addAll(await initPlatformState());
    setState(() {
      textLog = "Getting Location";
      progressIndicator = true;
    });
    loc = await getLocation();

    if (loc != null)
      uploadData.addAll({
        "latitude": loc.latitude,
        "longitude": loc.longitude,
        "altitude": loc.altitude,
        "location-accuracy": loc.accuracy
      });

    setState(() {
      textLog = "Uploading Basic Data";
      progressIndicator = true;
    });
    return data.add(uploadData).then((value) {
      print("Data Added: $value");
      internetSpeedTest.startUploadTesting(
        onDone: (double transferRate, SpeedUnit unit) {
          print('the transfer rate $transferRate');
          String unitText = unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
          setState(() {
            textLog = "Uploading upload speed $transferRate $unitText";
            progressIndicator = false;
          });
          CollectionReference updata =
              FirebaseFirestore.instance.collection('data');
          updata
              .doc(value.id)
              .update({"uploadSpeed": transferRate.toString() + unitText}).then(
                  (value) => setState(() {
                        textLog = "Done";
                        progressIndicator = false;
                      }));

          internetSpeedTest.startDownloadTesting(
            onDone: (double transferRate, SpeedUnit unit) {
              String unitText = unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
              setState(() {
                textLog = "Uploading download speed $transferRate $unitText";
                progressIndicator = false;
              });
              print('the transfer rate $transferRate');
              CollectionReference dwdata =
                  FirebaseFirestore.instance.collection('data');
              dwdata.doc(value.id).update({
                "downloadSpeed": transferRate.toString() + unitText
              }).then((value) => setState(() {
                    textLog = "Done";
                    progressIndicator = false;
                  }));
            },
            onProgress: (double percent, double transferRate, SpeedUnit unit) {
              String unitText = unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
              setState(() {
                textLog =
                    "Calculating (${percent.toStringAsFixed(2)} %) Upload Speed $transferRate $unitText";
                progressIndicator = true;
              });
              // print('the transfer rate $transferRate, the percent $percent');
            },
            onError: (String errorMessage, String speedTestError) {
              // print(
              //     'the errorMessage $errorMessage, the speedTestError $speedTestError');
              setState(() {
                textLog = "$errorMessage";
                progressIndicator = false;
              });
            },
          );
        },
        onProgress: (double percent, double transferRate, SpeedUnit unit) {
          // print('the transfer rate $transferRate, the percent $percent');
          String unitText = unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
          setState(() {
            textLog =
                "Calculating (${percent.toStringAsFixed(2)} %) Upload Speed $transferRate $unitText";
            progressIndicator = true;
          });
        },
        onError: (String errorMessage, String speedTestError) {
          // print(
          //     'the errorMessage $errorMessage, the speedTestError $speedTestError');
          setState(() {
            textLog = "$errorMessage";
            progressIndicator = false;
          });
        },
      );
    }).catchError((error) {
      print("Failed to add data: $error");
      setState(() {
        textLog = "$error";
        progressIndicator = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create a CollectionReference called users that references the firestore collection

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ButtonTheme(
            minWidth: 200,
            height: 40.0,
            child: RaisedButton(
              color: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              onPressed: addData,
              child: Text(
                "Add Data",
                style: TextStyle(color: Colors.white),
              ),
            )),
        SizedBox(
          height: 20.0,
        ),
        Text("$textLog"),
        SizedBox(
          height: 20.0,
        ),
        Visibility(
          child: CircularProgressIndicator(),
          visible: progressIndicator,
        )
      ],
    );
  }
}
