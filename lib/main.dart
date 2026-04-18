import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'bloc/movie_bloc.dart';
import 'services/atmovies_service.dart';
import 'pages/movie_list_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MovieBloc(AtmoviesService())..add(FetchNowPlaying()),
        ),
      ],
      child: GetMaterialApp(
        title: '電影人',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MovieListPage(),
      ),
    );
  }
}
