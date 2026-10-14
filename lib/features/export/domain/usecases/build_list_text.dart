import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/formatting/date_formatter.dart';
import 'package:market_list/core/formatting/money_formatter.dart';
import 'package:market_list/core/formatting/quantity_formatter.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class BuildListText implements UseCase<String, String> {
  const BuildListText({
    required ShoppingItemRepository itemRepository,
    Clock clock = const Clock(),
  })  : _itemRepository = itemRepository,
        _clock = clock;

  final ShoppingItemRepository _itemRepository;
  final Clock _clock;

  @override
  Future<Either<Failure, String>> call(String listId) async {
    final detailResult = await _itemRepository.getListDetail(listId);
    return detailResult.fold(
      Left.new,
      (detail) {
        if (detail.items.isEmpty) {
          return const Left(ValidationFailure('Cannot export an empty list.'));
        }

        final buffer = StringBuffer();
        buffer.writeln(detail.list.name);
        buffer.writeln(DateFormatter.format(_clock.now()));
        buffer.writeln();

        for (var i = 0; i < detail.items.length; i++) {
          final item = detail.items[i];
          final index = i + 1;
          final qtyStr = QuantityFormatter.format(item.quantity);
          final priceStr = MoneyFormatter.formatAmount(item.unitPrice);
          final totalStr = MoneyFormatter.formatAmount(item.lineTotal);

          if (item.unit != null && item.unit!.isNotEmpty) {
            buffer.writeln('$index. ${item.name}, $qtyStr ${item.unit} x $priceStr = $totalStr');
          } else {
            buffer.writeln('$index. ${item.name}, $qtyStr x $priceStr = $totalStr');
          }
        }

        buffer.writeln();
        final totalFormatted = MoneyFormatter.format(detail.total, detail.list.currency);
        buffer.write('Total: $totalFormatted');

        return Right(buffer.toString());
      },
    );
  }
}
