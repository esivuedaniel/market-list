import 'package:equatable/equatable.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';

class PdfDocumentData extends Equatable {
  const PdfDocumentData({
    required this.listDetail,
  });

  final ListDetail listDetail;

  @override
  List<Object?> get props => [listDetail];
}
