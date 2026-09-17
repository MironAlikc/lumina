// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringExpenseModelAdapter extends TypeAdapter<RecurringExpenseModel> {
  @override
  final int typeId = 3;

  @override
  RecurringExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringExpenseModel(
      id: fields[0] as String,
      productName: fields[1] as String,
      price: fields[2] as double,
      categoryId: fields[3] as String,
      isIncome: fields[4] as bool,
      dayOfMonth: fields[5] as int,
      typeName: fields[6] as String,
      lastProcessedMonth: fields[7] as int,
      lastProcessedYear: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringExpenseModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.isIncome)
      ..writeByte(5)
      ..write(obj.dayOfMonth)
      ..writeByte(6)
      ..write(obj.typeName)
      ..writeByte(7)
      ..write(obj.lastProcessedMonth)
      ..writeByte(8)
      ..write(obj.lastProcessedYear);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
