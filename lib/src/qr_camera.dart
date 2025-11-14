import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';
import 'package:qr_mobile_vision/src/preview.dart' as pr;
import 'package:qr_mobile_vision/src/preview_details.dart';
import 'package:qr_mobile_vision/src/scanned_barcode.g.dart';

final WidgetBuilder _defaultNotStartedBuilder = (context) => Text("Camera Loading ...");
final WidgetBuilder _defaultOffscreenBuilder = (context) => Text("Camera Paused.");
final ErrorCallback _defaultOnError = (BuildContext context, Object? error) {
  print("Error reading from camera: $error");
  return Text("Error reading from camera...");
};

typedef Widget ErrorCallback(BuildContext context, Object? error);

class QrCameraController {
  QrCameraState? _state;

  void attach(QrCameraState state) {
    _state = state;
  }

  void detach() {
    _state = null;
  }

  Future<void> restart() {
    return _state?.restart() ?? Future.value();
  }

  Future<void> stop() {
    return _state?.stop() ?? Future.value();
  }
}

class QrCamera extends StatefulWidget {
  QrCamera({
    Key? key,
    required this.qrCodeCallback,
    required this.onScannedBarcodes,
    this.child,
    this.fit = BoxFit.cover,
    WidgetBuilder? notStartedBuilder,
    WidgetBuilder? offscreenBuilder,
    ErrorCallback? onError,
    this.cameraDirection = CameraDirection.BACK,
    this.formats,
    this.controller,
  })  : notStartedBuilder = notStartedBuilder ?? _defaultNotStartedBuilder,
        offscreenBuilder = offscreenBuilder ?? notStartedBuilder ?? _defaultOffscreenBuilder,
        onError = onError ?? _defaultOnError,
        super(key: key);

  final BoxFit fit;
  final ValueChanged<String?> qrCodeCallback;
  final Function(ScannedBarcodesResponse) onScannedBarcodes;
  final Widget? child;
  final WidgetBuilder notStartedBuilder;
  final WidgetBuilder offscreenBuilder;
  final ErrorCallback onError;
  final List<BarcodeFormats>? formats;
  final CameraDirection cameraDirection;
  final QrCameraController? controller;

  static toggleFlash() {
    QrMobileVision.toggleFlash();
  }

  @override
  QrCameraState createState() => QrCameraState();
}

class QrCameraState extends State<QrCamera> with WidgetsBindingObserver {
  // needed for flutter < 3.0 to still be supported
  T? _ambiguate<T>(T? value) => value;

  @override
  void initState() {
    super.initState();
    _ambiguate(WidgetsBinding.instance)!.addObserver(this);
    widget.controller?.attach(this);
  }

  @override
  void reassemble() {
    restart();
    super.reassemble();
  }

  @override
  dispose() {
    widget.controller?.detach();
    _ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(QrCamera oldWidget) {
    if (oldWidget.cameraDirection != widget.cameraDirection) {
      QrMobileVision.stop();
      setState(() {
        _asyncInitOnce = null;
      });
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => onScreen = true);
    } else {
      if (_asyncInitOnce != null && onScreen) {
        QrMobileVision.stop();
      }
      setState(() {
        onScreen = false;
        _asyncInitOnce = null;
      });
    }
  }

  bool onScreen = true;
  Future<PreviewDetails>? _asyncInitOnce;

  Future<PreviewDetails> _asyncInit(num width, num height) async {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return await QrMobileVision.start(
      width: (devicePixelRatio * width.toInt()).ceil(),
      height: (devicePixelRatio * height.toInt()).ceil(),
      qrCodeHandler: widget.qrCodeCallback,
      onScannedBarcodes: widget.onScannedBarcodes,
      formats: widget.formats,
      cameraDirection: widget.cameraDirection,
    );
  }

  /// This method can be used to restart scanning
  ///  the event that it was paused.
  Future<void> restart() async {
    await QrMobileVision.stop();
    if (mounted) {
      setState(() {
        _asyncInitOnce = null;
      });
    }
  }

  /// This method can be used to manually stop the
  /// camera.
  Future<void> stop() async {
    await QrMobileVision.stop();
  }

  @override
  deactivate() {
    super.deactivate();
    QrMobileVision.stop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      if (_asyncInitOnce == null && onScreen) {
        _asyncInitOnce = _asyncInit(constraints.maxWidth, constraints.maxHeight);
      } else if (!onScreen) {
        return widget.offscreenBuilder(context);
      }

      return FutureBuilder(
        future: _asyncInitOnce,
        builder: (BuildContext context, AsyncSnapshot<PreviewDetails> details) {
          switch (details.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return widget.notStartedBuilder(context);
            case ConnectionState.done:
              if (details.hasError) {
                debugPrint(details.error.toString());
                return widget.onError(context, details.error);
              }
              Widget preview = SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: pr.Preview(
                  previewDetails: details.data!,
                  targetWidth: constraints.maxWidth,
                  targetHeight: constraints.maxHeight,
                  fit: widget.fit,
                ),
              );

              if (widget.child != null) {
                return Stack(
                  children: [
                    preview,
                    widget.child!,
                  ],
                );
              }
              return preview;

            default:
              throw AssertionError("${details.connectionState} not supported.");
          }
        },
      );
    });
  }
}
