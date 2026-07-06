// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryExpenseModelAdapter extends TypeAdapter<HistoryExpenseModel> {
  @override
  final int typeId = 0;

  @override
  HistoryExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryExpenseModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      productName: fields[2] as String,
      price: fields[3] as double,
      isSynced: fields[4] as bool,
      category: fields[5] as String,
      type: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryExpenseModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
