import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/export/domain/usecases/build_list_pdf.dart';
import 'package:market_list/features/export/domain/usecases/build_list_text.dart';
import 'package:market_list/features/export/domain/usecases/share_file.dart';
import 'package:market_list/features/export/domain/usecases/share_text.dart';
import 'package:market_list/features/export/presentation/cubit/share_state.dart';

class ShareCubit extends Cubit<ShareState> {
  ShareCubit({
    required BuildListPdf buildListPdf,
    required BuildListText buildListText,
    required ShareFile shareFile,
    required ShareText shareText,
  })  : _buildListPdf = buildListPdf,
        _buildListText = buildListText,
        _shareFile = shareFile,
        _shareText = shareText,
        super(const ShareState());

  final BuildListPdf _buildListPdf;
  final BuildListText _buildListText;
  final ShareFile _shareFile;
  final ShareText _shareText;

  Future<void> sharePdf(String listId) async {
    emit(state.copyWith(status: ShareStatus.working, clearMessage: true));

    final buildResult = await _buildListPdf(listId);
    if (isClosed) return;

    await buildResult.fold(
      (failure) async {
        emit(state.copyWith(
          status: ShareStatus.failure,
          message: _mapFailure(failure),
        ));
      },
      (file) async {
        final listTitle = file.listName ?? file.fileName;
        final shareResult = await _shareFile(ShareFileParams(
          path: file.filePath,
          subject: listTitle,
          text: 'Shopping list: $listTitle',
        ));
        if (isClosed) return;

        shareResult.fold(
          (failure) {
            emit(state.copyWith(
              status: ShareStatus.failure,
              message: _mapFailure(failure),
            ));
          },
          (outcome) {
            emit(state.copyWith(status: ShareStatus.done, clearMessage: true));
            if (!isClosed) {
              emit(state.copyWith(status: ShareStatus.idle));
            }
          },
        );
      },
    );
  }

  Future<void> shareText(String listId) async {
    emit(state.copyWith(status: ShareStatus.working, clearMessage: true));

    final buildResult = await _buildListText(listId);
    if (isClosed) return;

    await buildResult.fold(
      (failure) async {
        emit(state.copyWith(
          status: ShareStatus.failure,
          message: _mapFailure(failure),
        ));
      },
      (text) async {
        final shareResult = await _shareText(text);
        if (isClosed) return;

        shareResult.fold(
          (failure) {
            emit(state.copyWith(
              status: ShareStatus.failure,
              message: _mapFailure(failure),
            ));
          },
          (outcome) {
            emit(state.copyWith(status: ShareStatus.done, clearMessage: true));
            if (!isClosed) {
              emit(state.copyWith(status: ShareStatus.idle));
            }
          },
        );
      },
    );
  }

  void messageHandled() {
    emit(state.copyWith(
      status: state.status == ShareStatus.failure ? ShareStatus.idle : state.status,
      clearMessage: true,
    ));
  }

  String _mapFailure(Failure failure) {
    if (failure is StorageFullFailure) {
      return FailureMessages.storageFullPdf;
    }
    if (failure is ExportFailure) {
      return FailureMessages.pdfBuildFailed;
    }
    if (failure is ShareFailure) {
      return FailureMessages.shareSheetFailed;
    }
    return FailureMessages.mapFailureToMessage(failure);
  }
}
