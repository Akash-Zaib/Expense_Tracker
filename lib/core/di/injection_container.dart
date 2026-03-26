import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_user_profile.dart';
import '../../features/settings/domain/usecases/save_user_profile.dart';
import '../../features/settings/presentation/store/settings_store.dart';
import '../../features/expense/presentation/store/transactions_store.dart';
import '../../features/banks/data/datasources/banks_local_data_source.dart';
import '../../features/banks/data/repositories/banks_repository_impl.dart';
import '../../features/banks/domain/repositories/banks_repository.dart';
import '../../features/banks/domain/usecases/add_bank.dart';
import '../../features/banks/domain/usecases/get_banks.dart';
import '../../features/banks/domain/usecases/remove_bank.dart';
import '../../features/banks/domain/usecases/submit_all_banks.dart';
import '../../features/banks/presentation/store/banks_store.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // Features - Settings
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetUserProfile(sl()));
  sl.registerLazySingleton(() => SaveUserProfile(sl()));
  sl.registerFactory(
    () => SettingsStore(getUserProfile: sl(), saveUserProfile: sl()),
  );

  // Features - Transactions (shared between Home/Analytics)
  sl.registerLazySingleton<TransactionsStore>(() => TransactionsStore());

  // Features - Banks
  sl.registerLazySingleton<BanksLocalDataSource>(
    () => BanksLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BanksRepository>(() => BanksRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBanks(sl()));
  sl.registerLazySingleton(() => AddBank(sl()));
  sl.registerLazySingleton(() => RemoveBank(sl()));
  sl.registerLazySingleton(() => SubmitAllBanks(sl()));
  sl.registerFactory(
    () => BanksStore(
      getBanks: sl(),
      addBank: sl(),
      removeBank: sl(),
      submitAllBanks: sl(),
    ),
  );
}
