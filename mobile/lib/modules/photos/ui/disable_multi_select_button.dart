import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DisableMultiSelectButton extends ConsumerWidget {
  const DisableMultiSelectButton({
    Key? key,
    required this.onPressed,
    required this.selectedItemCount,
  }) : super(key: key);

  final Function onPressed;
  final int selectedItemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: 0,
      left: 0,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 46),
        child: Material(
          elevation: 20,
          borderRadius: BorderRadius.circular(35),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              color: Colors.grey[100],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TextButton.icon(
                  onPressed: () {
                    onPressed();
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: Text(
                    '$selectedItemCount',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18),
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
