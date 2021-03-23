import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class TusdClient {
  static const tusVersion = '1.0.0';

  final String uploadToken;

  final Uri uri;

  final File file;

  final Map<String, String> headers;

  final Map<String, dynamic> metadata;

  final int maxChunkSize;

  late http.Client _client;

  late Uri _uploadUrl;

  int _fileSize = 0;

  int _offset = 0;

  int get fileSize => _fileSize;

  TusdClient({
    required this.uri, 
    required this.file, 
    required this.uploadToken, 
    required this.headers, 
    this.metadata = const {},
    this.maxChunkSize = 512 * 1024}) {
    _client = http.Client();
    _uploadUrl = uri;
  }

  Future prepare() async {
    _fileSize = await file.length();

    String generateMetadata() {
      final meta = Map<String, dynamic>.from(metadata);
      if (meta.isEmpty) {
        meta.addAll({
          'filename': basename(file.path),
          'upload-token': uploadToken,
        });
      }
      return meta.entries
        .map((entry) => entry.key + ' ' + base64.encode(utf8.encode(entry.value)))
        .join(',');
    };

    final createHeaders = Map<String, String>.from(headers)
      ..addAll({
        'Tus-Resumable': tusVersion,
        'Upload-Length': _fileSize.toString(),
        'Upload-Metadata': generateMetadata(),
      });

    final response = await _client.post(uri, headers: createHeaders);
    if (response.statusCode >= 300) {
      print(response.body);
      throw Exception('Encountered unexpected status code ${response.statusCode}');
    }
    _uploadUrl = Uri.parse(response.headers['location']!);
  }

  Future upload({
    required Function(double) onProgress,
    required Function() onComplete,
  }) async {
    if (_fileSize == 0) {
      throw Exception('Must call prepare() before upload()');
    }

    _offset = await _getOffset();

    while (_offset < _fileSize) {
      final uploadHeaders = Map<String, String>.from(headers)
        ..addAll({
          'tus-resumable': tusVersion,
          'upload-offset': '$_offset',
          HttpHeaders.contentTypeHeader: 'application/offset+octet-stream'
        });

      final uploadResponse = await _client.patch(
        _uploadUrl,
        headers: uploadHeaders,
        body: await _getFileData(),
      );

      if (uploadResponse.statusCode != 204) {
        throw Exception('Unexpected status code. ${uploadResponse.statusCode}');
      }

      final serverOffset = _parseOffset(uploadResponse.headers['upload-offset']);
      if (serverOffset == null) {

      }
      if (serverOffset != _offset) {
        throw Exception('Server offset was different.');
      }

      onProgress(_offset / fileSize);
    }
    if (_offset == _fileSize) {
      onComplete();
    }
  }

  /// Get data from file to upload
  Future<Uint8List> _getFileData() async {
    /*final start = _offset;
    var end = _offset + maxChunkSize;
    end = end > _fileSize ? _fileSize : end;
    final fileChunk = await file.openRead(start, end).first;

    final bytesRead = min(maxChunkSize, fileChunk.length);
    _offset += bytesRead;
    return fileChunk;*/
    var end = _offset + maxChunkSize;
    end = end > _fileSize ? _fileSize : end;
    final raf = file.openSync(mode: FileMode.read)..setPositionSync(_offset);
    final data = raf.readSync(end - _offset);
    _offset += min(maxChunkSize, data.lengthInBytes);
    return data;
  }

  int? _parseOffset(String? offset) {
    if (offset?.contains(',') ?? false) {
      offset = offset!.substring(0, offset.indexOf(','));
    }
    return int.tryParse(offset ?? '');
  }

  /// Get the offset from server
  Future<int> _getOffset() async {
    final offsetHeaders = Map<String, String>.from(headers)
      ..addAll({
        'tus-resumable': tusVersion,
      });

    final response = await _client.head(_uploadUrl, headers: offsetHeaders);

    if (response.statusCode != 204) {

    }

    return int.tryParse(response.headers['upload-offset'] ?? '0') ?? 0;
  }
}
