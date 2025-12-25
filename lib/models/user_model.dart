class UserModel {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String avatarUrl;
  final String password; // Thêm để kiểm tra đăng nhập
  final String loginOTP; // Thêm để kiểm tra quên mật khẩu

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.displayName = "",
    this.avatarUrl = "",
    this.password = "",
    this.loginOTP = "",
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      password: map['password'] ?? '', //
      loginOTP: map['loginOTP'] ?? '', //
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'password': password,
      'loginOTP': loginOTP,
    };
  }
}