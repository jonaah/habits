// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as HabitFrequency,
      fields[4] as IconData?,
      fields[5] as String?,
      fields[6] as int,
      fields[7] as DateTime,
      (fields[8] as List).cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.streak)
      ..writeByte(7)
      ..write(obj.lastCompleted)
      ..writeByte(8)
      ..write(obj.completedDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitFrequencyAdapter extends TypeAdapter<HabitFrequency> {
  @override
  final int typeId = 1;

  @override
  HabitFrequency read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitFrequency(
      fields[0] as FrequencyType,
      (fields[1] as List).cast<int>(),
      fields[2] as int,
      fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HabitFrequency obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.daysOfWeek)
      ..writeByte(2)
      ..write(obj.dayOfMonth)
      ..writeByte(3)
      ..write(obj.customDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FrequencyTypeAdapter extends TypeAdapter<FrequencyType> {
  @override
  final int typeId = 2;

  @override
  FrequencyType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FrequencyType.daily;
      case 1:
        return FrequencyType.weekly;
      case 2:
        return FrequencyType.monthly;
      case 3:
        return FrequencyType.custom;
      default:
        return FrequencyType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, FrequencyType obj) {
    switch (obj) {
      case FrequencyType.daily:
        writer.writeByte(0);
        break;
      case FrequencyType.weekly:
        writer.writeByte(1);
        break;
      case FrequencyType.monthly:
        writer.writeByte(2);
        break;
      case FrequencyType.custom:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
