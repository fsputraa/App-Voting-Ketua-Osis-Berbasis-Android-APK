library sign_in_with_apple;

class SignInWithApple {
  static Future<dynamic> getAppleIDCredential({
    List<String>? scopes,
    String? nonce,
    String? state,
    String? webAuthenticationOptions,
  }) async {
    throw UnsupportedError('SignInWithApple is not supported on this platform.');
  }
}

class AppleIDAuthorizationScopes {
  static const email = 'email';
  static const fullName = 'fullName';
}
