Never panic(String errorMessage) {
  throw Exception(errorMessage);
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
}

bool responseOk(int status) {
  return status >= 200 && status <= 299;
}
