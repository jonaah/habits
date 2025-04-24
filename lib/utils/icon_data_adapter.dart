import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class IconDataAdapter extends TypeAdapter<IconData> {
  @override
  final int typeId = 3;

  @override
  IconData read(BinaryReader reader) {
    final codePoint = reader.readInt();
    final fontFamily = reader.readString();
    final fontPackage = reader.readString().isEmpty ? null : reader.readString();
    final matchTextDirection = reader.readBool();
    
    return IconData(
      codePoint,
      fontFamily: fontFamily.isEmpty ? null : fontFamily,
      fontPackage: fontPackage,
      matchTextDirection: matchTextDirection,
    );
  }

  @override
  void write(BinaryWriter writer, IconData obj) {
    writer.writeInt(obj.codePoint);
    writer.writeString(obj.fontFamily ?? '');
    writer.writeString(obj.fontPackage ?? '');
    writer.writeBool(obj.matchTextDirection);
  }
}

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final typeId = 4;

  @override
  Color read(BinaryReader reader) {
    final value = reader.readInt();
    return Color(value);
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.value);
  }
}