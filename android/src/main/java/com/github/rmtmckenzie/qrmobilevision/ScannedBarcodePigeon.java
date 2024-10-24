// Autogenerated from Pigeon (v10.1.4), do not edit directly.
// See also: https://pub.dev/packages/pigeon

package com.github.rmtmckenzie.qrmobilevision;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Generated class from Pigeon. */
@SuppressWarnings({"unused", "unchecked", "CodeBlock2Expr", "RedundantSuppression", "serial"})
public class ScannedBarcodePigeon {

  /** Error class for passing custom error details to Flutter via a thrown PlatformException. */
  public static class FlutterError extends RuntimeException {

    /** The error code. */
    public final String code;

    /** The error details. Must be a datatype supported by the api codec. */
    public final Object details;

    public FlutterError(@NonNull String code, @Nullable String message, @Nullable Object details) 
    {
      super(message);
      this.code = code;
      this.details = details;
    }
  }

  @NonNull
  protected static ArrayList<Object> wrapError(@NonNull Throwable exception) {
    ArrayList<Object> errorList = new ArrayList<Object>(3);
    if (exception instanceof FlutterError) {
      FlutterError error = (FlutterError) exception;
      errorList.add(error.code);
      errorList.add(error.getMessage());
      errorList.add(error.details);
    } else {
      errorList.add(exception.toString());
      errorList.add(exception.getClass().getSimpleName());
      errorList.add(
        "Cause: " + exception.getCause() + ", Stacktrace: " + Log.getStackTraceString(exception));
    }
    return errorList;
  }

  public enum ScannedBarcodeFormat {
    UNKNOWN(0),
    CODE_128(1),
    CODE_39(2),
    CODE_93(3),
    CODABAR(4),
    DATA_MATRIX(5),
    EAN_13(6),
    EAN_8(7),
    ITF(8),
    QR_CODE(9),
    UPC_A(10),
    UPC_E(11),
    PDF417(12),
    AZTEC(13);

    final int index;

    private ScannedBarcodeFormat(final int index) {
      this.index = index;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static final class ScannedBarcodesResponse {
    private @NonNull List<ScannedBarcode> barcodes;

    public @NonNull List<ScannedBarcode> getBarcodes() {
      return barcodes;
    }

    public void setBarcodes(@NonNull List<ScannedBarcode> setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"barcodes\" is null.");
      }
      this.barcodes = setterArg;
    }

    /** Constructor is non-public to enforce null safety; use Builder. */
    ScannedBarcodesResponse() {}

    public static final class Builder {

      private @Nullable List<ScannedBarcode> barcodes;

      public @NonNull Builder setBarcodes(@NonNull List<ScannedBarcode> setterArg) {
        this.barcodes = setterArg;
        return this;
      }

      public @NonNull ScannedBarcodesResponse build() {
        ScannedBarcodesResponse pigeonReturn = new ScannedBarcodesResponse();
        pigeonReturn.setBarcodes(barcodes);
        return pigeonReturn;
      }
    }

    @NonNull
    ArrayList<Object> toList() {
      ArrayList<Object> toListResult = new ArrayList<Object>(1);
      toListResult.add(barcodes);
      return toListResult;
    }

    static @NonNull ScannedBarcodesResponse fromList(@NonNull ArrayList<Object> list) {
      ScannedBarcodesResponse pigeonResult = new ScannedBarcodesResponse();
      Object barcodes = list.get(0);
      pigeonResult.setBarcodes((List<ScannedBarcode>) barcodes);
      return pigeonResult;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static final class ScannedBarcode {
    private @NonNull String barcode;

    public @NonNull String getBarcode() {
      return barcode;
    }

    public void setBarcode(@NonNull String setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"barcode\" is null.");
      }
      this.barcode = setterArg;
    }

    private @Nullable ScannedBarcodeFormat format;

    public @Nullable ScannedBarcodeFormat getFormat() {
      return format;
    }

    public void setFormat(@Nullable ScannedBarcodeFormat setterArg) {
      this.format = setterArg;
    }

    /** https://developers.google.com/ml-kit/reference/swift/mlkitbarcodescanning/api/reference/Classes/Barcode */
    private @Nullable BarcodeRect rect;

    public @Nullable BarcodeRect getRect() {
      return rect;
    }

    public void setRect(@Nullable BarcodeRect setterArg) {
      this.rect = setterArg;
    }

    /** Constructor is non-public to enforce null safety; use Builder. */
    ScannedBarcode() {}

    public static final class Builder {

      private @Nullable String barcode;

      public @NonNull Builder setBarcode(@NonNull String setterArg) {
        this.barcode = setterArg;
        return this;
      }

      private @Nullable ScannedBarcodeFormat format;

      public @NonNull Builder setFormat(@Nullable ScannedBarcodeFormat setterArg) {
        this.format = setterArg;
        return this;
      }

      private @Nullable BarcodeRect rect;

      public @NonNull Builder setRect(@Nullable BarcodeRect setterArg) {
        this.rect = setterArg;
        return this;
      }

      public @NonNull ScannedBarcode build() {
        ScannedBarcode pigeonReturn = new ScannedBarcode();
        pigeonReturn.setBarcode(barcode);
        pigeonReturn.setFormat(format);
        pigeonReturn.setRect(rect);
        return pigeonReturn;
      }
    }

    @NonNull
    ArrayList<Object> toList() {
      ArrayList<Object> toListResult = new ArrayList<Object>(3);
      toListResult.add(barcode);
      toListResult.add(format == null ? null : format.index);
      toListResult.add((rect == null) ? null : rect.toList());
      return toListResult;
    }

    static @NonNull ScannedBarcode fromList(@NonNull ArrayList<Object> list) {
      ScannedBarcode pigeonResult = new ScannedBarcode();
      Object barcode = list.get(0);
      pigeonResult.setBarcode((String) barcode);
      Object format = list.get(1);
      pigeonResult.setFormat(format == null ? null : ScannedBarcodeFormat.values()[(int) format]);
      Object rect = list.get(2);
      pigeonResult.setRect((rect == null) ? null : BarcodeRect.fromList((ArrayList<Object>) rect));
      return pigeonResult;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static final class BarcodeRect {
    private @NonNull Long imageWidth;

    public @NonNull Long getImageWidth() {
      return imageWidth;
    }

    public void setImageWidth(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"imageWidth\" is null.");
      }
      this.imageWidth = setterArg;
    }

    private @NonNull Long imageHeight;

    public @NonNull Long getImageHeight() {
      return imageHeight;
    }

    public void setImageHeight(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"imageHeight\" is null.");
      }
      this.imageHeight = setterArg;
    }

    private @NonNull Long left;

    public @NonNull Long getLeft() {
      return left;
    }

    public void setLeft(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"left\" is null.");
      }
      this.left = setterArg;
    }

    private @NonNull Long top;

    public @NonNull Long getTop() {
      return top;
    }

    public void setTop(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"top\" is null.");
      }
      this.top = setterArg;
    }

    private @NonNull Long right;

    public @NonNull Long getRight() {
      return right;
    }

    public void setRight(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"right\" is null.");
      }
      this.right = setterArg;
    }

    private @NonNull Long bottom;

    public @NonNull Long getBottom() {
      return bottom;
    }

    public void setBottom(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"bottom\" is null.");
      }
      this.bottom = setterArg;
    }

    /** Constructor is non-public to enforce null safety; use Builder. */
    BarcodeRect() {}

    public static final class Builder {

      private @Nullable Long imageWidth;

      public @NonNull Builder setImageWidth(@NonNull Long setterArg) {
        this.imageWidth = setterArg;
        return this;
      }

      private @Nullable Long imageHeight;

      public @NonNull Builder setImageHeight(@NonNull Long setterArg) {
        this.imageHeight = setterArg;
        return this;
      }

      private @Nullable Long left;

      public @NonNull Builder setLeft(@NonNull Long setterArg) {
        this.left = setterArg;
        return this;
      }

      private @Nullable Long top;

      public @NonNull Builder setTop(@NonNull Long setterArg) {
        this.top = setterArg;
        return this;
      }

      private @Nullable Long right;

      public @NonNull Builder setRight(@NonNull Long setterArg) {
        this.right = setterArg;
        return this;
      }

      private @Nullable Long bottom;

      public @NonNull Builder setBottom(@NonNull Long setterArg) {
        this.bottom = setterArg;
        return this;
      }

      public @NonNull BarcodeRect build() {
        BarcodeRect pigeonReturn = new BarcodeRect();
        pigeonReturn.setImageWidth(imageWidth);
        pigeonReturn.setImageHeight(imageHeight);
        pigeonReturn.setLeft(left);
        pigeonReturn.setTop(top);
        pigeonReturn.setRight(right);
        pigeonReturn.setBottom(bottom);
        return pigeonReturn;
      }
    }

    @NonNull
    ArrayList<Object> toList() {
      ArrayList<Object> toListResult = new ArrayList<Object>(6);
      toListResult.add(imageWidth);
      toListResult.add(imageHeight);
      toListResult.add(left);
      toListResult.add(top);
      toListResult.add(right);
      toListResult.add(bottom);
      return toListResult;
    }

    static @NonNull BarcodeRect fromList(@NonNull ArrayList<Object> list) {
      BarcodeRect pigeonResult = new BarcodeRect();
      Object imageWidth = list.get(0);
      pigeonResult.setImageWidth((imageWidth == null) ? null : ((imageWidth instanceof Integer) ? (Integer) imageWidth : (Long) imageWidth));
      Object imageHeight = list.get(1);
      pigeonResult.setImageHeight((imageHeight == null) ? null : ((imageHeight instanceof Integer) ? (Integer) imageHeight : (Long) imageHeight));
      Object left = list.get(2);
      pigeonResult.setLeft((left == null) ? null : ((left instanceof Integer) ? (Integer) left : (Long) left));
      Object top = list.get(3);
      pigeonResult.setTop((top == null) ? null : ((top instanceof Integer) ? (Integer) top : (Long) top));
      Object right = list.get(4);
      pigeonResult.setRight((right == null) ? null : ((right instanceof Integer) ? (Integer) right : (Long) right));
      Object bottom = list.get(5);
      pigeonResult.setBottom((bottom == null) ? null : ((bottom instanceof Integer) ? (Integer) bottom : (Long) bottom));
      return pigeonResult;
    }
  }

  private static class QrMobileVisionApiCodec extends StandardMessageCodec {
    public static final QrMobileVisionApiCodec INSTANCE = new QrMobileVisionApiCodec();

    private QrMobileVisionApiCodec() {}

    @Override
    protected Object readValueOfType(byte type, @NonNull ByteBuffer buffer) {
      switch (type) {
        case (byte) 128:
          return BarcodeRect.fromList((ArrayList<Object>) readValue(buffer));
        case (byte) 129:
          return ScannedBarcode.fromList((ArrayList<Object>) readValue(buffer));
        case (byte) 130:
          return ScannedBarcodesResponse.fromList((ArrayList<Object>) readValue(buffer));
        default:
          return super.readValueOfType(type, buffer);
      }
    }

    @Override
    protected void writeValue(@NonNull ByteArrayOutputStream stream, Object value) {
      if (value instanceof BarcodeRect) {
        stream.write(128);
        writeValue(stream, ((BarcodeRect) value).toList());
      } else if (value instanceof ScannedBarcode) {
        stream.write(129);
        writeValue(stream, ((ScannedBarcode) value).toList());
      } else if (value instanceof ScannedBarcodesResponse) {
        stream.write(130);
        writeValue(stream, ((ScannedBarcodesResponse) value).toList());
      } else {
        super.writeValue(stream, value);
      }
    }
  }

  /** Generated class from Pigeon that represents Flutter messages that can be called from Java. */
  public static class QrMobileVisionApi {
    private final @NonNull BinaryMessenger binaryMessenger;

    public QrMobileVisionApi(@NonNull BinaryMessenger argBinaryMessenger) {
      this.binaryMessenger = argBinaryMessenger;
    }

    /** Public interface for sending reply. */ 
    @SuppressWarnings("UnknownNullness")
    public interface Reply<T> {
      void reply(T reply);
    }
    /** The codec used by QrMobileVisionApi. */
    static @NonNull MessageCodec<Object> getCodec() {
      return QrMobileVisionApiCodec.INSTANCE;
    }
    public void onScannedBarcode(@NonNull ScannedBarcodesResponse barcodeArg, @NonNull Reply<Void> callback) {
      BasicMessageChannel<Object> channel =
          new BasicMessageChannel<>(
              binaryMessenger, "dev.flutter.pigeon.qr_mobile_vision.QrMobileVisionApi.onScannedBarcode", getCodec());
      channel.send(
          new ArrayList<Object>(Collections.singletonList(barcodeArg)),
          channelReply -> callback.reply(null));
    }
  }
}
