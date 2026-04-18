import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/movie.dart';
import '../services/atmovies_service.dart';

// Events
abstract class MovieEvent {}

class FetchNowPlaying extends MovieEvent {}

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
    emit(MovieLoading());
    try {
      final movies = await _service.getNowPlaying();
      emit(MovieLoaded(movies: movies));
    } catch (e) {
      emit(MovieError(e.toString()));
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
