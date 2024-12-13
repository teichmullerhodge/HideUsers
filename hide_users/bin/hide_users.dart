import 'package:excel/excel.dart';
import 'package:hide_users/ploomes.dart';
import 'package:hide_users/iterableInterface.dart';
import 'package:hide_users/sheets.dart';
import 'package:hide_users/validator.dart';
import 'package:hide_users/utils.dart' as utils;
Future<void> main() async {

  final List<String> accountKeys = await PloomesCollections.collectAccountKeys();
  await hideUserBase(accountKeys);

}


Future<bool> validateAccounts(List<String> accountKeys) async {
  for(final keys in accountKeys){

    final Ploomes ploomesInstance = Ploomes(keys);
    bool isAccountWithScript = await Validator.ValidateAccount(ploomesInstance);
    if(isAccountWithScript){
      utils.logSuccess('Account $keys has the script.');
    } else {
      utils.logError('Account $keys does not have the script.');
    }
  }
  return true;
}

Future<void> hideUserBase(List<String> accountKeys) async {


  final dynamic accountsData = await IterableInterface.scanUserBase(accountKeys);
  final Excel excel = ExcelFile.createExcel();
  Sheet sheetObject = excel['Sheet1'];
  ExcelFile.initializeHeaders(sheetObject);
  sheetObject = ExcelFile.insertValues(accountsData, sheetObject);
  ExcelFile.saveExcel(excel);

}