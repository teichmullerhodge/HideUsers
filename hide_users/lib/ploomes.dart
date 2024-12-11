import 'credentials.dart';
import 'package:http/http.dart' as http;
import 'utils.dart' as utils;

abstract class Queries {
  static final String userQuery =
      "\$select=Id,Name,Email,Suspended&\$expand=OtherProperties(\$expand=Field(\$select=Name);\$select=BigStringValue,FieldKey)&\$filter=Suspended+eq+false and Integration+eq+false";
  static final String accountQuery = "\$select=Id,Name,Register,Email";
}

abstract class PloomesCollections {
  static Future<dynamic> getAccountsData() async {
    final response = await http.get(
      Uri.parse(Credentials.collectionsURL),
      headers: {"Content-Type": "application/json"},
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
      "Content-Type": "application/json",
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

abstract class PloomesUser {
  static final String targetFieldName = "informações do usuário";

  static bool isButtonVisible(String? fieldInternalFormula) {
    if (fieldInternalFormula == null) {
      return false;
    }

    return !fieldInternalFormula.contains(Credentials.frontEndElement);
  }

  static Future<utils.RequestContext> patchUser(
      int userId, String fieldKey, Ploomes instance) async {
    final patchURL = "${Ploomes.baseURL}/($userId)";
    final payload = formatPayload(userId, fieldKey);
    final response = await http.patch(
      Uri.parse(patchURL),
      headers: instance.authorizationHeaders,
      body: payload,
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

  static Future<dynamic> injectHideScript(int userId, String fieldKey,
      Map<String, String> authorizationHeaders) async {
    final patchURL = "${Ploomes.baseURL}/($userId)";
    final payload = formatPayload(userId, fieldKey);
    final response = await http.patch(
      Uri.parse(patchURL),
      headers: authorizationHeaders,
      body: payload,
    );

    return utils.handleRequest(response);
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
    return accountInfo;
  }
}
