import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/scanned_barcode.g.dart',
  dartOptions: DartOptions(),
  // kotlinOut:
  // 'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/ScannedBarcode.g.kt',
  // kotlinOptions: KotlinOptions(),
  javaOut:
      'android/src/main/java/com/github/rmtmckenzie/qrmobilevision/ScannedBarcodePigeon.java',
  javaOptions: JavaOptions(package: 'com.github.rmtmckenzie.qrmobilevision'),
  swiftOut: 'ios/Classes/ScannedBarcodePigeon.g.swift',
  swiftOptions: SwiftOptions(),
  // objcHeaderOut: 'macos/Runner/scanned_barcode.g.h',
  // objcSourceOut: 'macos/Runner/scanned_barcode.g.m',
  // Set this to a unique prefix for your plugin or application, per Objective-C naming conventions.
  // objcOptions: ObjcOptions(prefix: 'PGN'),
  dartPackageName: 'qr_mobile_vision',
))
class ScannedBarcodesResponse {
  ScannedBarcodesResponse(this.barcodes);

  final List<ScannedBarcode?> barcodes;
}

class ScannedBarcode {
  final String barcode;

  /// https://developers.google.com/ml-kit/reference/swift/mlkitbarcodescanning/api/reference/Classes/Barcode
  final BarcodeRect? rect;

  ScannedBarcode(this.barcode, this.rect);
}

class BarcodeRect {
  BarcodeRect(this.left, this.top, this.right, this.bottom, this.imageWidth, this.imageHeight);

  final int imageWidth;
  final int imageHeight;

  final int left;
  final int top;
  final int right;
  final int bottom;
}

@FlutterApi()
abstract class QrMobileVisionApi {
  void onScannedBarcode(ScannedBarcodesResponse barcode);
}
