import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashly/theme/app_theme_variant.dart';
import 'package:cashly/theme/custom_theme.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/app_segmented_control.dart';
import 'package:cashly/theme/widgets/app_list_row.dart';

Widget _host(AppThemeVariant v, Widget child) => MaterialApp(
      theme: CustomTheme.build(v),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  for (final v in AppThemeVariant.values) {
    testWidgets('components render in $v', (tester) async {
      await tester.pumpWidget(
        _host(
          v,
          Column(
            children: [
              const GlassCard(child: Text('card')),
              PrimaryPillButton(label: 'Save', onPressed: () {}),
              const AmountText(
                amount: 12.5,
                currency: '€',
                isExpense: true,
                signed: true,
              ),
              AppSegmentedControl<bool>(
                segments: const [
                  (value: true, label: 'A', icon: null),
                  (value: false, label: 'B', icon: null),
                ],
                selected: true,
                onChanged: (_) {},
              ),
              const AppListRow(title: 'Row', subtitle: 'sub'),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Save'), findsOneWidget);
    });
  }
}
