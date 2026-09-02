import 'package:flutter_test/flutter_test.dart';
import 'package:cashly/theme/app_glass.dart';

void main() {
  test('ethereal has blur, obsidian is flat', () {
    expect(AppGlass.ethereal.blurSigma, greaterThan(0));
    expect(AppGlass.obsidian.blurSigma, 0);
  });

  test('lerp returns an AppGlass', () {
    final a = AppGlass.ethereal;
    final b = AppGlass.obsidian;
    final mid = a.lerp(b, 0.5);
    expect(mid, isA<AppGlass>());
  });
}
