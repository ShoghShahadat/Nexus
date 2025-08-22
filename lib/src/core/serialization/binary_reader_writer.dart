import 'dart:convert';
import 'dart:typed_data';

/// A helper class for writing primitive data types to a byte buffer.
///
/// This class provides methods to convert standard Dart types into a
/// compact binary format, which is essential for efficient network transfer.
class BinaryWriter {
  final BytesBuilder _builder = BytesBuilder();
  late final ByteData _byteData;

  BinaryWriter() {
    // A temporary 8-byte buffer for writing fixed-size data like doubles and ints.
    // This avoids reallocating memory for every write operation.
    _byteData = ByteData(8);
  }

  /// Writes a 64-bit double-precision floating-point number.
  void writeDouble(double value) {
    _byteData.setFloat64(0, value, Endian.little);
    _builder.add(_byteData.buffer.asUint8List(0, 8));
  }

  /// Writes a 32-bit signed integer.
  void writeInt32(int value) {
    _byteData.setInt32(0, value, Endian.little);
    _builder.add(_byteData.buffer.asUint8List(0, 4));
  }

  /// Writes a single byte for a boolean value (1 for true, 0 for false).
  void writeBool(bool value) {
    _builder.addByte(value ? 1 : 0);
  }

  /// Writes a string by first writing its length (as a 32-bit int),
  /// followed by the UTF-8 encoded bytes of the string.
  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeInt32(bytes.length);
    _builder.add(bytes);
  }

  /// Returns the final, consolidated byte buffer.
  Uint8List toBytes() {
    return _builder.toBytes();
  }
}

/// A helper class for reading primitive data types from a byte buffer.
///
/// This class reads data in the exact same format and order as written by
/// the [BinaryWriter], ensuring perfect deserialization.
class BinaryReader {
  final ByteData _byteData;
  int _offset = 0;

  BinaryReader(Uint8List bytes)
      : _byteData = ByteData.view(
            bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);

  /// Reads a 64-bit double-precision floating-point number.
  double readDouble() {
    final value = _byteData.getFloat64(_offset, Endian.little);
    _offset += 8;
    return value;
  }

  /// Reads a 32-bit signed integer.
  int readInt32() {
    final value = _byteData.getInt32(_offset, Endian.little);
    _offset += 4;
    return value;
  }

  /// Reads a single byte and interprets it as a boolean.
  bool readBool() {
    final value = _byteData.getUint8(_offset);
    _offset += 1;
    return value == 1;
  }

  /// Reads a string by first reading its 32-bit length, then decoding
  /// that many bytes as a UTF-8 string.
  String readString() {
    final length = readInt32();
    final bytes =
        _byteData.buffer.asUint8List(_byteData.offsetInBytes + _offset, length);
    _offset += length;
    return utf8.decode(bytes);
  }
}
