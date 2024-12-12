import 'ploomes.dart';
import 'utils.dart' as utils;

abstract class IterableInterface {
  /// This function will scan the user base and check if the button is hidden or not.
  /// If the button is visible, it will patch the user to hide the button.
  /// if the button is not visible, it will continue to the next user.
  /// the variable defined inside the function body [userBaseData] will be used to store the data.
  /// the function will return the userbaseData variable.

  static Future<dynamic> scanUserBase(List<String> accountKeys) async {
    List<Map<String, dynamic>> userBaseData = [];
    for (final keys in accountKeys) {
      final ploomesInstance = Ploomes(keys);
      final utils.RequestContext accountInfo =
          await ploomesInstance.getAccountInfo();
      Map<String, dynamic> currentAccountData = {};
      currentAccountData['ApiKey'] = keys;

      if (ploomesInstance.isSuccessfulResponse) {
        currentAccountData =
            PloomesAccount.appendData(accountInfo, currentAccountData);

        utils.logWarning(
            'Current account being analyzed: ${currentAccountData['Name']}');

        final utils.RequestContext usersInfo =
            await ploomesInstance.getUsersAccount();

        if (usersInfo.errorDetails != null) {
          utils.logError('Error fetching users data.');
          utils.logError(usersInfo.errorDetails.toString());
          utils.prettyPrint(currentAccountData);
        }

        final dynamic usersData = usersInfo.contents['value'];
        final Map<String, dynamic> usersContext = await iterateOverUsers(
            usersData, currentAccountData, ploomesInstance);
        final List<int> userIdsToPatch = usersContext['UserIdsToPatch'];
        if (userIdsToPatch.isNotEmpty) {
          final bool allUsersPatched = await PloomesUsers.iterateAndPatch(
              userIdsToPatch, ploomesInstance, usersContext);
          if (!allUsersPatched) {
            utils.logError('Error patching users.');
            utils.prettyPrint(currentAccountData);
          } else {
            utils.logSuccess('All users patched successfully.');
          }
        }

        final formsStatusId = await PloomesForms.checkFormsStatus(
            ploomesInstance, currentAccountData['FieldKey']);

        if (formsStatusId == FormStatus.fieldNotFound ||
            formsStatusId == FormStatus.requestFailed) {
          utils.logError('Field not found in the forms.');
          utils.logWarning(
              'Account ${currentAccountData['Name']} is not ready to go.');
          //implement the logic to add the field to the forms.

          final int formsId = await PloomesForms.getFormsId(ploomesInstance);
          if (formsId == 0) {
            utils.logError('Forms not found.');
            utils.logError('Error adding field to the forms.');
          } else {
            final createdFormContext = await PloomesForms.insertFieldToForms(
                ploomesInstance, currentAccountData['FieldKey'], formsId);
            if (createdFormContext.errorDetails != null) {
              utils.logError('Error adding field to the forms.');
              utils.logError(createdFormContext.errorDetails.toString());
            } else {
              utils.logSuccess('Field added to the forms.');
              utils.logSuccess(
                  'Account ${currentAccountData['Name']} is ready to go.');
            }
          }
        } else {
          print("Forms Field Id: $formsStatusId");
          utils.logSuccess('Field found in the forms.');
          utils.logSuccess(
              'Account ${currentAccountData['Name']} is ready to go.');
        }

        userBaseData.add(currentAccountData);
      } else {
        utils.logError('Account inactivated or not found.');
        continue;
      }
    }

    return userBaseData;
  }

  static Future<Map<String, dynamic>> iterateOverUsers(List<dynamic> usersData,
      Map<String, dynamic> currentAccountData, Ploomes instance) async {
    List<int> userIdsToPatch = [];

    for (final user in usersData) {
      final int userId = user['Id'];
      final List<dynamic> otherProperties = user['OtherProperties'];
      bool hasOtherProperties = otherProperties.isNotEmpty;
      if (!hasOtherProperties) {
        currentAccountData['IsButtonHidden'] = false;
        userIdsToPatch.add(userId);
        continue;
      }

      await iterateOverProperties(
          otherProperties, currentAccountData, userId, userIdsToPatch);
    }
    if (currentAccountData['IsButtonHidden'] == true &&
        currentAccountData['FieldKey'] == null) {
      utils.prettyPrint(currentAccountData);
      //this is technically impossible.
      utils.panic('FieldKey is null and the button is hidden! Panic!');
    }

    if (currentAccountData['IsButtonHidden'] == false &&
        currentAccountData['FieldKey'] == null) {
      ///in this case the field doesn't exist in the account or wasn't found, it needs to be created or found.
      String? createdFieldKey;
      final fieldContext =
          await PloomesFields.searchField(instance, currentAccountData);
      final fieldFound = fieldContext.contents['value'].isNotEmpty;
      final String? fieldKey =
          fieldFound ? fieldContext.contents['value'][0]['Key'] : null;
      if (fieldKey != null) {
        currentAccountData['FieldKey'] = fieldKey;
      } else {
        final createdFieldContext =
            await PloomesFields.createField(instance, currentAccountData);
        if (createdFieldContext.errorDetails != null) {
          utils.logError('Error creating field.');
          utils.logError(createdFieldContext.errorDetails.toString());
        } else {
          createdFieldKey = createdFieldContext.contents['value'][0]['Key'];
        }
      }
      final String? foundOrCreatedKey = createdFieldKey ?? fieldKey;
      if (foundOrCreatedKey == null) {
        currentAccountData['NotFoundOrCreatedKey'] = true;
      }
      currentAccountData['FieldKey'] = foundOrCreatedKey;
    }

    currentAccountData['UserIdsToPatch'] = userIdsToPatch;
    return currentAccountData;
  }

  static Future<Map<String, dynamic>> iterateOverProperties(
      List<dynamic> otherProperties,
      Map<String, dynamic> currentAccountData,
      int userId,
      List<int> userIdsToPatch) async {
    bool foundTheField = false;
    for (final properties in otherProperties) {
      final String? fieldName = properties['Field']['Name'];
      if (fieldName == PloomesFields.targetFieldName) {
        foundTheField = true;
        final String? fieldKey = properties['FieldKey'];
        currentAccountData['FieldKey'] = fieldKey;

        final String? fieldInternalFormula = properties['BigStringValue'];
        bool isVisible = PloomesFields.isButtonVisible(fieldInternalFormula);
        if (isVisible) {
          currentAccountData['IsButtonHidden'] = false;
          userIdsToPatch.add(userId);
        }
      }
    }

    if (currentAccountData['FieldKey'] == null || !foundTheField) {
      currentAccountData['IsButtonHidden'] = false;
      userIdsToPatch.add(userId);
    }

    return currentAccountData;
  }
}