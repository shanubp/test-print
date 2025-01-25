import 'dart:io';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

double fontSize = 0;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    _getDevicelist();
    // TODO: implement initState
    super.initState();
  }

  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  bool connected = false;
  List<Map<String, dynamic>> devices = [];

  ScreenshotController screenController = ScreenshotController();
  TextEditingController content = TextEditingController();

  _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();
    for (dynamic device in results) {
      _connect(int.parse(device['vendorId']), int.parse(device['productId']));
    }
    if (mounted) {
      setState(() {
        devices = results;
      });
    }
  }

  _connect(int vendorId, int productId) async {
    bool? returned;
    try {
      returned = await flutterUsbPrinter.connect(vendorId, productId);
    } on PlatformException {}
    if (returned!) {
      setState(() {
        connected = true;
      });
    }
  }

  getPrint() async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    final captureImage = await screenController.captureFromLongWidget(
        Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(content.text, style:
              TextStyle(
                color: Colors.black,
                fontSize: 30,
              ),
              )
            ],
          ),
        ), delay: Duration(microseconds: 500)
    );
    if (captureImage.isNotEmpty) {
      final img.Image image2 = img.decodeImage(captureImage)!;
      img.Image thumbnail = img.copyResize(
          image2, width: 480, maintainAspect: false);

      bytes += generator.drawer(pin: PosDrawer.pin2);
      bytes += generator.imageRaster(thumbnail);
      bytes += generator.feed(2);
      bytes += generator.cut();
      // print(bytes);
      // print(image2);

    }
  }

  //   if (captureImage.isNotEmpty) {
  //     // Decode the image
  //     final img.Image image = img.decodeImage(captureImage)!;
  //
  //     // Resize the image if necessary
  //     img.Image thumbnail = img.copyResize(
  //         image, width: 480, maintainAspect: false);
  //
  //     // Convert image to Uint8List
  //     Uint8List thumbnailBytes = Uint8List.fromList(img.encodePng(thumbnail));
  //
  //     // Request storage permission
  //     final status = await Permission.storage.request();
  //     if (status.isGranted) {
  //       // Save to the public Downloads directory
  //       String downloadPath = '/storage/emulated/0/Download'; // Path to Downloads folder
  //       String filePath = '$downloadPath/captured_image_${DateTime
  //           .now()
  //           .millisecondsSinceEpoch}.png';
  //
  //       final File file = File(filePath);
  //       await file.writeAsBytes(thumbnailBytes);
  //
  //       print('Image saved to $filePath');
  //       // Open the folder
  //       openFolder(downloadPath); // Open the folder
  //       return filePath; // Return the file path
  //     } else {
  //       print('Permission denied to access storage.');
  //       return null; // Return null if permission is denied
  //     }
  //   }
  //   return null;
  // }
  //
  // void openFolder(String folderPath) async {
  //   final url = 'file://$folderPath';
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     print("Cannot open folder.");
  //   }
  // }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: content,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height*0.05,
              ),
              TextButton(
                onPressed: () {
                  getPrint();
                },
                child: Text('Submit'),)
            ],
          ),
        ),
      ),
    );
  }
}
