import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

@RoutePage()
class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _currentWords = '';
  bool _isListening = false;
  double _confidenceLevel = 0.0;
  final List<String> _speechHistory = [];

  // Переменные для языков
  List<LocaleName> _availableLocales = [];
  String _currentLocale = 'ru-RU'; // Русский язык по умолчанию

  // Новые переменные для Telegram-style UI
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Анимация для визуализации звука
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfoSnackBar(
          'Доступ к микрофону будет запрошен только один раз при первом запуске.');
    });
    _initSpeech();
    _initAnimations();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _pulseController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          String errorMessage = 'Ошибка распознавания речи: ${error.errorMsg}';

          // Специальные сообщения для браузера
          if (error.errorMsg.contains('not-allowed')) {
            errorMessage =
                'Доступ к микрофону запрещен. Разрешите доступ в браузере.';
          } else if (error.errorMsg.contains('network')) {
            errorMessage =
                'Нет подключения к интернету. Речевое распознавание требует интернет.';
          } else if (error.errorMsg.contains('no-speech')) {
            errorMessage = 'Речь не обнаружена. Говорите ближе к микрофону.';
          }

          _showErrorSnackBar(errorMessage);
          setState(() {
            _speechEnabled = false;
            _isListening = false;
          });
          _stopAnimations();
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
            _stopAnimations();
            // УБРАН автоперезапуск прослушивания
          }
        },
      );

      if (_speechEnabled) {
        // Получаем список доступных языков
        _availableLocales = await _speechToText.locales();
        debugPrint(
            'Available locales: ${_availableLocales.map((e) => '${e.localeId} - ${e.name}').toList()}');

        // В браузере создаем список языков вручную, если система не предоставляет
        if (_availableLocales.isEmpty) {
          debugPrint('No locales from system, creating manual list for web...');

          // Добавляем основные языки для браузера
          _availableLocales = [
            LocaleName('en-US', 'English (United States)'),
            LocaleName('ru-RU', 'Русский'),
            LocaleName('en-GB', 'English (United Kingdom)'),
            LocaleName('es-ES', 'Español'),
            LocaleName('fr-FR', 'Français'),
            LocaleName('de-DE', 'Deutsch'),
            LocaleName('it-IT', 'Italiano'),
            LocaleName('pt-BR', 'Português (Brasil)'),
            LocaleName('zh-CN', '中文'),
            LocaleName('ja-JP', '日本語'),
            LocaleName('ko-KR', '한국어'),
          ];

          _showInfoSnackBar(
              'Браузер не предоставил список языков. Используется стандартный набор.');
        }

        // Проверяем, доступен ли русский язык
        bool hasRussian = _availableLocales
            .any((locale) => locale.localeId.toLowerCase().contains('ru'));

        if (hasRussian) {
          _currentLocale = 'ru-RU';
          _showInfoSnackBar(
              'Русский язык настроен. Если распознавание не работает, проверьте язык браузера в настройках.');
        } else {
          _currentLocale = 'en-US';
          _showInfoSnackBar(
              'Русский язык не найден. Используется английский. Измените язык браузера на русский в настройках.');
        }

        debugPrint('Using locale: $_currentLocale');
      } else {
        _showErrorSnackBar(
            'Распознавание речи недоступно. Проверьте:\n1. Используете HTTPS?\n2. Разрешен доступ к микрофону?\n3. Браузер поддерживает речевое распознавание?');
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      _showErrorSnackBar('Ошибка инициализации речевого распознавания: $e');
    }
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _showErrorSnackBar('Распознавание речи не инициализировано');
      return;
    }
    // Если уже слушаем — не запускаем повторно
    if (_isListening || _speechToText.isListening) {
      return;
    }
    setState(() {
      _recognizedText = '';
    });
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        localeId: _currentLocale,
        onSoundLevelChange: (level) {
          _updateWaveAnimation(level);
        },
      );
      setState(() {
        _isListening = true;
        _currentWords = '';
        _confidenceLevel = 0.0;
      });
      _startAnimations();
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _showErrorSnackBar('Ошибка запуска распознавания: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _stopListening() async {
    if (!_isListening) {
      return; // Уже остановлено
    }

    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _currentWords = ''; // Очищаем промежуточный результат
      });
      _stopAnimations();
    } catch (e) {
      debugPrint('Error stopping listening: $e');
      setState(() {
        _isListening = false;
        _currentWords = '';
      });
      _stopAnimations();
    }
  }

  String _lastFinalResult = '';

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords.trim();

    if (result.finalResult) {
      if (recognized.isNotEmpty) {
        final newPart = _getDeltaText(_lastFinalResult, recognized);
        if (newPart.isNotEmpty) {
          final existing = _textController.text.trim();
          final nextText = existing.isNotEmpty ? '$existing $newPart' : newPart;

          _textController.text = nextText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
        _lastFinalResult = recognized;
      }
      setState(() {
        _currentWords = '';
      });
    } else {
      setState(() {
        _currentWords = recognized;
      });
    }
  }

  String _getDeltaText(String previous, String current) {
    if (current.startsWith(previous)) {
      final delta = current.substring(previous.length).trim();
      // Если delta пустое, но current == previous — значит ты реально повторил фразу,
      // возвращаем её целиком, чтобы добавить повтор
      if (delta.isEmpty && current == previous) {
        return current;
      }
      return delta;
    }
    // Полностью новая строка — просто возвращаем всю
    return current;
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _pulseController.stop();
  }

  void _updateWaveAnimation(double level) {
    // Убираем для упрощения
  }

  void _clearText() {
    setState(() {
      _recognizedText = '';
      _currentWords = '';
      _speechHistory.clear();
      _textController.clear();
      _confidenceLevel = 0.0;
    });
  }

  // Методы для Telegram-style записи
  void _toggleRecording() {
    // Если уже слушаем — не запускаем повторно
    if (_isListening || _speechToText.isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  String _getLanguageName(String localeId) {
    // Сначала проверяем, есть ли этот язык в доступных локалях
    for (var locale in _availableLocales) {
      if (locale.localeId == localeId) {
        // Если есть, возвращаем его имя из системы
        if (locale.name.isNotEmpty) {
          return locale.name;
        }
      }
    }

    // Если не найден или нет имени, возвращаем предопределенные названия
    switch (localeId) {
      case 'ru-RU':
        return 'Русский';
      case 'en-US':
        return 'English';
      case 'es-ES':
        return 'Español';
      case 'fr-FR':
        return 'Français';
      case 'de-DE':
        return 'Deutsch';
      case 'it-IT':
        return 'Italiano';
      case 'zh-CN':
        return '中文';
      case 'ja-JP':
        return '日本語';
      case 'ko-KR':
        return '한국어';
      default:
        return localeId;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Голосовые сообщения'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Кнопка отладки для браузера
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Тестировать русский',
            onPressed: () async {
              // Принудительно пробуем русский язык
              setState(() {
                _currentLocale = 'ru-RU';
              });

              // Добавляем русский в список если его нет
              bool hasRussian = _availableLocales.any(
                  (locale) => locale.localeId.toLowerCase().contains('ru'));

              if (!hasRussian) {
                _availableLocales
                    .add(LocaleName('ru-RU', 'Русский (принудительно)'));
              }

              _showInfoSnackBar(
                  'Принудительно установлен русский язык. Попробуйте записать.');
              debugPrint('Forced Russian locale: ru-RU');
            },
          ),
          // Кнопка выбора языка
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: 'Выбрать язык',
            onSelected: (String localeId) {
              setState(() {
                _currentLocale = localeId;
              });
              _showInfoSnackBar('Выбран язык: ${_getLanguageName(localeId)}');
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String>> items = [];

              // Добавляем все доступные языки
              for (var locale in _availableLocales) {
                String flag = '';
                String displayName = locale.name;

                // Добавляем флаги для популярных языков
                if (locale.localeId.startsWith('ru')) {
                  flag = '🇷🇺';
                  displayName = 'Русский';
                } else if (locale.localeId.startsWith('en')) {
                  flag = '🇺🇸';
                  displayName = 'English';
                } else if (locale.localeId.startsWith('es')) {
                  flag = '🇪🇸';
                } else if (locale.localeId.startsWith('fr')) {
                  flag = '🇫🇷';
                } else if (locale.localeId.startsWith('de')) {
                  flag = '🇩🇪';
                } else if (locale.localeId.startsWith('it')) {
                  flag = '🇮🇹';
                } else if (locale.localeId.startsWith('zh')) {
                  flag = '🇨🇳';
                } else if (locale.localeId.startsWith('ja')) {
                  flag = '🇯🇵';
                } else if (locale.localeId.startsWith('ko')) {
                  flag = '🇰🇷';
                }

                items.add(
                  PopupMenuItem<String>(
                    value: locale.localeId,
                    child: Row(
                      children: [
                        if (flag.isNotEmpty) ...[
                          Text(flag),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName
                                : locale.localeId,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_currentLocale == locale.localeId)
                          const Icon(Icons.check, size: 16),
                      ],
                    ),
                  ),
                );
              }

              // Если нет доступных языков, добавляем стандартные для браузера
              if (items.isEmpty) {
                List<Map<String, String>> browserLanguages = [
                  {'id': 'ru-RU', 'name': 'Русский', 'flag': '🇷🇺'},
                  {'id': 'en-US', 'name': 'English', 'flag': '🇺🇸'},
                  {'id': 'es-ES', 'name': 'Español', 'flag': '🇪🇸'},
                  {'id': 'fr-FR', 'name': 'Français', 'flag': '🇫🇷'},
                  {'id': 'de-DE', 'name': 'Deutsch', 'flag': '🇩🇪'},
                ];

                for (var lang in browserLanguages) {
                  items.add(
                    PopupMenuItem<String>(
                      value: lang['id']!,
                      child: Row(
                        children: [
                          Text(lang['flag']!),
                          const SizedBox(width: 8),
                          Text(lang['name']!),
                          if (_currentLocale == lang['id'])
                            const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                  );
                }
              }

              return items;
            },
          ),
          IconButton(
            onPressed: _clearText,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Очистить текст',
          ),
        ],
      ),
      body: Column(
        children: [
          // Статус индикатор
          if (_isListening) _buildListeningIndicator(),

          // Основная область с полем ввода
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Поле ввода текста
                  Expanded(
                    child: _buildTextInput(),
                  ),
                  const SizedBox(height: 16),

                  // Telegram-style панель ввода
                  _buildInputPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          height: 60,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isListening
                  ? [
                      Colors.red.withOpacity(0.3),
                      Colors.redAccent.withOpacity(0.3)
                    ]
                  : [
                      Colors.blue.withOpacity(0.3),
                      Colors.purple.withOpacity(0.3)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                _isListening
                    ? 'Говорите... (${_getLanguageName(_currentLocale)})'
                    : 'Нажмите, чтобы начать запись',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_confidenceLevel > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '${(_confidenceLevel * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withOpacity(0.05),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText:
              'Начните печатать или зажмите кнопку микрофона для записи голоса (${_getLanguageName(_currentLocale)})...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildInputPanel() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Bubble с текущим распознанным текстом
            if (_isListening && _currentWords.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _currentWords,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            Row(
              children: [
                // Кнопка отправки (когда есть текст и не идёт запись)
                if (_textController.text.isNotEmpty && !_isListening)
                  IconButton(
                    onPressed: () {
                      String textToSend = _textController.text.trim();
                      if (textToSend.isNotEmpty) {
                        setState(() {
                          // Проверяем, не добавляли ли мы уже этот текст
                          if (_recognizedText.isEmpty ||
                              !_recognizedText.endsWith(textToSend)) {
                            _recognizedText += '$textToSend\n';
                          }
                          _textController.clear();
                          _currentWords = '';
                        });
                      }
                    },
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                const Spacer(),
                // Кнопка записи с пульсацией
                GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56 * (_isListening ? _pulseAnimation.value : 1.0),
                    height: 56 * (_isListening ? _pulseAnimation.value : 1.0),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [Colors.red, Colors.redAccent]
                            : [Colors.blue, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.blue)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
