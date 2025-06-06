import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

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
  String _lastProcessedText =
      ''; // Для предотвращения дублирования на мобильных
  bool _isListening = false;
  double _confidenceLevel = 0.0;
  final List<String> _speechHistory = [];

  // Переменные для предотвращения дублирования на мобильных устройствах
  DateTime? _lastUpdateTime;
  static const Duration _debounceDelay = Duration(milliseconds: 100);

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

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(minutes: 10), // Увеличиваем время прослушивания
      pauseFor: const Duration(seconds: 10), // Увеличиваем паузу до остановки
      partialResults: true,
      cancelOnError: false, // Не отменяем при ошибках
      localeId: _currentLocale, // Используем выбранный язык
      onSoundLevelChange: (level) {
        _updateWaveAnimation(level);
      },
    );

    setState(() {
      _isListening = true;
      _currentWords = '';
      _confidenceLevel = 0.0;
      _lastProcessedText = ''; // Сбрасываем для мобильных устройств
      _lastUpdateTime = null; // Сбрасываем время обновления
      // НЕ очищаем _textController.text, чтобы сохранить уже введённый текст
    });
    _startAnimations();
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _stopAnimations();

    // На мобильных устройствах добавляем небольшую задержку для обработки финального результата
    if (_isMobileDevice()) {
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('Mobile: Stop listening completed with delay');
    }
  }

  void _onSpeechResult(result) {
    String newRecognizedWords = result.recognizedWords.trim();

    // Для мобильных устройств добавляем дополнительную проверку
    bool isMobile = _isMobileDevice();
    final now = DateTime.now();

    // Дебаунсинг для мобильных устройств
    if (isMobile && _lastUpdateTime != null) {
      final timeSinceLastUpdate = now.difference(_lastUpdateTime!);
      if (timeSinceLastUpdate < _debounceDelay) {
        debugPrint(
            'Mobile: Debouncing - ignoring update (${timeSinceLastUpdate.inMilliseconds}ms)');
        return;
      }
    }

    // Отладочная информация
    debugPrint(
        'Speech result: isMobile=$isMobile, finalResult=${result.finalResult}, text="$newRecognizedWords", lastProcessed="$_lastProcessedText"');

    setState(() {
      _confidenceLevel = result.confidence;

      if (!result.finalResult) {
        // Промежуточный результат
        if (isMobile) {
          // На мобильных устройствах используем улучшенную проверку
          if (_shouldUpdateTextOnMobile(newRecognizedWords, false)) {
            _currentWords = newRecognizedWords;
            _textController.text = newRecognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
            _lastProcessedText = newRecognizedWords;
            _lastUpdateTime = now;
            debugPrint('Mobile: Updated interim text to "$newRecognizedWords"');
          }
        } else {
          // На десктопе работаем как обычно
          _currentWords = newRecognizedWords;
          _textController.text = newRecognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          _lastUpdateTime = now;
        }
      } else {
        // Финальный результат
        if (newRecognizedWords.isNotEmpty) {
          bool shouldUpdate = false;

          if (isMobile) {
            // На мобильных устройствах используем улучшенную проверку
            shouldUpdate = _shouldUpdateTextOnMobile(newRecognizedWords, true);
            debugPrint(
                'Mobile: Final result check - shouldUpdate=$shouldUpdate');
          } else {
            // На десктопе обычная проверка
            shouldUpdate = newRecognizedWords != _currentWords;
          }

          if (shouldUpdate) {
            _currentWords = newRecognizedWords;
            _textController.text = newRecognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
            _lastProcessedText = newRecognizedWords;
            _lastUpdateTime = now;
            debugPrint('Updated final text to "$newRecognizedWords"');
          }
        }
      }
    });
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

  // Функция для определения мобильного устройства
  bool _isMobileDevice() {
    if (kIsWeb) {
      // В веб-версии проверяем размер экрана и user agent
      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;

      // Считаем мобильным если ширина меньше 600px или это планшет/телефон
      return screenWidth < 600 ||
          mediaQuery.orientation == Orientation.portrait;
    } else {
      // На нативных платформах проверяем платформу
      return Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS;
    }
  }

  void _clearText() {
    setState(() {
      _recognizedText = '';
      _currentWords = '';
      _lastProcessedText = '';
      _lastUpdateTime = null; // Сбрасываем время последнего обновления
      _speechHistory.clear();
      _textController.clear();
      _confidenceLevel = 0.0;
    });
  }

  // Методы для Telegram-style записи
  void _toggleRecording() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // Специальный метод для обработки финального результата на мобильных устройствах
  bool _shouldUpdateTextOnMobile(String newText, bool isFinalResult) {
    if (newText.isEmpty) return false;

    // Если это тот же текст, что мы уже обработали
    if (newText == _lastProcessedText) return false;

    // Если новый текст короче предыдущего (возможный баг мобильного API)
    if (newText.length < _lastProcessedText.length) {
      debugPrint(
          'Mobile: Ignoring shorter text: "$newText" vs "$_lastProcessedText"');
      return false;
    }

    // Если новый текст полностью содержится в текущем поле ввода
    if (_textController.text.contains(newText)) {
      debugPrint('Mobile: Text already present in field');
      return false;
    }

    // Для финального результата добавляем дополнительные проверки
    if (isFinalResult) {
      // Проверяем, что финальный результат существенно отличается
      final similarity = _calculateSimilarity(newText, _currentWords);
      if (similarity > 0.9) {
        debugPrint(
            'Mobile: Final result too similar to current (${(similarity * 100).toInt()}%)');
        return false;
      }
    }

    return true;
  }

  // Простая функция для вычисления схожести строк
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;

    if (longer.isEmpty) return 1.0;

    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  // Алгоритм Левенштейна для вычисления расстояния редактирования
  int _levenshteinDistance(String a, String b) {
    final matrix =
        List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));

    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Голосовые сообщения'),
            const SizedBox(width: 8),
            // Индикатор типа устройства
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _isMobileDevice() ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isMobileDevice() ? 'Mobile' : 'Desktop',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Кнопка информации об устройстве
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Информация об устройстве',
            onPressed: () {
              final isMobile = _isMobileDevice();
              final deviceInfo = isMobile ? 'Мобильное устройство' : 'Десктоп';
              final screenSize = MediaQuery.of(context).size;

              _showInfoSnackBar('$deviceInfo\n'
                  'Размер экрана: ${screenSize.width.toInt()}x${screenSize.height.toInt()}\n'
                  'Платформа: ${kIsWeb ? "Web" : Theme.of(context).platform.name}\n'
                  'Язык: ${_getLanguageName(_currentLocale)}');
            },
          ),
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
          // Кнопка сброса речевого движка (особенно для мобильных)
          if (_isMobileDevice())
            IconButton(
              onPressed: () async {
                // Полный сброс речевого движка
                await _speechToText.stop();
                _clearText();
                await Future.delayed(const Duration(milliseconds: 500));
                _initSpeech();
                _showInfoSnackBar(
                    'Речевой движок перезапущен (для мобильных устройств)');
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Перезапустить речевой движок',
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
            if (_isListening && _textController.text.isNotEmpty)
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
                    _textController.text,
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
