import 'package:excel/excel.dart';
import 'dart:io';

abstract class ExcelFile {


  static Excel createExcel() {
    return Excel.createExcel();
  }

  static void initializeHeaders(Sheet sheetObject) {
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
  }

  static Sheet insertValues(dynamic accountsData, Sheet sheetObject) {
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

  static void saveExcel(Excel excel) async {
    var fileBytes = excel.save();
    File('Dados.xlsx').writeAsBytesSync(fileBytes!);
  }

}