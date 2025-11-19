import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  debugPaintSizeEnabled = false;
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyApp());
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? qr;
  bool camState = false;
  bool dirState = false;
  final QrCameraController _cameraController = QrCameraController();

  int dumbWayToThrottle = 0;
  ScannedBarcodesResponse? response;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plugin example app'),
        actions: <Widget>[
          IconButton(icon: new Icon(Icons.light), onPressed: _swapBackLightState),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 50),
          Expanded(
              child: Stack(
            children: [
              Positioned.fill(
                child: camState
                    ? QrCamera(
                        controller: _cameraController,
                        onScannedBarcodes: (codes) {
                          setState(() {
                            response = codes;
                          });
                        },
                        onError: (context, error) => Text(
                          error.toString(),
                          style: TextStyle(color: Colors.red),
                        ),
                        cameraDirection: dirState ? CameraDirection.FRONT : CameraDirection.BACK,
                        qrCodeCallback: (code) {
                          setState(() {
                            qr = code;
                          });
                        },
                      )
                    : new Center(child: new Text("Camera inactive")),
              ),
              if (response != null)
                Positioned.fill(
                  child: LayoutBuilder(builder: (context, cons) {
                    return CustomPaint(
                      painter: YourRect(response!, View.of(context).devicePixelRatio, cons),
                    );
                  }),
                ),
            ],
          )),
          Text("QRCODE: $qr"),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              heroTag: 'camera',
              child: Text(
                "on/off",
                textAlign: TextAlign.center,
              ),
              onPressed: () {
                setState(() {
                  camState = !camState;
                });
              }),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'capture',
            child: Icon(Icons.camera_alt),
            onPressed: _takePhoto,
          ),
        ],
      ),
    );
  }

  void _takePhoto() async {
    if (!camState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera is not active')),
      );
      return;
    }
    final imageBytes = await _cameraController.capturePhoto();

    if (imageBytes != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = p.join(directory.path, 'photo_${DateTime.now().millisecondsSinceEpoch}.png');

        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo saved to: $filePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving photo: $e')),
        );
      }
    }
  }

  _swapBackLightState() async {
    QrCamera.toggleFlash();
  }
}

class YourRect extends CustomPainter {
  YourRect(this.response, this.devicePixelRatio, this.constraints);

  final ScannedBarcodesResponse response;
  final double devicePixelRatio;
  final BoxConstraints constraints;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xff0056eb).withOpacity(0.3)
      ..strokeWidth = 1.0;

    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xfff0562b).withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (final barcode in response.barcodes) {
      if (barcode == null || barcode.rect == null) {
        continue;
      }

      final rect = barcode.rect!;

      // temp calc
      final oldLeft = rect.left / devicePixelRatio;
      final oldRight = rect.right / devicePixelRatio;
      final oldTop = rect.top / devicePixelRatio;
      final oldBottom = rect.bottom / devicePixelRatio;

      // the diff way
      // in dps
      final flutterScreenWidth = size.width;
      final flutterScreenHeight = size.height;

      // in px
      final nativeScreenWidth = rect.imageWidth;
      final nativeScreenHeight = rect.imageHeight;

      final horizCut = (nativeScreenWidth / devicePixelRatio - flutterScreenWidth) / 2;
      final vertCut = (nativeScreenHeight / devicePixelRatio - flutterScreenHeight) / 2;

      print('horizCut $horizCut vertCut $vertCut');

      // final newLeft = (rect.left / rect.imageWidth) * flutterScreenWidth;
      // final newRight = (rect.right / rect.imageWidth) * flutterScreenWidth;
      // final newTop = (rect.top / rect.imageHeight) * flutterScreenWidth;
      // final newBottom = (rect.bottom / rect.imageHeight) * flutterScreenWidth;

      final originalInwardLeft = (nativeScreenWidth / 2) - rect.left;
      final originalInwardRight = (nativeScreenWidth / 2) - rect.right;
      final originalInwardTop = (nativeScreenHeight / 2) - rect.top;
      final originalInwardBottom = (nativeScreenHeight / 2) - rect.bottom;

      final inwardLRatio = originalInwardLeft / rect.imageWidth;
      final inwardRRatio = originalInwardRight / rect.imageWidth;
      final inwardTRatio = originalInwardTop / rect.imageHeight;
      final inwardBRatio = originalInwardBottom / rect.imageHeight;

      final newLeft = (flutterScreenWidth / 2) - (flutterScreenWidth * inwardLRatio);
      final newRight = (flutterScreenWidth / 2) - (flutterScreenWidth * inwardRRatio);
      final newTop = (flutterScreenHeight / 2) - (flutterScreenWidth * inwardTRatio);
      final newBottom = (flutterScreenHeight / 2) - (flutterScreenWidth * inwardBRatio);

      print(
          'oldLeft $oldLeft flutterScreenWidth $flutterScreenWidth nativeScreenWidth $nativeScreenWidth newLeft $newLeft');

      canvas.drawRect(
        Rect.fromLTRB(
          rect.left / devicePixelRatio - horizCut,
          rect.top / devicePixelRatio - vertCut,
          rect.right / devicePixelRatio - horizCut,
          rect.bottom / devicePixelRatio - vertCut,
        ),
        paint,
      );

      // canvas.drawRect(
      //   Rect.fromLTRB(newLeft, newTop, newRight, newBottom),
      //   paint2,
      // );
    }
  }

  @override
  bool shouldRepaint(YourRect oldDelegate) {
    return false;
  }
}
