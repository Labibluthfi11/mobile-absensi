bool isAttendanceFacePhotoValidationError(Object? responseData) {
  if (responseData is! Map) return false;
  final errors = responseData['errors'];
  if (errors is! Map) return false;

  final fotoErrors = errors['foto'];
  if (fotoErrors is String) return fotoErrors.trim().isNotEmpty;
  if (fotoErrors is Iterable) {
    return fotoErrors.any((error) => error.toString().trim().isNotEmpty);
  }
  return false;
}

String? attendanceSubmissionPolicyErrorMessage(
  int? statusCode,
  Object? responseData,
) {
  if (statusCode == 503) {
    return 'Pemeriksaan wajah sedang tidak tersedia. Silakan coba lagi beberapa saat.';
  }
  if (statusCode == 422 &&
      isAttendanceFacePhotoValidationError(responseData)) {
    return 'Wajah belum terlihat jelas pada foto utama. Silakan ambil ulang foto dengan wajah di dalam area kamera.';
  }
  return null;
}
