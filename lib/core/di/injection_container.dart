import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firestore_user_scope.dart';
import '../firebase/current_user_context.dart';
import '../firebase/users_directory_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/signup_with_email.dart';
import '../../features/auth/presentation/store/auth_store.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_user_profile.dart';
import '../../features/settings/domain/usecases/save_user_profile.dart';
import '../../features/settings/presentation/store/settings_store.dart';
import '../../features/expense/data/datasources/expense_remote_data_source.dart';
import '../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/expense/domain/usecases/add_transaction.dart';
import '../../features/expense/domain/usecases/get_transactions.dart';
import '../../features/expense/domain/usecases/update_paid_to.dart';
import '../../features/expense/presentation/store/transactions_store.dart';
import '../../features/banks/data/datasources/banks_local_data_source.dart';
import '../../features/banks/data/datasources/banks_remote_data_source.dart';
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
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<UsersDirectoryDataSource>(
    () => UsersDirectoryDataSource(sl()),
  );
  sl.registerLazySingleton<CurrentUserContext>(
    () => CurrentUserContext(auth: sl(), usersDirectory: sl()),
  );
  sl.registerLazySingleton<FirestoreUserScope>(
    () => FirestoreUserScope(firestore: sl(), auth: sl()),
  );

  // Features - Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => FirebaseAuthRemoteDataSourceImpl(sl(), sl()),
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
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => GetUserProfile(sl()));
  sl.registerLazySingleton(() => SaveUserProfile(sl()));
  sl.registerFactory(
    () => SettingsStore(getUserProfile: sl(), saveUserProfile: sl()),
  );

  // Features - Transactions (shared between Home/Analytics)
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => UpdatePaidTo(sl()));
  sl.registerLazySingleton<TransactionsStore>(
    () => TransactionsStore(
      getTransactions: sl(),
      addTransaction: sl(),
      updatePaidTo: sl(),
    ),
  );

  // Features - Banks
  sl.registerLazySingleton<BanksLocalDataSource>(
    () => BanksLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BanksRemoteDataSource>(
    () => BanksRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BanksRepository>(
    () => BanksRepositoryImpl(sl(), sl()),
  );
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
