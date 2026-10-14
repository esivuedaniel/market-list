import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/export/domain/entities/exported_file.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';
import 'package:market_list/features/export/domain/usecases/build_list_pdf.dart';
import 'package:market_list/features/export/domain/usecases/build_list_text.dart';
import 'package:market_list/features/export/domain/usecases/share_file.dart';
import 'package:market_list/features/export/domain/usecases/share_text.dart';
import 'package:market_list/features/export/presentation/cubit/share_cubit.dart';
import 'package:market_list/features/export/presentation/cubit/share_state.dart';

class MockBuildListPdf extends Mock implements BuildListPdf {}
class MockBuildListText extends Mock implements BuildListText {}
class MockShareFile extends Mock implements ShareFile {}
class MockShareText extends Mock implements ShareText {}

void main() {
  late MockBuildListPdf mockBuildListPdf;
  late MockBuildListText mockBuildListText;
  late MockShareFile mockShareFile;
  late MockShareText mockShareText;

  setUpAll(() {
    registerFallbackValue(const ShareFileParams(
      path: 'fallback',
      subject: 'fallback',
    ));
  });

  setUp(() {
    mockBuildListPdf = MockBuildListPdf();
    mockBuildListText = MockBuildListText();
    mockShareFile = MockShareFile();
    mockShareText = MockShareText();
  });

  ShareCubit buildCubit() => ShareCubit(
        buildListPdf: mockBuildListPdf,
        buildListText: mockBuildListText,
        shareFile: mockShareFile,
        shareText: mockShareText,
      );

  const testFile = ExportedFile(
    filePath: '/exports/Sunday-market-20261014.pdf',
    fileName: 'Sunday-market-20261014.pdf',
    listName: 'Sunday market',
  );

  group('ShareCubit', () {
    test('initial state has idle status and no message', () {
      expect(buildCubit().state, const ShareState());
    });

    blocTest<ShareCubit, ShareState>(
      'FR-070 sharePdf success goes to working, done, then idle',
      build: () {
        when(() => mockBuildListPdf('l1'))
            .thenAnswer((_) async => const Right(testFile));
        when(() => mockShareFile(any()))
            .thenAnswer((_) async => const Right(ShareOutcome.success));
        return buildCubit();
      },
      act: (cubit) => cubit.sharePdf('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(status: ShareStatus.done),
        const ShareState(status: ShareStatus.idle),
      ],
      verify: (_) {
        verify(() => mockBuildListPdf('l1')).called(1);
        verify(() => mockShareFile(const ShareFileParams(
              path: '/exports/Sunday-market-20261014.pdf',
              subject: 'Sunday market',
              text: 'Shopping list: Sunday market',
            ))).called(1);
      },
    );

    blocTest<ShareCubit, ShareState>(
      'FR-070 sharePdf dismissed is not an error and returns to idle',
      build: () {
        when(() => mockBuildListPdf('l1'))
            .thenAnswer((_) async => const Right(testFile));
        when(() => mockShareFile(any()))
            .thenAnswer((_) async => const Right(ShareOutcome.dismissed));
        return buildCubit();
      },
      act: (cubit) => cubit.sharePdf('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(status: ShareStatus.done),
        const ShareState(status: ShareStatus.idle),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'FR-072 sharePdf on empty list emits failure with validation message',
      build: () {
        when(() => mockBuildListPdf('l1'))
            .thenAnswer((_) async => const Left(ValidationFailure('Cannot export an empty list.')));
        return buildCubit();
      },
      act: (cubit) => cubit.sharePdf('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(
          status: ShareStatus.failure,
          message: 'Cannot export an empty list.',
        ),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'FR-073 sharePdf on ExportFailure emits failure with pdfBuildFailed',
      build: () {
        when(() => mockBuildListPdf('l1'))
            .thenAnswer((_) async => const Left(ExportFailure()));
        return buildCubit();
      },
      act: (cubit) => cubit.sharePdf('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(
          status: ShareStatus.failure,
          message: FailureMessages.pdfBuildFailed,
        ),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'FR-070 sharePdf on StorageFullFailure emits failure with storageFullPdf',
      build: () {
        when(() => mockBuildListPdf('l1'))
            .thenAnswer((_) async => const Left(StorageFullFailure()));
        return buildCubit();
      },
      act: (cubit) => cubit.sharePdf('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(
          status: ShareStatus.failure,
          message: FailureMessages.storageFullPdf,
        ),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'FR-070 sharePdf on ShareFailure emits failure with shareSheetFailed',
      build: () {
        when(() => mockBuildListPdf('l1'))
            .thenAnswer((_) async => const Right(testFile));
        when(() => mockShareFile(any()))
            .thenAnswer((_) async => const Left(ShareFailure()));
        return buildCubit();
      },
      act: (cubit) => cubit.sharePdf('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(
          status: ShareStatus.failure,
          message: FailureMessages.shareSheetFailed,
        ),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'FR-071 shareText success goes to working, done, then idle',
      build: () {
        when(() => mockBuildListText('l1'))
            .thenAnswer((_) async => const Right('Shopping list text'));
        when(() => mockShareText('Shopping list text'))
            .thenAnswer((_) async => const Right(ShareOutcome.success));
        return buildCubit();
      },
      act: (cubit) => cubit.shareText('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(status: ShareStatus.done),
        const ShareState(status: ShareStatus.idle),
      ],
      verify: (_) {
        verify(() => mockBuildListText('l1')).called(1);
        verify(() => mockShareText('Shopping list text')).called(1);
      },
    );

    blocTest<ShareCubit, ShareState>(
      'FR-071 shareText on ShareFailure emits failure with shareSheetFailed',
      build: () {
        when(() => mockBuildListText('l1'))
            .thenAnswer((_) async => const Right('Shopping list text'));
        when(() => mockShareText('Shopping list text'))
            .thenAnswer((_) async => const Left(ShareFailure()));
        return buildCubit();
      },
      act: (cubit) => cubit.shareText('l1'),
      expect: () => [
        const ShareState(status: ShareStatus.working),
        const ShareState(
          status: ShareStatus.failure,
          message: FailureMessages.shareSheetFailed,
        ),
      ],
    );

    blocTest<ShareCubit, ShareState>(
      'messageHandled clears message and resets failure to idle',
      build: () => buildCubit(),
      seed: () => const ShareState(
        status: ShareStatus.failure,
        message: 'Some error',
      ),
      act: (cubit) => cubit.messageHandled(),
      expect: () => [
        const ShareState(status: ShareStatus.idle),
      ],
    );
  });
}
