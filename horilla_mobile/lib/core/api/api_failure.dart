/// Every failure the UI branches on, named.
///
/// Widgets never see a DioException or a raw status code. The interceptor
/// stack maps everything into one of these at the boundary, so a screen can
/// switch on a case rather than guess what 400 meant this time.
///
/// Several cases exist because the Horilla backend has distinct failure modes
/// that all surface as the same HTTP status, and the sign-in screen has to
/// explain them in words a person can act on:
///
/// * [ApiThrottled] and [ApiLockedOut] are both 429 -- one is the request
///   rate limiter, the other is django-axes locking the account after five
///   bad passwords. "Slow down" and "your account is locked" are not the
///   same message.
/// * [ApiNoCompany] is a 403 meaning the account has no company assigned, so
///   the API refuses everything. It is unrecoverable by the user and needs to
///   say so rather than looking like a password problem.
library;

sealed class ApiFailure implements Exception {
  const ApiFailure(this.message);

  /// Safe to show a user as-is.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No usable connection, DNS failure, or the host never answered.
final class ApiNetwork extends ApiFailure {
  const ApiNetwork([super.message = 'No connection.']);
}

/// The connection was made but the server did not answer in time.
final class ApiTimeout extends ApiFailure {
  const ApiTimeout([super.message = 'The server took too long to respond.']);
}

/// TLS could not be established or verified.
final class ApiTls extends ApiFailure {
  const ApiTls([super.message = 'The secure connection could not be verified.']);
}

/// 401. Credentials are wrong, or the session is over and refresh failed.
final class ApiUnauthenticated extends ApiFailure {
  const ApiUnauthenticated([super.message = 'Please sign in again.']);
}

/// 403. Authenticated, but not permitted.
final class ApiForbidden extends ApiFailure {
  const ApiForbidden([super.message = "You don't have access to that."]);
}

/// 403 with the backend's "not assigned to a company" signal. Distinct because
/// the user cannot fix it -- an administrator has to.
final class ApiNoCompany extends ApiFailure {
  const ApiNoCompany([
    super.message =
        'This account is not assigned to a company. Ask your HR admin to set one.',
  ]);
}

/// 404.
final class ApiNotFound extends ApiFailure {
  const ApiNotFound([super.message = 'That is no longer available.']);
}

/// 400 with field errors, as DRF returns them: {"field": ["problem", ...]}.
final class ApiValidation extends ApiFailure {
  const ApiValidation(this.fieldErrors, [super.message = 'Please check the form.']);

  final Map<String, List<String>> fieldErrors;

  /// First problem reported for [field], if any.
  String? forField(String field) {
    final errors = fieldErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }
}

/// 429 from the rate limiter. [retryAfter] is the server's hint, when given.
final class ApiThrottled extends ApiFailure {
  const ApiThrottled({
    this.retryAfter,
    String message = 'Too many requests. Try again shortly.',
  }) : super(message);

  final Duration? retryAfter;
}

/// 429 from django-axes: the account is locked after repeated bad passwords.
final class ApiLockedOut extends ApiFailure {
  const ApiLockedOut([
    super.message = 'Too many failed sign-in attempts. Try again later.',
  ]);
}

/// The host answered, but is not a Horilla server, or is too old to talk to.
final class ApiIncompatibleServer extends ApiFailure {
  const ApiIncompatibleServer([
    super.message = "This doesn't look like a Horilla server.",
  ]);
}

/// 5xx.
final class ApiServer extends ApiFailure {
  const ApiServer([super.message = 'The server had a problem. Try again.']);
}

/// Anything unrecognised. Kept so the UI always has a case to fall into.
final class ApiUnknown extends ApiFailure {
  const ApiUnknown([super.message = 'Something went wrong.']);
}
