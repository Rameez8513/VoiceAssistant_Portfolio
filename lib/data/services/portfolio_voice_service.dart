import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../models/project_model.dart';
import '../models/service_model.dart';
import '../models/book_model.dart';
import '../models/social_model.dart';
import '../models/cv_model.dart';
import '../../core/constants/app_constants.dart';

enum VoiceState { idle, connecting, listening, speaking, processing, error }

class VoiceMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  VoiceMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class PortfolioVoiceService {
  bool _wsReady = false;
  bool _disposed = false;
  bool _sessionConfigured = false;

  html.MediaStream? _stream;
  html.AudioElement? _currentAudio;
  Timer? _audioTimer;

  final List<Uint8List> _pcmBuf = [];
  bool _isPlaying = false;

  final _stateCtrl = StreamController<VoiceState>.broadcast();
  final _msgCtrl = StreamController<VoiceMessage>.broadcast();

  Stream<VoiceState> get stateStream => _stateCtrl.stream;
  Stream<VoiceMessage> get messageStream => _msgCtrl.stream;

  VoiceState _currentState = VoiceState.idle;
  VoiceState get currentState => _currentState;

  String _apiKey = '';
  String _resourceName = '';
  String _model = '';
  String _voiceName = '';
  String _instructions = '';

  List<ProjectModel> _projects = [];
  List<ServiceModel> _services = [];
  List<BookModel> _books = [];
  List<SocialModel> _socials = [];
  CvModel? _cv;

  final List<String> _textBuffer = [];
  int _reconnectAttempts = 0;

  void _setState(VoiceState s) {
    if (_disposed) return;
    _currentState = s;
    _stateCtrl.add(s);
  }

  void _addMessage(String text, bool isUser) {
    if (_disposed) return;
    _msgCtrl.add(VoiceMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> initialize({
    required String apiKey,
    required String resourceName,
    required String model,
    required String voiceName,
    String voiceType = 'azure-standard',
    required String instructions,
    required List<ProjectModel> projects,
    required List<ServiceModel> services,
    required List<BookModel> books,
    required List<SocialModel> socials,
    CvModel? cv,
  }) async {
    if (_disposed) return;

    _apiKey = apiKey;
    _resourceName = resourceName;
    _model = model;
    _voiceName = voiceName.isEmpty ? 'en-US-AvaNeural' : voiceName;
    _instructions = instructions;
    _projects = projects;
    _services = services;
    _books = books;
    _socials = socials;
    _cv = cv;

    _setState(VoiceState.connecting);

    try {
      await _initMicrophone();
      await _connectWebSocket();
    } catch (e) {
      debugPrint('Voice init failed: $e');
      _setState(VoiceState.error);
    }
  }

  Future<void> _initMicrophone() async {
    _stream = await html.window.navigator.mediaDevices!.getUserMedia({
      'audio': {
        'channelCount': 1,
        'sampleRate': 24000,
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
    });

    _injectScripts();
    _startAudioCapture();
  }

  void _injectScripts() {
    if (html.document.getElementById('_pfScript') != null) return;

    final script = html.ScriptElement()
      ..id = '_pfScript'
      ..text = r'''
        window._pfChunks = [];
        window._pfActive = false;

        window._pfStartCapture = function(stream) {
          try {
            if (window._pfCtx) {
              try { window._pfProc.disconnect(); } catch(e) {}
              try { window._pfSrc.disconnect(); } catch(e) {}
              try { window._pfCtx.close(); } catch(e) {}
            }
            var ctx = new (window.AudioContext || window.webkitAudioContext)({sampleRate: 24000});
            window._pfCtx = ctx;
            var src = ctx.createMediaStreamSource(stream);
            window._pfSrc = src;
            var proc = ctx.createScriptProcessor(2048, 1, 1);
            window._pfProc = proc;
            window._pfChunks = [];
            window._pfActive = true;
            proc.onaudioprocess = function(e) {
              if (!window._pfActive) return;
              var d = e.inputBuffer.getChannelData(0);
              var p = new Int16Array(d.length);
              for (var i = 0; i < d.length; i++) {
                var s = Math.max(-1, Math.min(1, d[i]));
                p[i] = s < 0 ? s * 32768 : s * 32767;
              }
              var u = new Uint8Array(p.buffer);
              var b = '';
              for (var i = 0; i < u.length; i += 8192) {
                b += String.fromCharCode.apply(null, u.subarray(i, Math.min(i + 8192, u.length)));
              }
              window._pfChunks.push(btoa(b));
            };
            src.connect(proc);
            proc.connect(ctx.destination);
          } catch(err) {
            console.error('Audio capture error:', err);
          }
        };

        window._pfGetAndClear = function() {
          var c = window._pfChunks || [];
          window._pfChunks = [];
          return JSON.stringify(c);
        };

        window._pfStop = function() {
          window._pfActive = false;
          try { if (window._pfProc) window._pfProc.disconnect(); } catch(e) {}
          try { if (window._pfSrc) window._pfSrc.disconnect(); } catch(e) {}
          try { if (window._pfCtx) window._pfCtx.close(); } catch(e) {}
        };

        window._pfWSMessages = [];
        window._pfWSClosed = false;
        window._pfWSConnectResult = '';

        window._pfConnectWS = function(url) {
          return new Promise(function(resolve, reject) {
            try {
              var ws = new WebSocket(url);
              ws.binaryType = 'arraybuffer';
              ws.onopen = function() {
                window._pfWS = ws;
                window._pfWSClosed = false;
                window._pfWSMessages = [];
                resolve('ok');
              };
              ws.onerror = function(e) {
                reject('ws_error');
              };
              ws.onclose = function(e) {
                window._pfWSClosed = true;
                console.log('WS closed code:', e.code, 'reason:', e.reason);
              };
              ws.onmessage = function(e) {
                if (typeof e.data === 'string') {
                  window._pfWSMessages.push(e.data);
                }
              };
            } catch(e) {
              reject(e.toString());
            }
          });
        };

        window._pfSendWS = function(data) {
          if (window._pfWS && window._pfWS.readyState === 1) {
            window._pfWS.send(data);
            return true;
          }
          return false;
        };

        window._pfCloseWS = function() {
          if (window._pfWS) {
            try { window._pfWS.close(); } catch(e) {}
          }
        };

        window._pfGetMessages = function() {
          var m = window._pfWSMessages || [];
          window._pfWSMessages = [];
          return JSON.stringify(m);
        };

        window._pfIsWSClosed = function() {
          return window._pfWSClosed ? 'true' : 'false';
        };
      ''';
    html.document.head!.append(script);
  }

  void _startAudioCapture() {
    if (_stream == null) return;

    globalContext.setProperty(
      '_pfPendingStream'.toJS,
      _stream!.jsify()!,
    );

    final execScript = html.ScriptElement()
      ..text =
          'if (window._pfPendingStream && window._pfStartCapture) { window._pfStartCapture(window._pfPendingStream); }';
    html.document.head!.append(execScript);
  }

  void _sendCapturedAudio() {
    if (!_wsReady || _disposed || _isPlaying || !_sessionConfigured) return;

    try {
      final resultJs = globalContext.callMethod('_pfGetAndClear'.toJS);
      if (resultJs == null) return;

      String jsonStr;
      if (resultJs.isA<JSString>()) {
        jsonStr = (resultJs as JSString).toDart;
      } else {
        jsonStr = resultJs.toString();
      }

      if (jsonStr.isEmpty || jsonStr == '[]' || jsonStr == 'undefined') return;

      final List<dynamic> chunks = jsonDecode(jsonStr);
      for (final chunk in chunks) {
        if (chunk is String && chunk.isNotEmpty) {
          _sendRaw(jsonEncode({
            'type': 'input_audio_buffer.append',
            'audio': chunk,
          }));
        }
      }
    } catch (e) {
      debugPrint('Audio send error: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    if (_disposed) return;

    _sessionConfigured = false;

    final wsUrl =
        'wss://$_resourceName.cognitiveservices.azure.com/voice-live/realtime'
        '?api-version=2025-10-01'
        '&model=$_model'
        '&api-key=$_apiKey';

    if (_disposed) return;
    try {
      debugPrint('Connecting to Voice Live...');

      final safeUrl = wsUrl.replaceAll("'", "\\'");
      final connectScript = html.ScriptElement()
        ..text = '''
          (async function() {
            try {
              window._pfWSConnectResult = '';
              await window._pfConnectWS('$safeUrl');
              window._pfWSConnectResult = 'ok';
            } catch(e) {
              window._pfWSConnectResult = 'fail:' + e;
            }
          })();
        ''';
      html.document.head!.append(connectScript);

      String connectResult = '';
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_disposed) return;
        try {
          final r = globalContext.getProperty('_pfWSConnectResult'.toJS);
          if (r != null) {
            if (r.isA<JSString>()) {
              connectResult = (r as JSString).toDart;
            } else {
              connectResult = r.toString();
            }
            if (connectResult.isNotEmpty && connectResult != 'undefined') break;
          }
        } catch (_) {}
      }

      if (connectResult == 'ok') {
        debugPrint('WebSocket connected!');
        _wsReady = true;
        _reconnectAttempts = 0;

        _audioTimer?.cancel();
        _audioTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
          _pollMessages();
          _sendCapturedAudio();
          _checkWSClosed();
        });

        return;
      } else {
        debugPrint('Connect failed: $connectResult');
        _wsReady = false;
        _setState(VoiceState.error);
      }
    } catch (e) {
      debugPrint('WS attempt error: $e');
      _wsReady = false;
      _setState(VoiceState.error);
    }
  }

  void _pollMessages() {
    if (_disposed) return;

    try {
      final resultJs = globalContext.callMethod('_pfGetMessages'.toJS);
      if (resultJs == null) return;

      String jsonStr;
      if (resultJs.isA<JSString>()) {
        jsonStr = (resultJs as JSString).toDart;
      } else {
        jsonStr = resultJs.toString();
      }

      if (jsonStr.isEmpty || jsonStr == '[]' || jsonStr == 'undefined') return;

      final List<dynamic> messages = jsonDecode(jsonStr);
      for (final msg in messages) {
        if (msg is String) {
          _handleMessage(msg);
        }
      }
    } catch (e) {
      debugPrint('Poll error: $e');
    }
  }

  void _checkWSClosed() {
    if (_disposed) return;

    try {
      final closedJs = globalContext.callMethod('_pfIsWSClosed'.toJS);
      if (closedJs == null) return;

      String closed;
      if (closedJs.isA<JSString>()) {
        closed = (closedJs as JSString).toDart;
      } else {
        closed = closedJs.toString();
      }

      if (closed == 'true') {
        debugPrint('WebSocket closed detected');
        _wsReady = false;
        _sessionConfigured = false;
        _audioTimer?.cancel();
        if (!_disposed) _attemptReconnect();
      }
    } catch (_) {}
  }

  void _attemptReconnect() {
    if (_disposed || _reconnectAttempts >= 5) {
      _setState(VoiceState.error);
      return;
    }

    _reconnectAttempts++;
    _setState(VoiceState.connecting);

    Future.delayed(Duration(seconds: _reconnectAttempts * 2), () {
      if (!_disposed) _connectWebSocket();
    });
  }

  void _sendRaw(String jsonString) {
    if (!_wsReady || _disposed) return;
    try {
      final escaped = jsonString
          .replaceAll('\\', '\\\\')
          .replaceAll("'", "\\'")
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');

      final sendScript = html.ScriptElement()
        ..text = "window._pfSendWS('$escaped');";
      html.document.head!.append(sendScript);
    } catch (e) {
      debugPrint('Send error: $e');
    }
  }

  void _send(Map<String, dynamic> message) {
    _sendRaw(jsonEncode(message));
  }

  void _sendSessionUpdate() {
    final voiceName = _voiceName.isNotEmpty ? _voiceName : 'en-US-AvaNeural';

    final sessionConfig = {
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': _buildInstructions(),
        'voice': {
          'name': voiceName,
          'type': 'azure-standard',
        },
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'azure-speech',
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 300,
          'create_response': true,
          'interrupt_response': true,
        },
        'tools': _buildTools(),
        'tool_choice': 'auto',
        'temperature': 0.7,
        'max_response_output_tokens': 500,
      },
    };

    debugPrint('Sending session.update with voice: $voiceName');
    _send(sessionConfig);
  }

  void _handleMessage(String raw) {
    if (_disposed) return;

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = json['type'] as String? ?? '';
    debugPrint('Event: $type');

    switch (type) {
      case 'session.created':
        debugPrint('Session created — sending session.update');
        _sessionConfigured = false;
        _sendSessionUpdate();
        break;

      case 'session.updated':
        debugPrint('Session configured successfully');
        _sessionConfigured = true;
        _setState(VoiceState.listening);
        break;

      case 'input_audio_buffer.speech_started':
        _stopCurrentAudio();
        _pcmBuf.clear();
        _textBuffer.clear();
        _setState(VoiceState.processing);
        break;

      case 'input_audio_buffer.speech_stopped':
        break;

      case 'conversation.item.input_audio_transcription.completed':
        final t = (json['transcript'] as String? ?? '').trim();
        if (t.isNotEmpty) _addMessage(t, true);
        break;

      case 'response.audio_transcript.delta':
        _textBuffer.add(json['delta'] as String? ?? '');
        break;

      case 'response.audio_transcript.done':
        if (_textBuffer.isNotEmpty) {
          _addMessage(_textBuffer.join(), false);
          _textBuffer.clear();
        }
        break;

      case 'response.text.delta':
        _textBuffer.add(json['delta'] as String? ?? '');
        break;

      case 'response.text.done':
        if (_textBuffer.isNotEmpty) {
          _addMessage(_textBuffer.join(), false);
          _textBuffer.clear();
        }
        break;

      case 'response.audio.delta':
        final b64 = json['delta'] as String? ?? '';
        if (b64.isNotEmpty) {
          try {
            _pcmBuf.add(base64Decode(b64));
          } catch (_) {}
        }
        _setState(VoiceState.speaking);
        break;

      case 'response.audio.done':
        _flushAndPlay();
        break;

      case 'response.done':
        if (_textBuffer.isNotEmpty) {
          _addMessage(_textBuffer.join(), false);
          _textBuffer.clear();
        }
        if (_pcmBuf.isEmpty && !_isPlaying) {
          _setState(VoiceState.listening);
        }
        break;

      case 'response.function_call_arguments.done':
        _handleToolCall(json);
        break;

      case 'error':
        final errObj = json['error'] as Map<String, dynamic>?;
        final msg = errObj?['message'] as String? ?? '';
        final code = errObj?['code'] as String? ?? '';
        debugPrint('API error [$code]: $msg');

        if (msg.contains('voice') && msg.contains('Azure')) {
          debugPrint('Voice name issue — check your voiceName config');
        }
        break;
    }
  }

  void _flushAndPlay() {
    if (_pcmBuf.isEmpty) {
      _setState(VoiceState.listening);
      return;
    }

    final total = _pcmBuf.fold<int>(0, (s, b) => s + b.length);
    final pcm = Uint8List(total);
    var off = 0;
    for (final chunk in _pcmBuf) {
      pcm.setRange(off, off + chunk.length, chunk);
      off += chunk.length;
    }
    _pcmBuf.clear();

    final wav = _pcm16ToWav(pcm, sampleRate: 24000);
    final blob = html.Blob([wav], 'audio/wav');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final audio = html.AudioElement()
      ..src = url
      ..volume = 1.0;

    _currentAudio = audio;
    _isPlaying = true;
    _setState(VoiceState.speaking);

    audio.onEnded.listen((_) {
      html.Url.revokeObjectUrl(url);
      _isPlaying = false;
      _currentAudio = null;
      if (!_disposed) _setState(VoiceState.listening);
    });

    audio.onError.listen((_) {
      html.Url.revokeObjectUrl(url);
      _isPlaying = false;
      _currentAudio = null;
      if (!_disposed) _setState(VoiceState.listening);
    });

    audio.play();
  }

  void _stopCurrentAudio() {
    if (_currentAudio != null) {
      try {
        _currentAudio!.pause();
        _currentAudio!.currentTime = 0;
      } catch (_) {}
      _currentAudio = null;
    }
    _pcmBuf.clear();
    _isPlaying = false;
  }

  Uint8List _pcm16ToWav(Uint8List pcm, {int sampleRate = 24000}) {
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const int blockAlign = numChannels * bitsPerSample ~/ 8;
    final bd = ByteData(44 + pcm.length);

    void str(int off, String s) {
      for (int i = 0; i < s.length; i++) {
        bd.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    bd.setUint32(4, 36 + pcm.length, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, numChannels, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, byteRate, Endian.little);
    bd.setUint16(32, blockAlign, Endian.little);
    bd.setUint16(34, bitsPerSample, Endian.little);
    str(36, 'data');
    bd.setUint32(40, pcm.length, Endian.little);
    for (int i = 0; i < pcm.length; i++) {
      bd.setUint8(44 + i, pcm[i]);
    }
    return bd.buffer.asUint8List();
  }

  void _handleToolCall(Map<String, dynamic> json) {
    final callId = json['call_id'] as String? ?? '';
    final functionName = json['name'] as String? ?? '';

    String result;
    switch (functionName) {
      case 'get_projects':
        result =
            _projects.map((p) => '${p.title}: ${p.description}').join('\n\n');
        if (result.isEmpty) result = 'No projects available';
        break;
      case 'get_services':
        result =
            _services.map((s) => '${s.title}: ${s.description}').join('\n\n');
        if (result.isEmpty) result = 'No services available';
        break;
      case 'get_books':
        result = _books.map((b) => '${b.title} by ${b.author}').join('\n');
        if (result.isEmpty) result = 'No books available';
        break;
      case 'get_contact':
        result =
            'Email: ${AppConstants.appEmail}\nSocial: ${_socials.map((s) => s.platform).join(', ')}';
        break;
      case 'get_cv':
        result = _cv != null
            ? 'CV available. Highlights: ${_cv!.highlights.join(', ')}'
            : 'CV not available';
        break;
      default:
        result = 'Function not found';
    }

    _send({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': result,
      },
    });
    _send({'type': 'response.create'});
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty || _disposed) return;

    if (!_wsReady || !_sessionConfigured) {
      _addMessage(text.trim(), true);
      _addMessage('Still connecting, please wait a moment...', false);
      return;
    }

    _stopCurrentAudio();
    _textBuffer.clear();

    _addMessage(text.trim(), true);
    _setState(VoiceState.processing);

    _send({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': text.trim()},
        ],
      },
    });
    _send({'type': 'response.create'});
  }

  String _buildInstructions() {
    final projects = _projects
        .map((p) => '${p.title}: ${p.description} (${p.category}, ${p.year})')
        .join('. ');
    final services =
        _services.map((s) => '${s.title}: ${s.description}').join('. ');
    final books =
        _books.map((b) => '${b.title} by ${b.author} (${b.status})').join('. ');

    return '$_instructions Keep responses brief, 2-3 sentences max. '
        'Projects: $projects. '
        'Services: $services. '
        'Books: $books. '
        'Social: ${_socials.map((s) => '${s.platform}: ${s.handle}').join(', ')}. '
        'CV: ${_cv != null ? 'Available' : 'Not available'}.';
  }

  List<Map<String, dynamic>> _buildTools() => [
        {
          'type': 'function',
          'name': 'get_projects',
          'description': 'Get list of all projects or filter by category',
          'parameters': {
            'type': 'object',
            'properties': {
              'category': {'type': 'string'},
            },
          },
        },
        {
          'type': 'function',
          'name': 'get_services',
          'description': 'Get available services',
          'parameters': {'type': 'object', 'properties': {}},
        },
        {
          'type': 'function',
          'name': 'get_books',
          'description': 'Get reading list',
          'parameters': {'type': 'object', 'properties': {}},
        },
        {
          'type': 'function',
          'name': 'get_contact',
          'description': 'Get contact information',
          'parameters': {'type': 'object', 'properties': {}},
        },
        {
          'type': 'function',
          'name': 'get_cv',
          'description': 'Get CV or resume information',
          'parameters': {'type': 'object', 'properties': {}},
        },
      ];

  Future<void> dispose() async {
    _disposed = true;
    _wsReady = false;
    _sessionConfigured = false;
    _audioTimer?.cancel();
    _stopCurrentAudio();

    try {
      globalContext.callMethod('_pfStop'.toJS);
    } catch (_) {}
    try {
      globalContext.callMethod('_pfCloseWS'.toJS);
    } catch (_) {}

    _stream?.getTracks().forEach((t) => t.stop());
    await _stateCtrl.close();
    await _msgCtrl.close();
  }
}
