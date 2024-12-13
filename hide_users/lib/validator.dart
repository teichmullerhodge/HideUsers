import 'package:hide_users/credentials.dart';

import 'ploomes.dart';
import 'utils.dart' as utils;


class Validator {


  static Future<bool> ValidateAccount(Ploomes instance) async {

    final accountContext = await instance.getAccountInfo();
    
    if (accountContext.errorDetails != null) {
      utils.logError('Error getting account info.');
      return true;
    }
    final accountData = accountContext.contents['value'][0];
    utils.logWarning('Accounted info collected in the account: ${accountData['Name']} Passing to the next step.');

    final usersContext = await instance.getUsersAccount();
    
    if (usersContext.errorDetails != null) {
      utils.logError('Error getting users info.');
      return false;
    }

    utils.logWarning('Users info collected. Passing to the next step.');

    final usersData = usersContext.contents['value'];
    bool hasScript = false;
    String? fieldKey;
    for(final users in usersData){
      

      final List<dynamic> otherProperties = users['OtherProperties'];
      if(otherProperties.isEmpty){
        utils.logError('User ${users['Id']} has no other properties.');
        utils.logWarning('User mail: ${users['Email']}');
        return false;
      } 

      for(final properties in otherProperties){
        if(properties['Field']['Name'] == PloomesFields.targetInfoFieldName && properties['BigStringValue'] == Credentials.frontEndScript){
          fieldKey = properties['FieldKey'];
          hasScript = true;
          break;
        }
      }
    }

    if(!hasScript){
      utils.logError("One user doesn't have the script.");
      return false;
    }

    if(fieldKey == null){
      utils.logError("FieldKey is null.");
      return false;
    }

    utils.logWarning('All users have the script. Proceeding to the next step.');

    final formsStatusId = await PloomesForms.checkFormsStatus(instance, fieldKey);
    if(formsStatusId == FormStatus.fieldNotFound){
      utils.logError('Field not found in the forms.');
      return false;
    }
    if(formsStatusId == FormStatus.requestFailed){
      utils.logError('Request failed.');
      return false;
    }

    utils.logSuccess('Field found in the forms. Account validated!');    
    return true;

  }
}