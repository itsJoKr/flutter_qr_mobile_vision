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
  final int? boundLeft;
  final int? boundTop;
  final int? boundRight;
  final int? boundBottom;

  ScannedBarcode(this.barcode, this.boundLeft, this.boundTop, this.boundBottom,
      this.boundRight);
}

@FlutterApi()
abstract class QrMobileVisionApi {
  void onScannedBarcode(ScannedBarcodesResponse barcode);
}
