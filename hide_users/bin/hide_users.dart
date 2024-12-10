import 'package:hide_users/ploomes.dart' as ploomes;

Future<void> main() async {
//  final ploomesList = await ploomes.Ploomes.;
  List<String> accountKeys = [];

  for (final accounts in ploomesList) {
    final String userKey = accounts['UserKey'];
    if (userKey == '' || accountKeys.contains(userKey)) {
      continue;
    }

    accountKeys.add(userKey);
  }
}
