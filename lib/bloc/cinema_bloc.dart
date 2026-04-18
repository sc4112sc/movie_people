import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';
import '../services/atmovies_service.dart';

// Events
abstract class CinemaEvent {}

class FetchCinemas extends CinemaEvent {
  final Movie movie;
  final String regionCode;
  FetchCinemas(this.movie, {this.regionCode = 'a02'});
}

class ChangeRegion extends CinemaEvent {
  final Movie movie;
  final String regionCode;
  ChangeRegion(this.movie, this.regionCode);
}

// States
abstract class CinemaState {}

class CinemaInitial extends CinemaState {}

class CinemaLoading extends CinemaState {}

class CinemaLoaded extends CinemaState {
  final Map<Cinema, List<Showtime>> cinemaShowtimes;
  final String currentRegion;

  CinemaLoaded({
    required this.cinemaShowtimes,
    required this.currentRegion,
  });
}

class CinemaError extends CinemaState {
  final String message;
  CinemaError(this.message);
}

// BLoC
class CinemaBloc extends Bloc<CinemaEvent, CinemaState> {
  final AtmoviesService _service;

  CinemaBloc(this._service) : super(CinemaInitial()) {
    on<FetchCinemas>(_onFetchCinemas);
    on<ChangeRegion>(_onChangeRegion);
  }

  Future<void> _onFetchCinemas(
    FetchCinemas event,
    Emitter<CinemaState> emit,
  ) async {
    emit(CinemaLoading());
    try {
      final data = await _service.getShowtimes(
        movie: event.movie,
        regionCode: event.regionCode,
      );
      emit(CinemaLoaded(
        cinemaShowtimes: data,
        currentRegion: event.regionCode,
      ));
    } catch (e) {
      emit(CinemaError(e.toString()));
    }
  }

  Future<void> _onChangeRegion(
    ChangeRegion event,
    Emitter<CinemaState> emit,
  ) async {
    emit(CinemaLoading());
    try {
      final data = await _service.getShowtimes(
        movie: event.movie,
        regionCode: event.regionCode,
      );
      emit(CinemaLoaded(
        cinemaShowtimes: data,
        currentRegion: event.regionCode,
      ));
    } catch (e) {
      emit(CinemaError(e.toString()));
    }
  }
}
