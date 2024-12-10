import 'dart:convert';
import 'package:http/http.dart' as http;

bool responseOk(int status){

  return status >= 200 && status <= 299;

}

Future<List<String>> getAccountKeys() async {

  final baseURL = "";
  final defaultHeaders = {

    "Content-Type" : "application/json",

  };

  final response = await http.get(
    
    Uri.parse(baseURL),
    headers: defaultHeaders,
  
  );

  if(responseOk(response.statusCode)){

    final dynamic contents = jsonDecode(response.body);
    if()
  }


}