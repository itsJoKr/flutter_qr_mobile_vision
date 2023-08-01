package com.github.rmtmckenzie.qrmobilevision;

import android.util.Log;
import android.util.Size;

import androidx.annotation.GuardedBy;
import androidx.annotation.NonNull;


import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.mlkit.vision.barcode.BarcodeScanner;
import com.google.mlkit.vision.barcode.BarcodeScannerOptions;
import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;
import com.google.mlkit.vision.common.InputImage;

import java.util.ArrayList;
import java.util.List;

/**
 * Allows QrCamera classes to send frames to a Detector
 */

class QrDetector implements OnSuccessListener<List<Barcode>>, OnFailureListener {
    private static final String TAG = "cgr.qrmv.QrDetector";
    private final QrReaderCallbacks communicator;
    private final BarcodeScanner detector;

    public interface Frame {
        InputImage toImage();

        void close();
    }

    @GuardedBy("this")
    private Frame latestFrame;

    @GuardedBy("this")
    private Frame processingFrame;

    @GuardedBy("this")
    private Size latestFrameSize;

    QrDetector(QrReaderCallbacks communicator, BarcodeScannerOptions options) {
        this.communicator = communicator;
        this.detector = BarcodeScanning.getClient(options);
    }

    void detect(Frame frame) {
        if (latestFrame != null) latestFrame.close();
        latestFrame = frame;

        if (processingFrame == null) {
            processLatest();
        }
    }

    private synchronized void processLatest() {
        if (processingFrame != null) processingFrame.close();
        processingFrame = latestFrame;
        latestFrame = null;
        if (processingFrame != null) {
            processFrame(processingFrame);
        }
    }

    private void processFrame(Frame frame) {
        InputImage image;
        try {
            image = frame.toImage();
            latestFrameSize = new Size(image.getWidth(), image.getHeight());
        } catch (IllegalStateException ex) {
            // ignore state exception from making frame to image
            // as the image may be closed already.
            return;
        }

        if (image != null) {
            detector.process(image)
                .addOnSuccessListener(this)
                .addOnFailureListener(this)
                .addOnCompleteListener((Task<List<Barcode>> firebaseVisionBarcodes) -> {
                    // regardless of failure or success, close the previous frame
                    // and process the next one.
                    frame.close();
                    processLatest();;
                });
        }
    }

    @Override
    public void onSuccess(List<Barcode> firebaseVisionBarcodes) {
        final List<ScannedBarcodePigeon.ScannedBarcode> barcodes = new ArrayList<>();

        if (firebaseVisionBarcodes.isEmpty()) {
            return;
        }

        for (Barcode barcode : firebaseVisionBarcodes) {
            communicator.qrRead(barcode.getDisplayValue());

            final ScannedBarcodePigeon.ScannedBarcode barcode1 = new ScannedBarcodePigeon.ScannedBarcode();
            barcode1.setBarcode(barcode.getDisplayValue());

            if (barcode.getBoundingBox() != null) {
                final ScannedBarcodePigeon.BarcodeRect barcodeRect = new ScannedBarcodePigeon.BarcodeRect();
                barcodeRect.setLeft((long) barcode.getBoundingBox().left);
                barcodeRect.setTop((long) barcode.getBoundingBox().top);
                barcodeRect.setRight((long) barcode.getBoundingBox().right);
                barcodeRect.setBottom((long) barcode.getBoundingBox().bottom);
                // Putting width to height, because image is always rotated 90 degrees
                barcodeRect.setImageHeight((long) latestFrameSize.getWidth());
                barcodeRect.setImageWidth((long) latestFrameSize.getHeight());
                barcode1.setRect(barcodeRect);
            }

            barcodes.add(barcode1);
        }
        communicator.onScanned(barcodes);
    }

    @Override
    public void onFailure(@NonNull Exception e) {
        Log.w(TAG, "Barcode Reading Failure: ", e);
    }
}
