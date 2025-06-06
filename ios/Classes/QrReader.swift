import Foundation
import AVFoundation
import MLKitVision
import MLKitBarcodeScanning
import os.log


extension BarcodeScannerOptions {
    convenience init(formatStrings: [String]) {
        let formats = formatStrings.map { (format) -> BarcodeFormat? in
            switch format  {
            case "ALL_FORMATS":
                return .all
            case "AZTEC":
                return .aztec
            case "CODE_128":
                return .code128
            case "CODE_39":
                return .code39
            case "CODE_93":
                return .code93
            case "CODABAR":
                return .codaBar
            case "DATA_MATRIX":
                return .dataMatrix
            case "EAN_13":
                return .EAN13
            case "EAN_8":
                return .EAN8
            case "ITF":
                return .ITF
            case "PDF417":
                return .PDF417
            case "QR_CODE":
                return .qrCode
            case "UPC_A":
                return .UPCA
            case "UPC_E":
                return .UPCE
            default:
                // ignore any unknown values
                return nil
            }
        }.reduce([]) { (result, format) -> BarcodeFormat in
            guard let format = format else {
                return result
            }
            return result.union(format)
        }
        
        self.init(formats: formats)
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
    let cameraPosition :AVCaptureDevice.Position
    
    var captureDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var previewSize: CMVideoDimensions!
    var textureId: Int64!
    var pixelBuffer : CVPixelBuffer?
    let barcodeDetector: BarcodeScanner
    let qrCallback: (_:String) -> Void
    let barcodeResponseCallback: (_:ScannedBarcodesResponse) -> Void
    
    
    
    init(targetWidth: Int, targetHeight: Int, direction: QrCameraDirection, textureRegistry: FlutterTextureRegistry, options: BarcodeScannerOptions, qrCallback: @escaping (_:String) -> Void, barcodeResponseCallback: @escaping (_:ScannedBarcodesResponse) -> Void) throws {
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.textureRegistry = textureRegistry
        self.qrCallback = qrCallback
        self.barcodeResponseCallback = barcodeResponseCallback
        self.cameraPosition  = direction.cameraPosition
        self.barcodeDetector = BarcodeScanner.barcodeScanner(options: options)
        
        
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
        
        
        let image = VisionImage(buffer: sampleBuffer)
        image.orientation = imageOrientation(
            deviceOrientation: UIDevice.current.orientation,
            defaultOrientation: .portrait
        )
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            self.barcodeDetector.process(image) { features, error in
                self.isProcessing.value = false
                
                guard error == nil else {
                    if #available(iOS 10.0, *) {
                        os_log("Error decoding barcode %@", error!.localizedDescription)
                    } else {
                        // Fallback on earlier versions
                        NSLog("Error decoding barcode %@", error!.localizedDescription)
                    }
                    return
                }
                
                guard let features = features, !features.isEmpty else {
                    return
                }
                
                
                var barcodesList: [ScannedBarcode] = []
                
                
                for feature in features {
                    let rect = feature.frame
                    
                    //            let barcodeRect = BarcodeRect(left: Int64(rect.minX), top: Int64(rect.minY), right:  Int64(rect.maxX), bottom: Int64(rect.maxY))
                    
                    // Re-calculated
                    let barcodeRect = BarcodeRect( imageWidth: Int64(self.previewSize.height), imageHeight: Int64(self.previewSize.width), left: Int64(self.previewSize!.height) - Int64(rect.minY), top: Int64(rect.minX), right: Int64(self.previewSize!.height) - Int64(rect.maxY), bottom: Int64(rect.maxX))
                    
                    
                    let barcode = ScannedBarcode(barcode: feature.rawValue ?? "N/A", format: self.mapBarcodeFormat(format: feature.format), rect: barcodeRect)
                    barcodesList.append(barcode)
                    
                    // Old way
                    if let value = feature.rawValue {
                        self.qrCallback(value)
                    }
                }
                
                self.barcodeResponseCallback(ScannedBarcodesResponse(barcodes: barcodesList))
            }
        }
    }
    
    func mapBarcodeFormat(format: BarcodeFormat) -> ScannedBarcodeFormat {
        switch format {
        case .EAN13:
            return ScannedBarcodeFormat.eAN13
        case .EAN8:
            return ScannedBarcodeFormat.eAN8
        case .ITF:
            return ScannedBarcodeFormat.iTF
        case .PDF417:
            return ScannedBarcodeFormat.pDF417
        case .UPCA:
            return ScannedBarcodeFormat.uPCA
        case .UPCE:
            return ScannedBarcodeFormat.uPCE
        case .aztec:
            return ScannedBarcodeFormat.aZTEC
        case .codaBar:
            return ScannedBarcodeFormat.cODABAR
        case .code128:
            return ScannedBarcodeFormat.cODE128
        case .code93:
            return ScannedBarcodeFormat.cODE93
        case .code39:
            return ScannedBarcodeFormat.cODE39
        case .qrCode:
            return ScannedBarcodeFormat.qRCODE
        case .dataMatrix:
            return ScannedBarcodeFormat.dATAMATRIX
        default:
            return ScannedBarcodeFormat.unknown
        }
    }
    
    func orientation() -> UIImage.Orientation {
        let curDeviceOrientation = UIDevice.current.orientation
        var exifOrientation: UIImage.Orientation
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, Home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, Home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, Home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, Home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    
    
    func imageOrientation(
        deviceOrientation: UIDeviceOrientation,
        defaultOrientation: UIDeviceOrientation
    ) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            return imageOrientation(deviceOrientation: defaultOrientation, defaultOrientation: .portrait)
        }
    }
    
}
