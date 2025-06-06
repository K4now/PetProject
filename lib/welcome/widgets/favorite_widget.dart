import 'package:telegram_web_app/telegram_web_app.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/card_class.dart';

import 'package:flutter/material.dart';

class FavoriteWidget extends StatefulWidget {
  const FavoriteWidget({
    super.key,
    required this.listCards,
  });

  final List<CardClass> listCards;

  @override
  State<FavoriteWidget> createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'ru_RU', // Русский язык
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onSoundLevelChange: (level) {
        // Можно добавить индикатор уровня звука
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Telegram Web App информация
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telegram Web App Info',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Version: ${TelegramWebApp.instance.version}'),
                  const SizedBox(height: 4),
                  Text(
                      'Theme: ${TelegramWebApp.instance.themeParams.toString()}'),
                  const SizedBox(height: 4),
                  Text(
                      'Init Data: ${TelegramWebApp.instance.initData.toString()}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Секция распознавания речи
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Распознавание речи',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Статус
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: _speechEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: _speechEnabled ? Colors.green : Colors.red,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _speechEnabled ? Icons.mic : Icons.mic_off,
                          color: _speechEnabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _speechEnabled
                              ? 'Распознавание речи доступно'
                              : 'Распознавание речи недоступно',
                          style: TextStyle(
                            color: _speechEnabled ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Кнопка записи
                  ElevatedButton.icon(
                    onPressed: _speechEnabled
                        ? _isListening
                            ? _stopListening
                            : _startListening
                        : null,
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening ? Colors.red : null,
                    ),
                    label: Text(
                      _isListening ? 'Остановить запись' : 'Начать запись',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : null,
                      foregroundColor: _isListening ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Результат распознавания
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Распознанный текст:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastWords.isEmpty
                              ? 'Нажмите на кнопку записи...'
                              : _lastWords,
                          style: TextStyle(
                            fontSize: 16,
                            color: _lastWords.isEmpty ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isListening) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Слушаю...'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
