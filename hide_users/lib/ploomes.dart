import 'dart:convert';
import 'credentials.dart';
import 'package:http/http.dart' as http;
import 'queries.dart';
import 'utils.dart' as utils;

///Abstract classes definitions

abstract class PloomesCollections {
  static Future<dynamic> getAccountsData() async {
    final response = await http.get(
      Uri.parse(Credentials.collectionsURL),
      headers: {"Content-Type": "application/json"},
    );

    return utils.handleRequest(response);
  }

  static Future<List<String>> collectAccountKeys() async {
    final dynamic ploomesList = await getAccountsData();
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
}

abstract class PloomesAccount {
  static Map<String, dynamic> appendData(
      utils.RequestContext context, Map<String, dynamic> accountInfo) {
    final String? accountName = context.contents['value'][0]['Name'];
    final int? accountId = context.contents['value'][0]['Id'];
    final String? accountRegister = context.contents['value'][0]['Register'];
    final String? accountEmail = context.contents['value'][0]['Email'];

    accountInfo['Name'] = accountName;
    accountInfo['Id'] = accountId;
    accountInfo['Register'] = accountRegister;
    accountInfo['Email'] = accountEmail;
    accountInfo['IsButtonHidden'] = true;
    accountInfo['FieldKey'] = null;
    return accountInfo;
  }
}

abstract class PloomesFields {
  static final String targetFieldName = "informações do usuário";
  static final Map<String, dynamic> fieldPayload = {
    "Name": targetFieldName,
    "DefaultBigStringValue": Credentials.frontEndScript,
    "TypeId": 2,
    "EntityId": 24,
    "Disabled": true,
  };

  static bool isButtonVisible(String? fieldInternalFormula) {
    if (fieldInternalFormula == null) {
      return false;
    }

    return !fieldInternalFormula.contains(Credentials.frontEndElement);
  }

  static Future<utils.RequestContext> searchField(
      Ploomes instance, Map<String, dynamic> accountInfo) async {
    final fieldURL =
        "${Ploomes.baseURL}/Fields?\$filter=Name eq '$targetFieldName' and EntityId eq 24";
    final response = await http.get(
      Uri.parse(fieldURL),
      headers: instance.authorizationHeaders,
    );

    print(fieldURL);
    return utils.handleRequest(response);
  }

  static Future<utils.RequestContext> createField(
      Ploomes instance, Map<String, dynamic> accountInfo) async {
    final fieldURL = "${Ploomes.baseURL}/Fields";

    final response = await http.post(
      Uri.parse(fieldURL),
      headers: instance.authorizationHeaders,
      body: jsonEncode(fieldPayload),
    );

    return utils.handleRequest(response);
  }

  static Map<String, dynamic> formatPayload(int userId, String fieldKey) {
    return {
      "Id": userId,
      "OtherProperties": [
        {"FieldKey": fieldKey, "BigStringValue": Credentials.frontEndScript}
      ]
    };
  }

  static Future<dynamic> hideUser(int userId, String fieldKey,
      Map<String, String> authorizationHeaders) async {
    final patchURL = "${Ploomes.baseURL}/Users({$userId.toString()})";
    final payload = formatPayload(userId, fieldKey);
    final response = await http.patch(
      Uri.parse(patchURL),
      headers: authorizationHeaders,
      body: payload,
    );

    return utils.handleRequest(response);
  }
}

abstract class PloomesUsers {
  static Future<utils.RequestContext> patchUser(
      Ploomes instance, int userId, String fieldKey) async {
    final patchURL = "${Ploomes.baseURL}/Users(${userId.toString()})";
    final payload = PloomesFields.formatPayload(userId, fieldKey);
    final response = await http.patch(
      Uri.parse(patchURL),
      headers: instance.authorizationHeaders,
      body: jsonEncode(payload),
    );

    return utils.handleRequest(response);
  }

  static Future<bool> iterateAndPatch(List<int> userIdsToPatch,
      Ploomes instance, Map<String, dynamic> accountData) async {
    bool allUsersPatched = true;
    for (final userId in userIdsToPatch) {
      final utils.RequestContext patchResponse = await PloomesUsers.patchUser(
          instance, userId, accountData['FieldKey']);
      if (patchResponse.errorDetails != null) {
        utils.logError('Error patching user.');
        utils.logError(patchResponse.errorDetails.toString());
        allUsersPatched = false;
        accountData['IsButtonHidden'] = false;
      } else {
        utils.logSuccess('User patched successfully.');
      }
    }

    return allUsersPatched;
  }
}

enum FormStatus {
  requestFailed,
  fieldNotFound,
}

abstract class PloomesForms {
  static final String formsKey = 'user_form';
  static final String formsFieldsURL = "${Ploomes.baseURL}/Forms@Fields";
  static final String formsURL = "${Ploomes.baseURL}/Forms";
  static final String formsFilteredUrl =
      "${Ploomes.baseURL}/Forms?\$filter=Key+eq+'$formsKey'";
  static final int ordination = 0;

  ///This function will check if the field already exists in the forms
  static Future<dynamic> checkFormsStatus(
      Ploomes instance, String fieldKey) async {
    final filteredURL = "$formsURL?\$filter=Key+eq+'$formsKey'&\$expand=Fields";
    final response = await http.get(
      Uri.parse(filteredURL),
      headers: instance.authorizationHeaders,
    );

    bool fieldInForms = false;
    final context = utils.handleRequest(response);
    if (context.errorDetails != null) {
      return FormStatus.requestFailed;
    }

    final formsData = context.contents['value'][0];
    final fields = formsData['Fields'];
    for (final field in fields) {
      if (field['FieldKey'] == fieldKey) {
        fieldInForms = true;
        break;
      }
    }
    return fieldInForms
        ? context.contents['value'][0]['Id']
        : FormStatus.fieldNotFound;
  }

  static Future<int> getFormsId(Ploomes instance) async {
    final response = await http.get(
      Uri.parse(formsFilteredUrl),
      headers: instance.authorizationHeaders,
    );
    final formsContext = utils.handleRequest(response);
    if (formsContext.errorDetails != null) {
      return 0;
    }
    return formsContext.contents['value'][0]['Id'];
  }

  static Future<utils.RequestContext> insertFieldToForms(
      Ploomes instance, String fieldKey, int formId) async {
    final fieldPayload = jsonEncode({
      "FormId": formId,
      "FieldKey": fieldKey,
      "Ordination": ordination,
    });

    final response = await http.post(
      Uri.parse(formsFieldsURL),
      headers: instance.authorizationHeaders,
      body: fieldPayload,
    );

    return utils.handleRequest(response);
  }
}

class Ploomes {
  static final baseURL = "https://api2.ploomes.com";
  final String apiKey;
  late final Map<String, String> authorizationHeaders;
  bool isSuccessfulResponse = false;

  Ploomes(this.apiKey) {
    authorizationHeaders = {
      "Authorization": "Bearer $apiKey",
      "User-Key": apiKey
    };
  }

  utils.RequestContext requestContextManager(utils.RequestContext context) {
    isSuccessfulResponse = context.errorDetails == null;
    return context;
  }

  Future<utils.RequestContext> getAccountInfo() async {
    final accountURL = "$baseURL/Account";
    final response = await http.get(
      Uri.parse(accountURL),
      headers: authorizationHeaders,
    );

    final utils.RequestContext context = utils.handleRequest(response);
    return requestContextManager(context);
  }

  Future<utils.RequestContext> getUsersAccount() async {
    final userURL = "$baseURL/Users?${Queries.userQuery}";
    final response = await http.get(
      Uri.parse(userURL),
      headers: authorizationHeaders,
    );

    final utils.RequestContext context = utils.handleRequest(response);
    return requestContextManager(context);
  }
}
