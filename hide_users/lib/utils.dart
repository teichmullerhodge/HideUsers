import 'dart:convert';
import 'package:http/http.dart' as http;
Never panic(String errorMessage) {
  throw Exception(errorMessage);
}

class RequestContext {
  final dynamic contents;
  final Map<String, dynamic>? errorDetails;

  RequestContext({this.contents, this.errorDetails});
}

dynamic handleHTTPError(
    bool logError, bool throwException, String errorMessage, int statusCode) {
  if (logError) {
    print('Request failed with status: $statusCode.');
    print('Error: $errorMessage');
  }

  if (throwException) {
    panic(errorMessage);
  }

  return {
    'Error': errorMessage,
    'StatusCode': statusCode,
  };
}

bool responseOk(int status) {
  return status >= 200 && status <= 299;
}

RequestContext handleRequest(http.Response response) {
  if (responseOk(response.statusCode)) {
    final dynamic contents = jsonDecode(response.body);
    return RequestContext(contents: contents, errorDetails: null);
  } else {
    final errorDetails = handleHTTPError(
      false,
      false,
      response.body,
      response.statusCode,
    );

    return RequestContext(errorDetails: errorDetails, contents: null);
    
  }
}