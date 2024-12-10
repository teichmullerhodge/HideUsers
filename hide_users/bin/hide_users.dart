import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

bool responseOk(int status){

  return status >= 200 && status <= 299;
}

Future<void> main() async {

  final String server  = "https://api2.ploomes.com/Deals";
  final String apiKey = "";
  final authorizationHeaders = {

    "User-Key" : apiKey,
    HttpHeaders.authorizationHeader : apiKey,
    HttpHeaders.contentTypeHeader : "application/json"
    
    };

  final response = await http.get(

    Uri.parse(server),
    headers: authorizationHeaders,

  );

  if(responseOk(response.statusCode)){

    final data = jsonDecode(response.body);
    print('Response: $data');
    return;
  }

  else {
      
      print('Failed to list users. Status code: ${response.statusCode}');
      print('Error: $response.body');
      return;
  }
}