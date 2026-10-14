import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/theme/app_theme.dart';
import 'package:market_list/features/export/presentation/cubit/share_cubit.dart';
import 'package:market_list/features/export/presentation/cubit/share_state.dart';
import 'package:market_list/features/export/presentation/widgets/share_sheet.dart';

class MockShareCubit extends MockCubit<ShareState> implements ShareCubit {}

void main() {
  late MockShareCubit mockShareCubit;

  setUp(() {
    mockShareCubit = MockShareCubit();
  });

  Widget createWidget({
    double textScale = 1.0,
    Size size = const Size(400, 800),
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: BlocProvider<ShareCubit>.value(
            value: mockShareCubit,
            child: const ShareBottomSheet(listId: 'list-123'),
          ),
        ),
      ),
    );
  }

  group('ShareBottomSheet', () {
    testWidgets('FR-070 renders options and triggers sharePdf when tapped', (tester) async {
      when(() => mockShareCubit.state).thenReturn(const ShareState(status: ShareStatus.idle));
      when(() => mockShareCubit.sharePdf('list-123')).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      expect(find.text('Share list'), findsOneWidget);
      expect(find.text('Share as PDF'), findsOneWidget);
      expect(find.text('Share as text'), findsOneWidget);

      await tester.tap(find.text('Share as PDF'));
      await tester.pump();

      verify(() => mockShareCubit.sharePdf('list-123')).called(1);
    });

    testWidgets('FR-071 triggers shareText when tapped', (tester) async {
      when(() => mockShareCubit.state).thenReturn(const ShareState(status: ShareStatus.idle));
      when(() => mockShareCubit.shareText('list-123')).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Share as text'));
      await tester.pump();

      verify(() => mockShareCubit.shareText('list-123')).called(1);
    });

    testWidgets('FR-070 shows progress and disables options when working', (tester) async {
      when(() => mockShareCubit.state).thenReturn(const ShareState(status: ShareStatus.working));

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      for (final tile in listTiles) {
        expect(tile.enabled, isFalse);
      }
    });

    testWidgets('FR-070 closes sheet when status is done', (tester) async {
      final controller = StreamController<ShareState>.broadcast();
      addTearDown(controller.close);

      when(() => mockShareCubit.state).thenReturn(const ShareState(status: ShareStatus.idle));
      when(() => mockShareCubit.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => BlocProvider<ShareCubit>.value(
                        value: mockShareCubit,
                        child: const ShareBottomSheet(listId: 'list-123'),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Share list'), findsOneWidget);

      controller.add(const ShareState(status: ShareStatus.done));
      await tester.pumpAndSettle();

      expect(find.text('Share list'), findsNothing);
    });

    testWidgets('FR-070 shows SnackBar and closes sheet when message is present', (tester) async {
      final controller = StreamController<ShareState>.broadcast();
      addTearDown(controller.close);

      when(() => mockShareCubit.state).thenReturn(const ShareState(status: ShareStatus.idle));
      when(() => mockShareCubit.stream).thenAnswer((_) => controller.stream);
      when(() => mockShareCubit.messageHandled()).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => BlocProvider<ShareCubit>.value(
                        value: mockShareCubit,
                        child: const ShareBottomSheet(listId: 'list-123'),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Share list'), findsOneWidget);

      const failureState = ShareState(
        status: ShareStatus.failure,
        message: 'Could not create the PDF. Try again.',
      );
      when(() => mockShareCubit.state).thenReturn(failureState);
      controller.add(failureState);
      await tester.pumpAndSettle();

      expect(find.text('Share list'), findsNothing);
      expect(find.text('Could not create the PDF. Try again.'), findsOneWidget);
      verify(() => mockShareCubit.messageHandled()).called(1);
    });

    testWidgets('NFR-009/NFR-011 renders without overflow at small screen and 2.0 text scale', (tester) async {
      when(() => mockShareCubit.state).thenReturn(const ShareState(status: ShareStatus.idle));

      await tester.pumpWidget(createWidget(
        size: const Size(320, 568),
        textScale: 2.0,
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Share list'), findsOneWidget);
    });
  });
}
