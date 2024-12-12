import 'dart:io';
import 'package:excel/excel.dart';
import 'package:hide_users/ploomes.dart';
//import 'package:hide_users/utils.dart' as utils;
import 'package:hide_users/iterableInterface.dart';

Future<void> main() async {
  final List<String> accountKeys =
      await PloomesCollections.collectAccountKeys();
  dynamic accountsData = await IterableInterface.scanUserBase(accountKeys);

  final Excel excel = Excel.createExcel();
  Sheet sheetObject = excel['Dados das contas'];
  List<CellValue> header = [
    TextCellValue('Name'),
    TextCellValue('Id'),
    TextCellValue('Register'),
    TextCellValue('Email'),
    TextCellValue('IsButtonHidden'),
    TextCellValue('NotFoundOrCreatedKey'),
    TextCellValue('FieldKey'),
    TextCellValue('ApiKey')
  ];

  sheetObject.appendRow(header);
  sheetObject = insertValues(accountsData, sheetObject);
  saveExcel(excel);
}

Sheet insertValues(dynamic accountsData, Sheet sheetObject) {
  for (final account in accountsData) {
    List<CellValue> row = [
      TextCellValue(account['Name'] ?? ''),
      IntCellValue(account['Id'] ?? 0),
      TextCellValue(account['Register'] ?? ''),
      TextCellValue(account['Email'] ?? ''),
      BoolCellValue(account['IsButtonHidden'] ?? true),
      BoolCellValue(account['NotFoundOrCreatedKey'] ?? false),
      TextCellValue(account['FieldKey'] ?? ''),
      TextCellValue(account['ApiKey'] ?? '')
    ];

    sheetObject.appendRow(row);
  }

  return sheetObject;
}

void saveExcel(Excel excel) async {
  var fileBytes = excel.save();
  File('Dados.xlsx').writeAsBytesSync(fileBytes!);
}
