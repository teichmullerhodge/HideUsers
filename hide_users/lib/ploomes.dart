import 'dart:convert';
import 'dart:mirrors';
import 'credentials.dart';

import 'package:http/http.dart' as http;
import 'utils.dart' as utils;

abstract class Queries {
  static final userQuery =
      "\$select=Id,Name,Email,Suspended&\$expand=OtherProperties(\$expand=Field(\$select=Name);\$select=BigStringValue)&\$filter=Suspended+eq+false and Integration+eq+false";
}

class Ploomes {
  final baseURL = "https://api2.ploomes.com";
  final apiKey;
  late final Map<String, String> authorizationHeaders;
  Ploomes(this.apiKey) {
    authorizationHeaders = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
      "User-Key": apiKey
    };
  }

  Future<dynamic> getAccountsData() async {
    final response = await http.get(
      Uri.parse(baseURL),
      headers: authorizationHeaders,
    );

    if (utils.responseOk(response.statusCode)) {
      final dynamic contents = jsonDecode(response.body);
      return contents;
    } else {
      utils.handleHTTPError(
        true,
        true,
        response.body,
        response.statusCode,
      );
    }
  }

  Future<dynamic> getUsersAccount() async {
    final userURL = "$baseURL/Users?$Queries.userQuery";
    final response = await http.get(
      Uri.parse(userURL),
      headers: authorizationHeaders,
    );

    if (utils.responseOk(response.statusCode)) {
      final dynamic contents = jsonDecode(response.body);
      return contents;
    } else {
      utils.handleHTTPError(
        true,
        true,
        response.body,
        response.statusCode,
      );
    }
  }
}
