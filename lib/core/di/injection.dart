import 'package:get_it/get_it.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/items_dao.dart';
import 'package:market_list/core/database/daos/lists_dao.dart';
import 'package:market_list/core/database/daos/settings_dao.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/platform/id_generator.dart';
import 'package:market_list/features/items/data/datasources/shopping_item_local_data_source.dart';
import 'package:market_list/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:market_list/features/items/data/repositories/shopping_item_repository_impl.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/add_item.dart';
import 'package:market_list/features/items/domain/usecases/delete_item.dart';
import 'package:market_list/features/items/domain/usecases/get_item.dart';
import 'package:market_list/features/items/domain/usecases/get_list_detail.dart';
import 'package:market_list/features/items/domain/usecases/has_duplicate_item_name.dart';
import 'package:market_list/features/items/domain/usecases/restore_item.dart';
import 'package:market_list/features/items/domain/usecases/set_item_bought.dart';
import 'package:market_list/features/items/domain/usecases/update_item.dart';
import 'package:market_list/features/items/domain/usecases/validate_item_draft.dart';
import 'package:market_list/features/items/domain/usecases/watch_list_detail.dart';
import 'package:market_list/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:market_list/features/settings/data/mappers/settings_mapper.dart';
import 'package:market_list/features/settings/data/repositories/onboarding_repository_impl.dart';
import 'package:market_list/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/router/app_router.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_bloc.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_cubit.dart';
import 'package:market_list/features/settings/domain/repositories/onboarding_repository.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:market_list/features/settings/domain/usecases/complete_onboarding.dart';
import 'package:market_list/features/settings/domain/usecases/ensure_settings.dart';
import 'package:market_list/features/settings/domain/usecases/set_default_currency.dart';
import 'package:market_list/features/settings/domain/usecases/set_theme_mode.dart';
import 'package:market_list/features/settings/domain/usecases/watch_settings.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_cubit.dart';
import 'package:market_list/features/shopping_lists/data/datasources/shopping_list_local_data_source.dart';
import 'package:market_list/features/shopping_lists/data/mappers/shopping_list_mapper.dart';
import 'package:market_list/features/shopping_lists/data/repositories/shopping_list_repository_impl.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/create_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/delete_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/duplicate_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/rename_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/set_list_currency.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/watch_lists.dart';
import 'package:market_list/features/export/data/services/pdf_list_generator.dart';
import 'package:market_list/features/export/data/services/share_plus_service.dart';
import 'package:market_list/features/export/data/services/temp_export_file_store.dart';
import 'package:market_list/features/export/domain/services/export_file_store.dart';
import 'package:market_list/features/export/domain/services/list_pdf_generator.dart';
import 'package:market_list/features/export/domain/services/share_service.dart';
import 'package:market_list/features/export/domain/usecases/build_list_pdf.dart';
import 'package:market_list/features/export/domain/usecases/build_list_text.dart';
import 'package:market_list/features/export/domain/usecases/cleanup_exports.dart';
import 'package:market_list/features/export/domain/usecases/share_file.dart';
import 'package:market_list/features/export/domain/usecases/share_text.dart';
import 'package:market_list/features/export/presentation/cubit/share_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({AppDatabase? database}) async {
  // 1. Platform
  if (!getIt.isRegistered<Clock>()) {
    getIt.registerLazySingleton<Clock>(() => const Clock());
  }
  if (!getIt.isRegistered<IdGenerator>()) {
    getIt.registerLazySingleton<IdGenerator>(() => const IdGenerator());
  }

  // 2. Database
  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());
  }
  if (!getIt.isRegistered<ListsDao>()) {
    getIt.registerLazySingleton<ListsDao>(
      () => ListsDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<ItemsDao>()) {
    getIt.registerLazySingleton<ItemsDao>(
      () => ItemsDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SettingsDao>()) {
    getIt.registerLazySingleton<SettingsDao>(
      () => SettingsDao(getIt<AppDatabase>()),
    );
  }

  // 3. Mappers
  if (!getIt.isRegistered<SettingsMapper>()) {
    getIt.registerLazySingleton<SettingsMapper>(
      () => const SettingsMapper(),
    );
  }
  if (!getIt.isRegistered<ShoppingListMapper>()) {
    getIt.registerLazySingleton<ShoppingListMapper>(
      () => const ShoppingListMapper(),
    );
  }
  if (!getIt.isRegistered<ShoppingItemMapper>()) {
    getIt.registerLazySingleton<ShoppingItemMapper>(
      () => const ShoppingItemMapper(),
    );
  }

  // 4. Data Sources
  if (!getIt.isRegistered<SettingsLocalDataSource>()) {
    getIt.registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(getIt<SettingsDao>()),
    );
  }
  if (!getIt.isRegistered<ShoppingListLocalDataSource>()) {
    getIt.registerLazySingleton<ShoppingListLocalDataSource>(
      () => ShoppingListLocalDataSourceImpl(getIt<ListsDao>()),
    );
  }
  if (!getIt.isRegistered<ShoppingItemLocalDataSource>()) {
    getIt.registerLazySingleton<ShoppingItemLocalDataSource>(
      () => ShoppingItemLocalDataSourceImpl(getIt<ItemsDao>()),
    );
  }

  // 5. Repositories
  if (!getIt.isRegistered<SettingsRepository>()) {
    getIt.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(
        dataSource: getIt<SettingsLocalDataSource>(),
        mapper: getIt<SettingsMapper>(),
      ),
    );
  }
  if (!getIt.isRegistered<OnboardingRepository>()) {
    getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(
        dataSource: getIt<SettingsLocalDataSource>(),
        idGenerator: getIt<IdGenerator>(),
        clock: getIt<Clock>(),
      ),
    );
  }
  if (!getIt.isRegistered<ShoppingListRepository>()) {
    getIt.registerLazySingleton<ShoppingListRepository>(
      () => ShoppingListRepositoryImpl(
        dataSource: getIt<ShoppingListLocalDataSource>(),
        mapper: getIt<ShoppingListMapper>(),
        idGenerator: getIt<IdGenerator>(),
        clock: getIt<Clock>(),
      ),
    );
  }
  if (!getIt.isRegistered<ShoppingItemRepository>()) {
    getIt.registerLazySingleton<ShoppingItemRepository>(
      () => ShoppingItemRepositoryImpl(
        dataSource: getIt<ShoppingItemLocalDataSource>(),
        mapper: getIt<ShoppingItemMapper>(),
        idGenerator: getIt<IdGenerator>(),
        clock: getIt<Clock>(),
      ),
    );
  }

  // 6. Settings use cases
  if (!getIt.isRegistered<EnsureSettings>()) {
    getIt.registerLazySingleton(() => EnsureSettings(getIt()));
  }
  if (!getIt.isRegistered<WatchSettings>()) {
    getIt.registerLazySingleton(() => WatchSettings(getIt()));
  }
  if (!getIt.isRegistered<SetDefaultCurrency>()) {
    getIt.registerLazySingleton(() => SetDefaultCurrency(getIt()));
  }
  if (!getIt.isRegistered<SetThemeMode>()) {
    getIt.registerLazySingleton(() => SetThemeMode(getIt()));
  }
  if (!getIt.isRegistered<CompleteOnboarding>()) {
    getIt.registerLazySingleton(() => CompleteOnboarding(getIt()));
  }

  // 7. Shopping lists use cases
  if (!getIt.isRegistered<WatchLists>()) {
    getIt.registerLazySingleton(() => WatchLists(getIt()));
  }
  if (!getIt.isRegistered<CreateList>()) {
    getIt.registerLazySingleton(() => CreateList(getIt()));
  }
  if (!getIt.isRegistered<RenameList>()) {
    getIt.registerLazySingleton(() => RenameList(getIt()));
  }
  if (!getIt.isRegistered<SetListCurrency>()) {
    getIt.registerLazySingleton(() => SetListCurrency(getIt()));
  }
  if (!getIt.isRegistered<DeleteList>()) {
    getIt.registerLazySingleton(() => DeleteList(getIt()));
  }
  if (!getIt.isRegistered<DuplicateList>()) {
    getIt.registerLazySingleton(() => DuplicateList(getIt()));
  }

  // 8. Shopping items use cases
  if (!getIt.isRegistered<WatchListDetail>()) {
    getIt.registerLazySingleton(() => WatchListDetail(getIt()));
  }
  if (!getIt.isRegistered<GetListDetail>()) {
    getIt.registerLazySingleton(() => GetListDetail(getIt()));
  }
  if (!getIt.isRegistered<GetItem>()) {
    getIt.registerLazySingleton(() => GetItem(getIt()));
  }
  if (!getIt.isRegistered<ValidateItemDraft>()) {
    getIt.registerLazySingleton(() => const ValidateItemDraft());
  }
  if (!getIt.isRegistered<AddItem>()) {
    getIt.registerLazySingleton(() => AddItem(getIt()));
  }
  if (!getIt.isRegistered<UpdateItem>()) {
    getIt.registerLazySingleton(() => UpdateItem(getIt()));
  }
  if (!getIt.isRegistered<DeleteItem>()) {
    getIt.registerLazySingleton(() => DeleteItem(getIt()));
  }
  if (!getIt.isRegistered<RestoreItem>()) {
    getIt.registerLazySingleton(() => RestoreItem(getIt()));
  }
  if (!getIt.isRegistered<SetItemBought>()) {
    getIt.registerLazySingleton(() => SetItemBought(getIt()));
  }
  if (!getIt.isRegistered<HasDuplicateItemName>()) {
    getIt.registerLazySingleton(() => HasDuplicateItemName(getIt()));
  }

  // 9. State holders
  if (!getIt.isRegistered<ListDetailBloc>()) {
    getIt.registerFactory<ListDetailBloc>(
      () => ListDetailBloc(
        watchListDetail: getIt(),
        setItemBought: getIt(),
        deleteItem: getIt(),
        restoreItem: getIt(),
        renameList: getIt(),
        setListCurrency: getIt(),
        deleteList: getIt(),
        addItem: getIt(),
      ),
    );
  }
  if (!getIt.isRegistered<ListsCubit>()) {
    getIt.registerFactory<ListsCubit>(
      () => ListsCubit(
        watchLists: getIt(),
        createList: getIt(),
        renameList: getIt(),
        setListCurrency: getIt(),
        deleteList: getIt(),
        duplicateList: getIt(),
      ),
    );
  }
  if (!getIt.isRegistered<SettingsCubit>()) {
    getIt.registerLazySingleton<SettingsCubit>(
      () => SettingsCubit(
        ensureSettings: getIt(),
        watchSettings: getIt(),
        setDefaultCurrency: getIt(),
        setThemeMode: getIt(),
        completeOnboarding: getIt(),
      ),
    );
  }
  if (!getIt.isRegistered<ItemFormCubit>()) {
    getIt.registerFactoryParam<ItemFormCubit, ItemFormArgs, void>(
      (args, _) => ItemFormCubit(
        listId: args.listId,
        itemId: args.itemId,
        initialCurrency: CurrencyCode.fromCode(args.initialCurrency),
        addItem: getIt(),
        updateItem: getIt(),
        getItem: getIt(),
        deleteItem: getIt(),
        hasDuplicateItemName: getIt(),
        validateItemDraft: getIt(),
      ),
    );
  }

  // 10. Export services and use cases
  if (!getIt.isRegistered<TempExportFileStore>()) {
    getIt.registerLazySingleton<TempExportFileStore>(
      () => TempExportFileStore(clock: getIt()),
    );
  }
  if (!getIt.isRegistered<ExportFileStore>()) {
    getIt.registerLazySingleton<ExportFileStore>(
      () => getIt<TempExportFileStore>(),
    );
  }
  if (!getIt.isRegistered<ListPdfGenerator>()) {
    getIt.registerLazySingleton<ListPdfGenerator>(
      () => PdfListGenerator(
        fileStore: getIt<TempExportFileStore>(),
        clock: getIt(),
      ),
    );
  }
  if (!getIt.isRegistered<ShareService>()) {
    getIt.registerLazySingleton<ShareService>(
      () => SharePlusService(),
    );
  }
  if (!getIt.isRegistered<BuildListPdf>()) {
    getIt.registerLazySingleton(
      () => BuildListPdf(
        itemRepository: getIt(),
        pdfGenerator: getIt(),
      ),
    );
  }
  if (!getIt.isRegistered<BuildListText>()) {
    getIt.registerLazySingleton(
      () => BuildListText(
        itemRepository: getIt(),
        clock: getIt(),
      ),
    );
  }
  if (!getIt.isRegistered<ShareFile>()) {
    getIt.registerLazySingleton(() => ShareFile(getIt()));
  }
  if (!getIt.isRegistered<ShareText>()) {
    getIt.registerLazySingleton(() => ShareText(getIt()));
  }
  if (!getIt.isRegistered<CleanupExports>()) {
    getIt.registerLazySingleton(() => CleanupExports(getIt()));
  }
  if (!getIt.isRegistered<ShareCubit>()) {
    getIt.registerFactory<ShareCubit>(
      () => ShareCubit(
        buildListPdf: getIt(),
        buildListText: getIt(),
        shareFile: getIt(),
        shareText: getIt(),
      ),
    );
  }
}
