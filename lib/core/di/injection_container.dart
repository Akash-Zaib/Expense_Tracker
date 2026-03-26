import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/signup_with_email.dart';
import '../../features/auth/presentation/store/auth_store.dart';
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

  // External - Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Features - Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => FirebaseAuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => LoginWithEmail(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => SignupWithEmail(sl()));
  sl.registerFactory(
    () => AuthStore(
      signupWithEmail: sl(),
      loginWithEmail: sl(),
      logoutUsecase: sl(),
    ),
  );

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
