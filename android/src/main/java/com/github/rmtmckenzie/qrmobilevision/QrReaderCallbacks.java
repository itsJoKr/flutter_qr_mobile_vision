package com.github.rmtmckenzie.qrmobilevision;

import java.util.List;

public interface QrReaderCallbacks {
    void qrRead(String data);

    void onScanned(List<ScannedBarcodePigeon.ScannedBarcode> barcodes);
}
