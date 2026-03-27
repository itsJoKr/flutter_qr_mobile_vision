import Foundation
import AVFoundation
import Vision
import os.log


/// Maps Dart-side format strings to Vision Framework symbologies
class VisionSymbologyMapper {
    static func symbologies(from formatStrings: [String]) -> [VNBarcodeSymbology] {
        var symbologies: [VNBarcodeSymbology] = []
        for format in formatStrings {
            switch format {
            case "ALL_FORMATS":
                // Return empty to indicate "all supported"
                return []
            case "AZTEC":
                symbologies.append(.aztec)
            case "CODE_128":
                symbologies.append(.code128)
            case "CODE_39":
                symbologies.append(.code39)
            case "CODE_93":
                symbologies.append(.code93)
            case "CODABAR":
                symbologies.append(.codabar)
            case "DATA_MATRIX":
                symbologies.append(.dataMatrix)
            case "EAN_13":
                symbologies.append(.ean13)
            case "EAN_8":
                symbologies.append(.ean8)
            case "ITF":
                symbologies.append(.itf14)
            case "PDF417":
                symbologies.append(.pdf417)
            case "QR_CODE":
                symbologies.append(.qr)
            case "UPC_A":
                symbologies.append(.upce)
            case "UPC_E":
                symbologies.append(.upce)
            default:
                break
            }
        }
        return symbologies
    }
}


class OrientationHandler {

    var lastKnownOrientation: UIDeviceOrientation!

    init() {
        setLastOrientation(UIDevice.current.orientation, defaultOrientation: .portrait)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil, using: orientationDidChange(_:))
    }

    func setLastOrientation(_ deviceOrientation: UIDeviceOrientation, defaultOrientation: UIDeviceOrientation?) {

        // set last device orientation but only if it is recognized
        switch deviceOrientation {
        case .unknown, .faceUp, .faceDown:
            lastKnownOrientation = defaultOrientation ?? lastKnownOrientation
            break
        default:
            lastKnownOrientation = deviceOrientation
        }
    }

    func orientationDidChange(_ notification: Notification) {
        let deviceOrientation = UIDevice.current.orientation

        let prevOrientation = lastKnownOrientation
        setLastOrientation(deviceOrientation, defaultOrientation: nil)

        if prevOrientation != lastKnownOrientation {
            //TODO: notify of orientation change??? (but mostly why bother...)
        }
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

protocol QrReaderResponses {
    func surfaceReceived(buffer: CMSampleBuffer)
    func qrReceived(code: String)
}

enum QrReaderError: Error {
    case noCamera
}

enum QrCameraDirection {
    case front
    case back
}

extension QrCameraDirection {
    var cameraPosition: AVCaptureDevice.Position {
        switch self {
        case .front:
            return AVCaptureDevice.Position.front
        case .back:
            return AVCaptureDevice.Position.back
        }
    }
}



class QrReader: NSObject {
    let targetWidth: Int
    let targetHeight: Int
    let textureRegistry: FlutterTextureRegistry
    let isProcessing = Atomic<Bool>(false)
    let cameraPosition: AVCaptureDevice.Position

    var captureDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var previewSize: CMVideoDimensions!
    var textureId: Int64!
    var pixelBuffer: CVPixelBuffer?
    let barcodeRequest: VNDetectBarcodesRequest
    let qrCallback: (_:String) -> Void
    let barcodeResponseCallback: (_:ScannedBarcodesResponse) -> Void



    init(targetWidth: Int, targetHeight: Int, direction: QrCameraDirection, textureRegistry: FlutterTextureRegistry, symbologies: [VNBarcodeSymbology], qrCallback: @escaping (_:String) -> Void, barcodeResponseCallback: @escaping (_:ScannedBarcodesResponse) -> Void) throws {
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.textureRegistry = textureRegistry
        self.qrCallback = qrCallback
        self.barcodeResponseCallback = barcodeResponseCallback
        self.cameraPosition = direction.cameraPosition

        // Set up Vision Framework barcode detection request
        self.barcodeRequest = VNDetectBarcodesRequest()
        if !symbologies.isEmpty {
            self.barcodeRequest.symbologies = symbologies
        }

        // Limit detection to a horizontal band in the center of the frame.
        // This matches the iOS native app's use of regionOfInterest — without it,
        // Vision detects ALL barcodes on a stacked label and returns the topmost one
        // first, making it impossible to scan a specific middle barcode.
        // Coordinates are normalized (0-1) with origin at lower-left.
        self.barcodeRequest.regionOfInterest = CGRect(x: 0.0, y: 0.3, width: 1.0, height: 0.4)


        super.init()

        captureSession = AVCaptureSession()

        if #available(iOS 13.0, *) {
            captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInTripleCamera, for: AVMediaType.video, position: cameraPosition)
        }

        if captureDevice == nil {
            if #available(iOS 10.0, *) {
                captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: cameraPosition)
            } else {
                for device in AVCaptureDevice.devices(for: AVMediaType.video) {
                    if device.position == cameraPosition {
                        captureDevice = device
                        break
                    }
                }
            }
        }

        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)

            guard captureDevice != nil else {
                throw QrReaderError.noCamera
            }
        }

        let input = try AVCaptureDeviceInput.init(device: captureDevice)
        previewSize = CMVideoFormatDescriptionGetDimensions(captureDevice.activeFormat.formatDescription)

        // Configure camera for optimal barcode scanning
        do {
            try captureDevice.lockForConfiguration()

            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            }

            if captureDevice.isSmoothAutoFocusSupported {
                captureDevice.isSmoothAutoFocusEnabled = true
            }

            if captureDevice.isAutoFocusRangeRestrictionSupported {
                captureDevice.autoFocusRangeRestriction = .near
            }

            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                captureDevice.exposureMode = .continuousAutoExposure
            }

            // Set focus point of interest to center of frame (where scan target is)
            if captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }

            captureDevice.unlockForConfiguration()
        } catch {
            print("Could not configure capture device: \(error)")
        }

        NSLog("[QrReader] Using Apple Vision Framework for barcode detection")
        NSLog("[QrReader] Camera device: %@", captureDevice.localizedName)
        NSLog("[QrReader] Preview size: %d x %d", previewSize.width, previewSize.height)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true

        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        output.setSampleBufferDelegate(self, queue: queue)

        captureSession.addInput(input)
        captureSession.addOutput(output)
    }


    func toggleTorch(on: Bool) {
        guard
            let device = captureDevice ?? AVCaptureDevice.default(for: AVMediaType.video),
            device.hasTorch
        else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }

    func start() {
        captureSession.startRunning()
        self.textureId = textureRegistry.register(self)
    }

    func stop() {
        captureSession.stopRunning()
        pixelBuffer = nil
        textureRegistry.unregisterTexture(textureId)
        textureId = nil
    }
}

extension QrReader : FlutterTexture {
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if(pixelBuffer == nil){
            return nil
        }
        return  .passRetained(pixelBuffer!)
    }
}

extension QrReader: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // runs on dispatch queue

        pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        textureRegistry.textureFrameAvailable(self.textureId)


        guard !isProcessing.swap(true) else {
            return
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            self.isProcessing.value = false
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            do {
                try handler.perform([self.barcodeRequest])
            } catch {
                NSLog("[QrReader] Failed to perform barcode detection: %@", error.localizedDescription)
                self.isProcessing.value = false
                return
            }

            self.isProcessing.value = false

            guard let results = self.barcodeRequest.results, !results.isEmpty else {
                return
            }

            var barcodesList: [ScannedBarcode] = []

            for observation in results {
                guard let payload = observation.payloadStringValue else {
                    continue
                }

                // Vision Framework returns normalized coordinates (0-1) with origin at
                // bottom-left. With `.right` orientation, coordinates are already in the
                // portrait-logical space. Convert to pixel coordinates directly.
                let boundingBox = observation.boundingBox
                let imageWidth = CGFloat(self.previewSize.height) // portrait width
                let imageHeight = CGFloat(self.previewSize.width)  // portrait height

                let barcodeRect = BarcodeRect(
                    imageWidth: Int64(imageWidth),
                    imageHeight: Int64(imageHeight),
                    left: Int64(boundingBox.origin.x * imageWidth),
                    top: Int64((1.0 - boundingBox.origin.y - boundingBox.size.height) * imageHeight),
                    right: Int64((boundingBox.origin.x + boundingBox.size.width) * imageWidth),
                    bottom: Int64((1.0 - boundingBox.origin.y) * imageHeight)
                )

                let format = self.mapSymbology(observation.symbology)
                let barcode = ScannedBarcode(barcode: payload, format: format, rect: barcodeRect)
                barcodesList.append(barcode)

                // Legacy callback
                self.qrCallback(payload)
            }

            self.barcodeResponseCallback(ScannedBarcodesResponse(barcodes: barcodesList))
        }
    }

    func mapSymbology(_ symbology: VNBarcodeSymbology) -> ScannedBarcodeFormat {
        switch symbology {
        case .ean13:
            return ScannedBarcodeFormat.eAN13
        case .ean8:
            return ScannedBarcodeFormat.eAN8
        case .itf14:
            return ScannedBarcodeFormat.iTF
        case .pdf417:
            return ScannedBarcodeFormat.pDF417
        case .upce:
            return ScannedBarcodeFormat.uPCE
        case .aztec:
            return ScannedBarcodeFormat.aZTEC
        case .codabar:
            return ScannedBarcodeFormat.cODABAR
        case .code128:
            return ScannedBarcodeFormat.cODE128
        case .code93:
            return ScannedBarcodeFormat.cODE93
        case .code39:
            return ScannedBarcodeFormat.cODE39
        case .qr:
            return ScannedBarcodeFormat.qRCODE
        case .dataMatrix:
            return ScannedBarcodeFormat.dATAMATRIX
        default:
            return ScannedBarcodeFormat.unknown
        }
    }
}
