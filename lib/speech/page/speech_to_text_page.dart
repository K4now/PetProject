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

  // Новые переменные для Telegram-style UI
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPressed = false;
  double _slideDistance = 0.0;
  bool _isCanceled = false;

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
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech recognition error: $error');
        _showErrorSnackBar('Ошибка распознавания речи: ${error.errorMsg}');
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

    if (!_speechEnabled) {
      _showErrorSnackBar('Распознавание речи недоступно на этом устройстве');
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
    setState(() {
      _currentWords = result.recognizedWords;
      _confidenceLevel = result.confidence;

      // Обновляем поле ввода в реальном времени
      if (_currentWords.isNotEmpty) {
        String currentText = _textController.text;
        // Удаляем последнее временное добавление, если есть
        if (currentText.contains('[Слушаю...]')) {
          currentText = currentText.replaceAll('[Слушаю...]', '');
        }
        _textController.text = '$currentText$_currentWords';
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }

      if (result.finalResult && _currentWords.isNotEmpty) {
        _recognizedText += '${_currentWords.trim()}\n';
        _speechHistory.insert(0, _currentWords.trim());
        if (_speechHistory.length > 10) {
          _speechHistory.removeLast();
        }
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
  void _onPanStart() {
    if (!_speechEnabled) return;

    setState(() {
      _isPressed = true;
      _isCanceled = false;
      _slideDistance = 0.0;
    });

    _scaleController.forward();
    _startListening();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPressed) return;

    setState(() {
      _slideDistance = -details.localPosition.dx;
      _isCanceled = _slideDistance > 100;
    });

    if (_isCanceled) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _onPanEnd() {
    if (!_isPressed) return;

    setState(() {
      _isPressed = false;
    });

    _scaleController.reverse();
    _slideController.reverse();

    if (_isCanceled) {
      // Отменяем запись
      _textController.text = _textController.text.replaceAll(_currentWords, '');
      _stopListening();
    } else {
      // Завершаем запись
      _stopListening();
    }

    setState(() {
      _slideDistance = 0.0;
      _isCanceled = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Голосовые сообщения'),
        centerTitle: true,
        elevation: 0,
        actions: [
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
              colors: [
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
                child: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                _isCanceled ? 'Отпустите для отмены' : 'Говорите...',
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
        decoration: const InputDecoration(
          hintText:
              'Начните печатать или зажмите кнопку микрофона для записи голоса...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
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
                onPanStart: (_) => _onPanStart(),
                onPanUpdate: _onPanUpdate,
                onPanEnd: (_) => _onPanEnd(),
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
                        _isListening ? Icons.stop : Icons.mic,
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
            ],
          ),
        );
      },
    );
  }
}
