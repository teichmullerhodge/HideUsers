abstract class Queries {
  static final String userQuery =
      "\$select=Id,Name,Email,Suspended&\$expand=OtherProperties(\$expand=Field(\$select=Name);\$select=BigStringValue,FieldKey)&\$filter=Suspended+eq+false and Integration+eq+false";
  static final String accountQuery = "\$select=Id,Name,Register,Email";
}
