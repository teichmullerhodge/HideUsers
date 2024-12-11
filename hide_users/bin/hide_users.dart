import 'package:hide_users/ploomes.dart';
import 'package:hide_users/utils.dart' as utils;
Future<void> main() async {
  final dynamic ploomesList = await PloomesCollections.getAccountsData();
  final List<String> accountKeys = [];

  for (final accounts in ploomesList.contents) {
    final String userKey = accounts['UserKey'];
    if (userKey == '' || accountKeys.contains(userKey)) {
      continue;
    }

    accountKeys.add(userKey);
  }

  for(final keys in accountKeys) {
    final account = Ploomes(keys);
    final accountInfo = await account.getAccountInfo();
    if(account.isSuccessfulResponse) {

      final utils.RequestContext usersInfo = await account.getUsersAccount();
      final dynamic data = usersInfo.contents['value'];
      for(final userInfo in data){
          print(userInfo['Name']);
      }
    }
  }
}
