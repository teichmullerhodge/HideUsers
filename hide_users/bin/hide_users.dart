import 'package:hide_users/ploomes.dart';

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

      final dynamic usersInfo = await account.getUsersAccount();
      for (final users in usersInfo.contents) {
        print(users['Name']);
      }
    }
  }
}