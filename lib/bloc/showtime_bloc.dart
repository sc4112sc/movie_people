import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/showtime.dart';
import '../services/mock_showtime_service.dart';

// Events
abstract class ShowtimeEvent {}

class FetchShowtimes extends ShowtimeEvent {
  final String cinemaId;
  final int movieId;
  final DateTime date;

  FetchShowtimes({
    required this.cinemaId,
    required this.movieId,
    required this.date,
  });
}

// States
abstract class ShowtimeState {}

class ShowtimeInitial extends ShowtimeState {}

class ShowtimeLoading extends ShowtimeState {}

class ShowtimeLoaded extends ShowtimeState {
  final List<Showtime> showtimes;
  final DateTime selectedDate;

  ShowtimeLoaded({required this.showtimes, required this.selectedDate});
}

// BLoC
class ShowtimeBloc extends Bloc<ShowtimeEvent, ShowtimeState> {
  final MockShowtimeService _showtimeService;

  ShowtimeBloc(this._showtimeService) : super(ShowtimeInitial()) {
    on<FetchShowtimes>(_onFetchShowtimes);
  }

  Future<void> _onFetchShowtimes(
    FetchShowtimes event,
    Emitter<ShowtimeState> emit,
  ) async {
    emit(ShowtimeLoading());
    await Future.delayed(const Duration(milliseconds: 300));
    final showtimes = _showtimeService.getShowtimes(
      cinemaId: event.cinemaId,
      movieId: event.movieId,
      date: event.date,
    );
    emit(ShowtimeLoaded(showtimes: showtimes, selectedDate: event.date));
  }
}
