import 'credentials.dart';
import 'package:http/http.dart' as http;
import 'utils.dart' as utils;

abstract class Queries {
  
  static final String userQuery =
      "\$select=Id,Name,Email,Suspended&\$expand=OtherProperties(\$expand=Field(\$select=Name);\$select=BigStringValue)&\$filter=Suspended+eq+false and Integration+eq+false";
  static final String accountQuery = "\$select=Id,Name,Register,Email";

}

abstract class PloomesCollections {

  static Future<dynamic> getAccountsData() async {
    final response = await http.get(
      Uri.parse(Credentials.collectionsURL),
      headers: {"Content-Type" : "application/json"},
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

  Future<dynamic> getAccountInfo() async {

    final accountURL = "$baseURL/Account";
    final response = await http.get(
      Uri.parse(accountURL),
      headers: authorizationHeaders,
    );
    
    final utils.RequestContext context = utils.handleRequest(response);
    return requestContextManager(context);

  }

  Future<dynamic> getUsersAccount() async {

    final userURL = "$baseURL/Users?${Queries.userQuery}";
    final response = await http.get(
      Uri.parse(userURL),
      headers: authorizationHeaders,
    );

    final utils.RequestContext context = utils.handleRequest(response);
    return requestContextManager(context);

  }

}

class PloomesUser {

  static bool isButtonVisible(String fieldInternalFormula){
    return fieldInternalFormula.contains("a.button.button-white-no-border.pull-right.nowrap");
  }

  static Map<String,dynamic> formatPayload(int userId, String fieldKey){
    return {"Id" : userId, "OtherProperties": [{"FieldKey": fieldKey, "BigStringValue": Credentials.frontEndScript}]};
  }

  static Future<dynamic> injectHideScript(int userId, String fieldKey, Map<String, String> authorizationHeaders) async {
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