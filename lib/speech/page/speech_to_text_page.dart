import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
  bool _shouldKeepListening = false;
  double _confidenceLevel = 0.0;
  DateTime? _listeningStartTime;
  final List<String> _speechHistory = [];
  
  // Переменные для языков
  List<LocaleName> _availableLocales = [];
  String _currentLocale = 'ru-RU'; // Русский язык по умолчанию

  // Новые переменные для Telegram-style UI
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPressed = false;
  double _slideDistance = 0.0;
  double _slideUpDistance = 0.0;
  bool _isCanceled = false;
  bool _isLocked = false;

  // Анимация для визуализации звука
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Анимации для Telegram-style кнопки
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAnimations();
  }

  @override
  void dispose() {
    _shouldKeepListening = false;
    _speechToText.stop();
    _pulseController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
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

    // Анимации для Telegram-style кнопки
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
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
            errorMessage = 'Доступ к микрофону запрещен. Разрешите доступ в браузере.';
          } else if (error.errorMsg.contains('network')) {
            errorMessage = 'Нет подключения к интернету. Речевое распознавание требует интернет.';
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

            // Автоматически перезапускаем прослушивание, если пользователь хочет продолжить
            if (_shouldKeepListening) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_shouldKeepListening && _speechEnabled) {
                  _startListening();
                }
              });
            }
          }
        },
      );

      if (_speechEnabled) {
        // Получаем список доступных языков
        _availableLocales = await _speechToText.locales();
        debugPrint('Available locales: ${_availableLocales.map((e) => '${e.localeId} - ${e.name}').toList()}');
        
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
          
          _showInfoSnackBar('Браузер не предоставил список языков. Используется стандартный набор.');
        }
        
        // Проверяем, доступен ли русский язык
        bool hasRussian = _availableLocales.any((locale) => 
          locale.localeId.toLowerCase().contains('ru'));
        
        if (hasRussian) {
          _currentLocale = 'ru-RU';
          _showInfoSnackBar('Русский язык настроен. Если распознавание не работает, проверьте язык браузера в настройках.');
        } else {
          _currentLocale = 'en-US';
          _showInfoSnackBar('Русский язык не найден. Используется английский. Измените язык браузера на русский в настройках.');
        }
        
        debugPrint('Using locale: $_currentLocale');
        
      } else {
        _showErrorSnackBar('Распознавание речи недоступно. Проверьте:\n1. Используете HTTPS?\n2. Разрешен доступ к микрофону?\n3. Браузер поддерживает речевое распознавание?');
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
      _shouldKeepListening = true; // Включаем автоматический перезапуск
      _listeningStartTime = DateTime.now(); // Записываем время начала
      _currentWords = '';
    });
    _startAnimations();
  }

  void _stopListening() async {
    _shouldKeepListening = false; // Отключаем автоматический перезапуск
    _listeningStartTime = null; // Сбрасываем время начала
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _stopAnimations();
  }

  void _onSpeechResult(result) {
    String newRecognizedWords = result.recognizedWords;
    
    // Предотвращаем дублирование только для промежуточных результатов
    if (!result.finalResult && newRecognizedWords == _currentWords) {
      return;
    }
    
    setState(() {
      _currentWords = newRecognizedWords;
      _confidenceLevel = result.confidence;
      
      // Если это финальный результат, добавляем к тексту
      if (result.finalResult && _currentWords.isNotEmpty) {
        // Добавляем новый распознанный текст к существующему
        String currentText = _textController.text;
        
        // Добавляем только новый текст, избегая дублирования
        if (!currentText.endsWith(_currentWords)) {
          _textController.text = '$currentText$_currentWords ';
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
        
        // Добавляем к истории
        _recognizedText += '${_currentWords.trim()}\n';
        _speechHistory.insert(0, _currentWords.trim());
        if (_speechHistory.length > 10) {
          _speechHistory.removeLast();
        }
        
        // Сбрасываем текущие слова после финального результата
        _currentWords = '';
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

  void _clearText() {
    setState(() {
      _recognizedText = '';
      _currentWords = '';
      _speechHistory.clear();
      _textController.clear();
    });
  }

  // Методы для Telegram-style записи
  void _onPanStart(DragStartDetails details) {
    if (!_speechEnabled) return;

    setState(() {
      _isPressed = true;
      _isCanceled = false;
      _isLocked = false;
      _slideDistance = 0.0;
      _slideUpDistance = 0.0;
    });

    _scaleController.forward();
    _startListening();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPressed || _isLocked) return;

    setState(() {
      // Горизонтальный свайп для отмены (влево)
      _slideDistance = -details.localPosition.dx;
      if (_slideDistance < 0) _slideDistance = 0; // Не даем тянуть вправо
      
      _isCanceled = _slideDistance > 100;

      // Вертикальный свайп для блокировки (вверх)
      _slideUpDistance = -details.localPosition.dy;
      if (_slideUpDistance < 0) _slideUpDistance = 0; // Не даем тянуть вниз
      
      if (_slideUpDistance > 100 && !_isCanceled) {
        _isLocked = true;
        _isCanceled = false;
      }
    });

    if (_isCanceled && !_isLocked) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isPressed) return;

    setState(() {
      _isPressed = false;
    });

    _scaleController.reverse();
    _slideController.reverse();

    if (_isCanceled && !_isLocked) {
      // Отменяем запись - удаляем последний добавленный текст
      String currentText = _textController.text;
      if (_currentWords.isNotEmpty) {
        // Удаляем промежуточный результат если он есть
        if (currentText.endsWith(_currentWords)) {
          _textController.text = currentText.substring(0, currentText.length - _currentWords.length);
        }
      }
      _stopListening();
      _currentWords = '';
    } else if (!_isLocked) {
      // Завершаем запись (если не заблокировано)
      _stopListening();
    }
    // Если заблокировано - продолжаем запись

    setState(() {
      _slideDistance = 0.0;
      _slideUpDistance = 0.0;
      _isCanceled = false;
    });
  }

  void _toggleRecording() {
    if (_isListening) {
      _stopListening();
      setState(() {
        _isLocked = false;
      });
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
              bool hasRussian = _availableLocales.any((locale) => 
                locale.localeId.toLowerCase().contains('ru'));
              
              if (!hasRussian) {
                _availableLocales.add(LocaleName('ru-RU', 'Русский (принудительно)'));
              }
              
              _showInfoSnackBar('Принудительно установлен русский язык. Попробуйте записать.');
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
                            displayName.isNotEmpty ? displayName : locale.localeId,
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
              colors: _isLocked
                  ? [Colors.green.withOpacity(0.3), Colors.teal.withOpacity(0.3)]
                  : [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
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
                child: Icon(
                  _isLocked ? Icons.lock : Icons.mic, 
                  color: Colors.white, 
                  size: 24
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isCanceled 
                    ? 'Отпустите для отмены' 
                    : _isLocked 
                        ? 'Запись заблокирована - нажмите для остановки'
                        : 'Говорите... (${_getLanguageName(_currentLocale)})',
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
      animation: Listenable.merge([_scaleAnimation, _slideAnimation]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Кнопка отправки (когда есть текст)
              if (_textController.text.isNotEmpty && !_isListening)
                IconButton(
                  onPressed: () {
                    // Добавляем текст к общему результату
                    setState(() {
                      _recognizedText += '${_textController.text}\n';
                      _textController.clear();
                    });
                  },
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),

              const Spacer(),

              // Telegram-style кнопка записи
              GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: _isLocked ? _toggleRecording : null,
                child: Transform.translate(
                  offset: Offset(_isPressed ? _slideDistance : 0, 0),
                  child: Transform.scale(
                    scale: _isPressed ? _scaleAnimation.value : 1.0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isListening
                              ? (_isLocked ? [Colors.green, Colors.teal] : [Colors.red, Colors.redAccent])
                              : [Colors.blue, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening 
                                ? (_isLocked ? Colors.green : Colors.red) 
                                : Colors.blue)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isLocked 
                            ? Icons.stop 
                            : (_isListening ? Icons.mic : Icons.mic),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Индикатор отмены
              if (_isPressed && _isCanceled)
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Отменить',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Индикатор блокировки
              if (_isPressed && _slideUpDistance > 50 && !_isCanceled)
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        _isLocked ? 'Заблокировано' : 'Потяните вверх',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
