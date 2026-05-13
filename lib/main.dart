import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'pages/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'services/auth_service.dart';
import 'bloc/movie_bloc.dart';
import 'services/atmovies_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(AuthService())..add(CheckAuthStatus()),
        ),
        BlocProvider<MovieBloc>(
          create: (context) => MovieBloc(AtmoviesService()),
        ),
      ],
      child: GetMaterialApp(
        title: '電影人',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashPage(),
      ),
    );
  }
}
