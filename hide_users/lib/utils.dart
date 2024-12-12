import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

///Throws an exception with the given error message.
Never panic(String errorMessage) {
  throw Exception(errorMessage);
}

///Request context class. It holds the response contents and error details.
///This class is used to return the response from the handleRequest function.
class RequestContext {
  final dynamic contents;
  final Map<String, dynamic>? errorDetails;

  RequestContext({this.contents, this.errorDetails});
}

///Handles the HTTP error. It logs the error and throws an exception if needed.
///Returns a map with the error details.
///Is typed as dynamic since it can return a map or throw an exception.
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

///Prints the data in a pretty format.
void prettyPrint(dynamic data) {
  print(JsonEncoder.withIndent(' ').convert(data));
}

///Logs an error message to the console with the red color.
void logError(String errorMessage) {
  final redColor = '\x1B[31m';
  final resetColor = '\x1B[0m';
  stderr.writeln('$redColor Error: $errorMessage! $resetColor');
}

///Logs a success message to the console with the green color.
void logSuccess(String sucessMessage) {
  final greenColor = '\x1B[32m';
  final resetColor = '\x1B[0m';
  stderr.writeln('$greenColor Success: $sucessMessage! $resetColor');
}

///Logs a warning message to the console with the yellow color.
void logWarning(String warningMessage) {
  final yellowColor = '\x1B[33m';
  final resetColor = '\x1B[0m';
  stderr.writeln('$yellowColor Warning: $warningMessage! $resetColor');
}
