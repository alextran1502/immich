import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
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
        useTextEditingController(text: 'login_endpoint_hint'.tr());
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
                  "login_form_save_login",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ).tr(),
                value: isSaveLoginInfo.value,
                onChanged: (switchValue) {
                  if (switchValue != null) {
                    isSaveLoginInfo.value = switchValue;
                  }
                },
              ),
              LoginButton(
                emailController: usernameController,
                passwordController: passwordController,
                serverEndpointController: serverEndpointController,
                isSavedLoginInfo: isSaveLoginInfo.value,
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
      return 'login_form_err_http'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'login_form_endpoint_url'.tr(),
        border: OutlineInputBorder(),
        hintText: 'login_form_endpoint_hint'.tr(),
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
    if (email.endsWith(' ')) return 'login_form_err_trailing_whitespace'.tr();
    if (email.startsWith(' ')) return 'login_form_err_leading_whitespace'.tr();
    if (email.contains(' ') || !email.contains('@'))
      return 'login_form_err_invalid_email'.tr();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'login_form_label_email'.tr(),
        border: OutlineInputBorder(),
        hintText: 'login_form_email_hint'.tr(),
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
      decoration: InputDecoration(
          labelText: 'login_form_label_password'.tr(),
          border: OutlineInputBorder(),
          hintText: 'login_form_password_hint'.tr()),
    );
  }
}

class LoginButton extends ConsumerWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController serverEndpointController;
  final bool isSavedLoginInfo;

  const LoginButton({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.serverEndpointController,
    required this.isSavedLoginInfo,
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
                  serverEndpointController.text, isSavedLoginInfo);

          if (isAuthenticated) {
            // Resume backup (if enable) then navigate

            if (ref.watch(authenticationProvider).shouldChangePassword &&
                !ref.watch(authenticationProvider).isAdmin) {
              GoRouter.of(context).goNamed('${ImmichRoute.changePassword}');
            } else {
              ref.watch(backupProvider.notifier).resumeBackup();
              GoRouter.of(context).goNamed("${ImmichRoute.home}");
            }
          } else {
            ImmichToast.show(
              context: context,
              msg: "login_failed".tr(),
              toastType: ToastType.error,
            );
          }
        },
        child: const Text(
          "login_form_button_text",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ).tr());
  }
}
