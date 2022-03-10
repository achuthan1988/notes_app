class UserModel {
  String userId;
  String userFullName;
  String userImageBase64;
  String userEmailId;

  UserModel(this.userId, this.userFullName, this.userImageBase64,this.userEmailId);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userFullName': userFullName,
      'noteContent': userImageBase64,
      'userEmailId':userEmailId
    };
  }
}
