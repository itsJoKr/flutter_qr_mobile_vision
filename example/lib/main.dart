import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_mobile_vision/qr_camera.dart';

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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Back"),
              Switch(
                  value: dirState,
                  onChanged: (val) => setState(() => dirState = val)),
              Text("Front"),
            ],
          ),
          Expanded(
              child: Stack(
            children: [
              Positioned.fill(
                child: camState
                    ? QrCamera(
                        onScannedBarcodes: (codes) {
                          setState(() {
                            response = codes;
                          });
                        },
                        onError: (context, error) => Text(
                          error.toString(),
                          style: TextStyle(color: Colors.red),
                        ),
                        cameraDirection: dirState
                            ? CameraDirection.FRONT
                            : CameraDirection.BACK,
                        qrCodeCallback: (code) {
                          setState(() {
                            qr = code;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Colors.orange,
                              width: 10.0,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      )
                    : Center(child: Text("Camera inactive")),
              ),
              if (response != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter:
                        YourRect(response!, View.of(context).devicePixelRatio),
                  ),
                ),
            ],
          )),
          Text("QRCODE: $qr"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Text(
            "on/off",
            textAlign: TextAlign.center,
          ),
          onPressed: () {
            setState(() {
              camState = !camState;
            });
          }),
    );
  }
}

class YourRect extends CustomPainter {
  YourRect(this.response, this.devicePixelRatio);

  final ScannedBarcodesResponse response;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xff0056eb).withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (final barcode in response.barcodes) {
      if (barcode == null || barcode.rect == null) {
        continue;
      }

      final rect = barcode.rect!;

      canvas.drawRect(
        Rect.fromLTRB(
          rect.left / devicePixelRatio,
          rect.top / devicePixelRatio,
          rect.right / devicePixelRatio,
          rect.bottom / devicePixelRatio,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(YourRect oldDelegate) {
    return false;
  }
}
