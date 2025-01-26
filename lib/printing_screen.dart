import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';


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


  // get usb devices
  _getDevicelist() async {
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();
    if(results.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No Printer Found')));
    }else {
      for (var device in results) {
        await _connect(
            int.parse(device['vendorId']), int.parse(device['productId']));
      }
    }
    if (mounted) {
      setState(() {
        devices = results;
      });
    }
  }

  // usb connection
  _connect(int vendorId, int productId) async {
    try {
      bool? result = await flutterUsbPrinter.connect(vendorId, productId);
      if (result == true) {
        setState(() {
          connected = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error connecting USB device: $e")));
      print("Error connecting USB device: $e");
    }
  }


   getUsbPrint() async {
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
        )
    );
    if (captureImage.isNotEmpty) {


      // ........printing............

      final img.Image image = img.decodeImage(captureImage)!;
      final img.Image resizedImage = img.copyResize(
          image, width: 480, maintainAspect: false);

      // bytes += generator.drawer(pin: PosDrawer.pin2);
      bytes += generator.imageRaster(resizedImage);
      bytes += generator.feed(2);
      bytes += generator.cut();
      // print(bytes);
      // print(image2);

      final Uint8List uint8ListBytes = Uint8List.fromList(bytes);
      print(uint8ListBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printed successfully ....')),
      );
  }


  //   if (captureImage.isNotEmpty) {
  //
  //     // ........saving image............
  //
  //
  //     final img.Image image = img.decodeImage(captureImage)!;
  //     img.Image thumbnail = img.copyResize(
  //         image, width: 480, maintainAspect: false);
  //
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
  }



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
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  // textInputAction: TextInputAction.done,
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
              ElevatedButton(
                onPressed: () async {
                  if (content.text.isNotEmpty) {
                   await getUsbPrint();

                   setState(() {
                     content.clear();
                   });

                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please Type Something')));
                  }

                },
                child: Text('Print'),)
            ],
          ),
        ),
      ),
    );
  }
}
