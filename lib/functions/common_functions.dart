import 'dart:math';

String generateRandomString(int length, bool isOnlyNumeric) {
  final rand = Random();

  if (isOnlyNumeric) {
    final codeUnits = List.generate(
      length,
      (index) => rand.nextInt(10).toString(), // 0から9までのランダムな数字を生成
    );

    return codeUnits.join(); // codeUnitsを文字列に変換
  } else {
    const _randomChars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const _charsLength = _randomChars.length;

    final codeUnits = List.generate(
      length,
      (index) =>
          _randomChars[rand.nextInt(_charsLength)], // _randomCharsからランダムに文字を選ぶ
    );

    return codeUnits.join();
  }
}
