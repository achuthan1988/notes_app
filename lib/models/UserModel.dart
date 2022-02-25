class UserModel {
  String userId;
  String userFullName;
  String userImageBase64;

  UserModel(this.userId, this.userFullName, this.userImageBase64);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userFullName': userFullName,
      'noteContent': userImageBase64,
    };
  }
}
