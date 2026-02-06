import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_reader/app/app.dart';
import 'package:flutter_reader/app/router.dart';
import 'package:flutter_reader/ui/dialogs/add_subscription_dialog.dart';

void main() {
  testWidgets('AddSubscriptionDialog barrier dismiss should not throw', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final errors = <FlutterErrorDetails>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (context, state) {
            return Scaffold(
              body: Center(
                child: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      key: const Key('open_add_subscription_dialog'),
                      onPressed: () async {
                        await showAddSubscriptionDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const App(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('open_add_subscription_dialog')));
    await tester.pump(); // start route push animation
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(AlertDialog), findsOneWidget);

    // Dismiss quickly by tapping outside the dialog (i.e. the modal barrier),
    // to simulate the crashy scenario.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(); // start pop animation
    await tester.pump(
      const Duration(milliseconds: 400),
    ); // finish pop animation
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    expect(errors, isEmpty);
  });
}
