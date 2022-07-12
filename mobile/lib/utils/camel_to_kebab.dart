extension StringExtension on String {
  String camelTokebab() {
    return split('')
        .map((letter) => letter.toUpperCase() == letter
            ? '${indexOf(letter) != 0 ? '-' : ''}${letter.toLowerCase()}'
            : letter)
        .join('');
  }
}
