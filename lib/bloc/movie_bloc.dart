import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/movie.dart';
import '../services/atmovies_service.dart';

// Events
abstract class MovieEvent {}

class FetchNowPlaying extends MovieEvent {
  final Completer<void>? completer;
  FetchNowPlaying({this.completer});
}

class FetchComingSoon extends MovieEvent {
  final Completer<void>? completer;
  FetchComingSoon({this.completer});
}

class LoadMovieDetail extends MovieEvent {
  final int index;
  final Movie movie;
  final bool isComingSoon;
  LoadMovieDetail(this.index, this.movie, {this.isComingSoon = false});
}

// States
abstract class MovieState {}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieLoaded extends MovieState {
  final List<Movie> movies;
  final List<Movie> comingSoon;

  MovieLoaded({
    required this.movies,
    this.comingSoon = const [],
  });

  MovieLoaded copyWith({
    List<Movie>? movies,
    List<Movie>? comingSoon,
  }) {
    return MovieLoaded(
      movies: movies ?? this.movies,
      comingSoon: comingSoon ?? this.comingSoon,
    );
  }

  MovieLoaded copyWithMovie(int index, Movie movie, {bool isComingSoon = false}) {
    if (isComingSoon) {
      final updated = List<Movie>.from(comingSoon);
      if (index < updated.length) {
        updated[index] = movie;
      }
      return copyWith(comingSoon: updated);
    } else {
      final updated = List<Movie>.from(movies);
      if (index < updated.length) {
        updated[index] = movie;
      }
      return copyWith(movies: updated);
    }
  }
}

class MovieError extends MovieState {
  final String message;
  MovieError(this.message);
}

// BLoC
class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final AtmoviesService _service;

  MovieBloc(this._service) : super(MovieInitial()) {
    on<FetchNowPlaying>(_onFetchNowPlaying);
    on<FetchComingSoon>(_onFetchComingSoon);
    on<LoadMovieDetail>(_onLoadMovieDetail);
  }

  Future<void> _onFetchNowPlaying(
    FetchNowPlaying event,
    Emitter<MovieState> emit,
  ) async {
    debugPrint('🔄 [MovieBloc] 收到下拉刷新事件，準備重新抓取資料...');
    final currentComingSoon = state is MovieLoaded ? (state as MovieLoaded).comingSoon : <Movie>[];
    emit(MovieLoading());
    try {
      final movies = await _service.getNowPlaying();
      debugPrint('✅ [MovieBloc] 成功從遠端取得 ${movies.length} 部最新上映電影！');
      emit(MovieLoaded(movies: movies, comingSoon: currentComingSoon));
    } catch (e) {
      debugPrint('❌ [MovieBloc] 抓取資料失敗: $e');
      emit(MovieError(e.toString()));
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onFetchComingSoon(
    FetchComingSoon event,
    Emitter<MovieState> emit,
  ) async {
    debugPrint('🔄 [MovieBloc] 抓取即將上映電影...');
    // 不論先前是否有資料，進入即將上映頁面時都顯示 Loading 以提供更好的反饋
    final currentMovies = state is MovieLoaded ? (state as MovieLoaded).movies : <Movie>[];
    emit(MovieLoading());
    try {
      final comingSoon = await _service.getComingSoon();
      emit(MovieLoaded(movies: currentMovies, comingSoon: comingSoon));
    } catch (e) {
      debugPrint('❌ [MovieBloc] 抓取即將上映失敗: $e');
      emit(MovieError(e.toString()));
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onLoadMovieDetail(
    LoadMovieDetail event,
    Emitter<MovieState> emit,
  ) async {
    if (state is MovieLoaded) {
      try {
        final detailed = await _service.getMovieDetail(event.movie);
        emit((state as MovieLoaded).copyWithMovie(
          event.index, 
          detailed, 
          isComingSoon: event.isComingSoon,
        ),);
      } catch (_) {
        // keep current state
      }
    }
  }
}
