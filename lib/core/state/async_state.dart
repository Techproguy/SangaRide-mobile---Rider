sealed class AsyncState<T> {
  const AsyncState();
}

class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

class AsyncSuccess<T> extends AsyncState<T> {
  final T data;

  const AsyncSuccess(this.data);
}

class AsyncError<T> extends AsyncState<T> {
  final AppError error;

  const AsyncError(this.error);
}

extension AsyncStateX<T> on AsyncState<T> {
  bool get isInitial => this is AsyncInitial<T>;

  bool get isLoading => this is AsyncLoading<T>;

  bool get isSuccess => this is AsyncSuccess<T>;

  bool get isError => this is AsyncError<T>;

  T? get dataOrNull => this is AsyncSuccess<T> ? (this as AsyncSuccess<T>).data : null;

  AppError? get errorOrNull => this is AsyncError<T> ? (this as AsyncError<T>).error : null;
}

class AppError {
  final String code;
  final String message;
  final StackTrace? stackTrace;

  const AppError({required this.code, required this.message, this.stackTrace});

  @override
  String toString() => '[$code] $message';
}
