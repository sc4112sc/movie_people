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

class LoadMovieDetail extends MovieEvent {
  final int index;
  final Movie movie;
  LoadMovieDetail(this.index, this.movie);
}

// States
abstract class MovieState {}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieLoaded extends MovieState {
  final List<Movie> movies;

  MovieLoaded({required this.movies});

  MovieLoaded copyWithMovie(int index, Movie movie) {
    final updated = List<Movie>.from(movies);
    if (index < updated.length) {
      updated[index] = movie;
    }
    return MovieLoaded(movies: updated);
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
    on<LoadMovieDetail>(_onLoadMovieDetail);
  }

  Future<void> _onFetchNowPlaying(
    FetchNowPlaying event,
    Emitter<MovieState> emit,
  ) async {
    print('🔄 [MovieBloc] 收到下拉刷新事件，準備重新抓取資料...');
    emit(MovieLoading());
    try {
      final movies = await _service.getNowPlaying();
      print('✅ [MovieBloc] 成功從遠端取得 ${movies.length} 部最新上映電影！');
      emit(MovieLoaded(movies: movies));
    } catch (e) {
      print('❌ [MovieBloc] 抓取資料失敗: $e');
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
        emit((state as MovieLoaded).copyWithMovie(event.index, detailed));
      } catch (_) {
        // keep current state
      }
    }
  }
}
