// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalExpenseModelAdapter extends TypeAdapter<GoalExpenseModel> {
  @override
  final int typeId = 4;

  @override
  GoalExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalExpenseModel(
      id: fields[0] as String,
      title: fields[1] as String,
      targetAmount: fields[2] as double,
      currentAmount: fields[3] as double,
      icon: fields[4] as String,
      colorValue: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GoalExpenseModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.currentAmount)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
