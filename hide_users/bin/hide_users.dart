import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:hide_users/ploomes.dart';
import 'package:hide_users/utils.dart' as utils;

Future<List<String>> collectAccountKeys() async {
  final dynamic ploomesList = await PloomesCollections.getAccountsData();
  final List<String> accountKeys = [];

  for (final accounts in ploomesList.contents) {
    final String userKey = accounts['UserKey'];
    if (userKey == '' || accountKeys.contains(userKey)) {
      continue;
    }

    accountKeys.add(userKey);
  }

  return accountKeys;
}

bool verifyOtherProperties(List<dynamic> otherProperties) {
  return otherProperties.isNotEmpty;
}

Map<String, dynamic> iterateOverProperties(
    List<dynamic> otherProperties,
    Map<String, dynamic> currentAccountData,
    int userId,
    List<int> userIdsToPatch) {
  for (final properties in otherProperties) {
    //set the field key to the current account data.
    //this will be used to patch the user later.

    final String? fieldName = properties['Field']['Name'];
    if (fieldName == PloomesUser.targetFieldName) {
      final String? fieldKey = properties['FieldKey'];
      currentAccountData['FieldKey'] = fieldKey;

      final String? fieldInternalFormula = properties['BigStringValue'];
      bool isVisible = PloomesUser.isButtonVisible(fieldInternalFormula);
      if (isVisible) {
        currentAccountData['IsButtonHidden'] = false;
        userIdsToPatch.add(userId);
        throw Exception('Found one that is visible!');
      }

      print(fieldInternalFormula); //should print the script to hide the button.
    }
  }

  return currentAccountData;
}

Future<Map<String, dynamic>> iterateOverUsers(List<dynamic> usersData,
    Map<String, dynamic> currentAccountData, Ploomes instance) async {
  List<int> userIdsToPatch = [];

  for (final user in usersData) {
    final int userId = user['Id'];
    final List<dynamic> otherProperties = user['OtherProperties'];
    bool hasOtherProperties = otherProperties.isNotEmpty;
    if (!hasOtherProperties) {
      currentAccountData['IsButtonHidden'] = false;
      print('User has no other properties.');
      userIdsToPatch.add(userId);
    }

    iterateOverProperties(
        otherProperties, currentAccountData, userId, userIdsToPatch);
    if (userIdsToPatch.isNotEmpty && 1 > 1000) {
      //test.
      for (final id in userIdsToPatch) {
        await PloomesUser.patchUser(
            id, currentAccountData['FieldKey'], instance);
      }
    }
  }
  return currentAccountData;
}

/// This function will scan the user base and check if the button is hidden or not.
/// If the button is visible, it will patch the user to hide the button.
/// if the button is not visible, it will continue to the next user.
/// the variable defined inside the function body [userBaseData] will be used to store the data.
/// the function will return the userbaseData variable.
Future<dynamic> scanUserBase(List<String> accountKeys) async {
  List<Map<String, dynamic>> userBaseData = [];
  for (final keys in accountKeys) {
    final ploomesInstance = Ploomes(keys);
    final accountInfo = await ploomesInstance.getAccountInfo();
    if (ploomesInstance.isSuccessfulResponse) {
      Map<String, dynamic> currentAccountData = {};

      currentAccountData =
          PloomesAccount.appendData(accountInfo, currentAccountData);

      final utils.RequestContext usersInfo =
          await ploomesInstance.getUsersAccount();

      if (usersInfo.errorDetails != null) {
        print('Error fetching users data.');
        print(usersInfo.errorDetails);
      }
      final dynamic usersData = usersInfo.contents['value'];
      iterateOverUsers(usersData, currentAccountData, ploomesInstance);
      userBaseData.add(currentAccountData);
    } else {
      print('Error fetching account data.');
      print(accountInfo.errorDetails);
    }
  }

  return userBaseData;
}

Future<void> main() async {
  final List<String> accountKeys = await collectAccountKeys();
  dynamic accountsData = await scanUserBase(accountKeys);

  String accountsOutput = JsonEncoder.withIndent(' ').convert(accountsData);
  print(accountsOutput); //just outpus the data.

  final Excel excel = Excel.createExcel();
  Sheet sheetObject = excel['Dados das contas'];
  List<CellValue> header = [
    TextCellValue('Name'),
    TextCellValue('Id'),
    TextCellValue('Register'),
    TextCellValue('Email'),
    TextCellValue('IsButtonHidden'),
    TextCellValue('FieldKey'),
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
      TextCellValue(account['FieldKey'] ?? ''),
    ];

    sheetObject.appendRow(row);
  }

  return sheetObject;
}

void saveExcel(Excel excel) async {
  var fileBytes = excel.save();
  File('Dados.xlsx').writeAsBytesSync(fileBytes!);
}
