import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/modules/login/models/hive_saved_login_info.model.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/providers/asset.provider.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/shared/ui/immich_toast.dart';

class LoginForm extends HookConsumerWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController =
        useTextEditingController.fromValue(TextEditingValue.empty);
    final passwordController =
        useTextEditingController.fromValue(TextEditingValue.empty);
    final serverEndpointController =
        useTextEditingController(text: 'http://your-server-ip:2283/api');
    final isSaveLoginInfo = useState<bool>(false);

    useEffect(() {
      var loginInfo =
          Hive.box<HiveSavedLoginInfo>(hiveLoginInfoBox).get(savedLoginInfoKey);

      if (loginInfo != null) {
        usernameController.text = loginInfo.email;
        passwordController.text = loginInfo.password;
        serverEndpointController.text = loginInfo.serverUrl;
        isSaveLoginInfo.value = loginInfo.isSaveLogin;
      }

      return null;
    }, []);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              const Image(
                image: AssetImage('assets/immich-logo-no-outline.png'),
                width: 100,
                filterQuality: FilterQuality.high,
              ),
              Text(
                'IMMICH',
                style: TextStyle(
                  fontFamily: 'SnowburstOne',
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              EmailInput(controller: usernameController),
              PasswordInput(controller: passwordController),
              ServerEndpointInput(controller: serverEndpointController),
              CheckboxListTile(
                activeColor: Theme.of(context).primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
                side: const BorderSide(color: Colors.grey, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                enableFeedback: true,
                title: const Text(
                  "Stay logged in",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
                value: isSaveLoginInfo.value,
                onChanged: (switchValue) {
                  if (switchValue != null) {
                    isSaveLoginInfo.value = switchValue;
                  }
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  LoginButton(
                    emailController: usernameController,
                    passwordController: passwordController,
                    serverEndpointController: serverEndpointController,
                    isSavedLoginInfo: isSaveLoginInfo.value,
                    oauth2Login: false,
                  ),
                  LoginButton(
                    emailController: usernameController,
                    passwordController: passwordController,
                    serverEndpointController: serverEndpointController,
                    isSavedLoginInfo: isSaveLoginInfo.value,
                    oauth2Login: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServerEndpointInput extends StatelessWidget {
  final TextEditingController controller;

  const ServerEndpointInput({Key? key, required this.controller})
      : super(key: key);

  String? _validateInput(String? url) {
  
    if (url?.startsWith(RegExp(r'https?://')) == true) {
      return null;
    } else {
      return 'Please specify http:// or https://';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Server Endpoint URL',
        border: OutlineInputBorder(),
        hintText: 'http://your-server-ip:port',
      ),
      validator: _validateInput,
      autovalidateMode: AutovalidateMode.always,
    );
  }
}

class EmailInput extends StatelessWidget {
  final TextEditingController controller;

  const EmailInput({Key? key, required this.controller}) : super(key: key);

  String? _validateInput(String? email) {
    if (email == null || email == '') return null;
    if (email.endsWith(' ')) return 'Trailing whitespace';
    if (email.startsWith(' ')) return 'Leading whitespace';
    if (email.contains(' ') || !email.contains('@')) return 'Invalid Email';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        hintText: 'youremail@email.com',
      ),
      validator: _validateInput,
      autovalidateMode: AutovalidateMode.always,
    );
  }
}

class PasswordInput extends StatelessWidget {
  final TextEditingController controller;

  const PasswordInput({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: true,
      controller: controller,
      decoration: const InputDecoration(
          labelText: 'Password',
          border: OutlineInputBorder(),
          hintText: 'password'),
    );
  }
}

class LoginButton extends ConsumerWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController serverEndpointController;
  final bool isSavedLoginInfo;
  final bool oauth2Login;

  const LoginButton({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.serverEndpointController,
    required this.isSavedLoginInfo,
    required this.oauth2Login,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          visualDensity: VisualDensity.standard,
          primary: Theme.of(context).primaryColor,
          onPrimary: Colors.grey[50],
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
        ),
        onPressed: () async {
          // This will remove current cache asset state of previous user login.
          ref.watch(assetProvider.notifier).clearAllAsset();

          var isAuthenticated = await ref
              .watch(authenticationProvider.notifier)
              .login(emailController.text, passwordController.text,
                  serverEndpointController.text, isSavedLoginInfo, oauth2Login);

          if (isAuthenticated) {
            // Resume backup (if enable) then navigate

            if (ref.watch(authenticationProvider).shouldChangePassword &&
                !ref.watch(authenticationProvider).isAdmin) {
              AutoRouter.of(context).push(const ChangePasswordRoute());
            } else {
              ref.watch(backupProvider.notifier).resumeBackup();
              AutoRouter.of(context).pushNamed("/tab-controller-page");
            }
          } else {
            ImmichToast.show(
              context: context,
              msg:
                oauth2Login ? "Error logging you in, check url and make sure OAuth2 is enabled"
                  : "Error logging you in, check server url, email and password!",
              toastType: ToastType.error,
            );
          }
        },
        child: Text(
          oauth2Login ? "OAuth2 Login" : "Login",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ));
  }
}
