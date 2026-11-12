import 'package:ecom_mobile/core/providers.dart';
import 'package:ecom_mobile/features/auth/data/models/app_user.dart';
import 'package:ecom_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:ecom_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets(
    'empty form shows required-field errors and does not call the API',
    (tester) async {
      final repo = MockAuthRepository();
      await tester.pumpWidget(
        plainApp(
          const LoginScreen(),
          overrides: [
            ...await baseOverrides(),
            authRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      verifyNever(() => repo.login(any(), any()));
    },
  );

  testWidgets('invalid email is rejected', (tester) async {
    await tester.pumpWidget(
      plainApp(
        const LoginScreen(),
        overrides: [
          ...await baseOverrides(),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
      ),
    );
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'not-an-email',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'secret');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('show / hide password toggles obscuring', (tester) async {
    await tester.pumpWidget(
      plainApp(
        const LoginScreen(),
        overrides: [
          ...await baseOverrides(),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
      ),
    );
    TextField field() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('login_password')),
        matching: find.byType(TextField),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('valid credentials call login', (tester) async {
    final repo = MockAuthRepository();
    when(
      () => repo.login(any(), any()),
    ).thenAnswer((_) async => AuthResult.fromJson(authJson));
    await tester.pumpWidget(
      plainApp(
        const LoginScreen(),
        overrides: [
          ...await baseOverrides(),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'customer@ecom.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'Customer@123',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    verify(() => repo.login('customer@ecom.com', 'Customer@123')).called(1);
  });
}
