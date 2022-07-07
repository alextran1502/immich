import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:hive/hive.dart';
import '../../../constants/hive_box.dart';

const FlutterAppAuth appAuth = FlutterAppAuth();
const oAuth2RedirectUri = 'app.alextran.immich://login-callback';

class OAuth2Service {

  static Future<bool> tryLogin(String issuer, String clientId) async {
    debugPrint("Trying OAuth2/OIDC auth");

    if (!issuer.startsWith("https://")) return false;

    var oAuth2Token = await OAuth2Service.getToken(issuer, clientId);
    if (oAuth2Token == null) {
      debugPrint("OAuth2/OIDC auth failed");
      return false;
    }

    debugPrint("OAuth2/OIDC auth successful");

    Hive.box(userInfoBox).put(oauth2IssuerKey, issuer);
    Hive.box(userInfoBox).put(oauth2ClientIdKey, clientId);
    Hive.box(userInfoBox).put(accessTokenKey, oAuth2Token.idToken);
    Hive.box(userInfoBox).put(refreshTokenKey, oAuth2Token.refreshToken);

    return true;
  }

  static Future<AuthorizationTokenResponse?> getToken(issuer, clientId) async {
    try {
      return await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          oAuth2RedirectUri,
          issuer: issuer,
          scopes: ['openid', 'profile', 'email'],
        ),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<bool> refreshToken() async {

    var box = Hive.box(userInfoBox);

    if (box.get(refreshTokenKey) == null) return false;

    try {
      var r = await appAuth.token(TokenRequest(
          box.get(oauth2ClientIdKey),
          oAuth2RedirectUri,
          issuer: box.get(oauth2IssuerKey),
          refreshToken: box.get(refreshTokenKey),
          scopes: ['openid','profile', 'email']));

      if (r == null) return false;

      debugPrint("OAuth2 token refreshed");

      box.put(accessTokenKey, r.idToken);
      box.put(refreshTokenKey, r.refreshToken);
      return true;
    } catch (e) {
      debugPrint("Could not refresh OAuth2 token");
      debugPrint(e.toString());
      return false;
    }
  }

}