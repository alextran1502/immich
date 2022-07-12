import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/modules/login/providers/authentication.provider.dart';
import 'package:immich_mobile/routing/router.dart';

import 'package:immich_mobile/shared/providers/asset.provider.dart';
import 'package:immich_mobile/shared/providers/websocket.provider.dart';

class ChangePasswordForm extends HookConsumerWidget {
  const ChangePasswordForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController =
        useTextEditingController.fromValue(TextEditingValue.empty);
    final confirmPasswordController =
        useTextEditingController.fromValue(TextEditingValue.empty);
    final authState = ref.watch(authenticationProvider);
    final formKey = GlobalKey<FormState>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Hi ${authState.firstName} ${authState.lastName},\n\nThis is either the first time you are signing into the system or a request has been made to change your password. Please enter the new password below.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    PasswordInput(controller: passwordController),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ConfirmPasswordInput(
                        originalController: passwordController,
                        confirmController: confirmPasswordController,
                      ),
                    ),
                    ChangePasswordButton(
                      passwordController: passwordController,
                      formKey: formKey,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
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
        labelText: 'New Password',
        border: OutlineInputBorder(),
        hintText: 'New Password',
      ),
    );
  }
}

class ConfirmPasswordInput extends StatelessWidget {
  final TextEditingController originalController;
  final TextEditingController confirmController;

  const ConfirmPasswordInput({
    Key? key,
    required this.originalController,
    required this.confirmController,
  }) : super(key: key);

  String? _validateInput(String? email) {
    if (confirmController.value != originalController.value) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: true,
      controller: confirmController,
      decoration: const InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter New Password',
        border: OutlineInputBorder(),
      ),
      validator: _validateInput,
      autovalidateMode: AutovalidateMode.always,
    );
  }
}

class ChangePasswordButton extends ConsumerWidget {
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  const ChangePasswordButton({
    Key? key,
    required this.passwordController,
    required this.formKey,
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
          if (formKey.currentState!.validate()) {
            var isSuccess = await ref
                .watch(authenticationProvider.notifier)
                .changePassword(passwordController.value.text);

            if (isSuccess) {
              bool res =
                  await ref.watch(authenticationProvider.notifier).logout();

              if (res) {
                ref.watch(backupProvider.notifier).cancelBackup();
                ref.watch(assetProvider.notifier).clearAllAsset();
                ref.watch(websocketProvider.notifier).disconnect();
                GoRouter.of(context).goNamed('${ImmichRoute.login}');
              }
            }
          }
        },
        child: const Text(
          "Change Password",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ));
  }
}
