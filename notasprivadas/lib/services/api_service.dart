import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://172.16.10.31:31139/', // ← puerto correcto
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  Future<List<dynamic>> getNotes(String userId) async {
    final res = await _dio.get('/notes', queryParameters: {'userId': userId});
    return res.data;
  }

  Future<Map<String, dynamic>> insertNote(Map<String, dynamic> note) async {
    final res = await _dio.post('/notes', data: note);
    return res.data;
  }

  Future<void> updateNote(int id, Map<String, dynamic> note) async {
    await _dio.put('/notes/$id', data: note);
  }

  Future<Map<String, dynamic>> togglePin(int id, String userId) async {
    final res = await _dio.patch('/notes/$id/pin', data: {'userId': userId});
    return res.data;
  }

  Future<void> deleteNote(int id, String userId) async {
    await _dio.delete('/notes/$id', queryParameters: {'userId': userId});
  }
}
