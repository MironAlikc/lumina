// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryExpenseModelAdapter extends TypeAdapter<HistoryExpenseModel> {
  @override
  final int typeId = 1;

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
      categoryId: fields[5] as String,
      type: fields[6] as TransactionType,
      categoryName: fields[7] as String?,
      accountId: fields[8] as String?,
      targetAccountId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryExpenseModel obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.categoryName)
      ..writeByte(8)
      ..write(obj.accountId)
      ..writeByte(9)
      ..write(obj.targetAccountId);
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

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 0;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      case 2:
        return TransactionType.transfer;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
      case TransactionType.transfer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
