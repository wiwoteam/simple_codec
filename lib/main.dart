import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_codec/utils/policy_service.dart';
import 'package:simple_codec/widgets/policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Decoder',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(Duration(seconds: 2));
    final fetchedLink = await PolicyService.fetchPolicyUrlFromServer();
    if (!mounted) return;
    if (fetchedLink == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DecoderScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PolicyScreen(url: fetchedLink)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 60, color: Colors.grey[700]),
            SizedBox(height: 20),
            Text(
              'Simple Decoder',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class DecoderScreen extends StatefulWidget {
  @override
  _DecoderScreenState createState() => _DecoderScreenState();
}

class _DecoderScreenState extends State<DecoderScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  bool _isEncode = true;
  String _selectedType = 'Base64';

  final List<String> _types = ['Base64', 'URL', 'Unicode', 'Morse'];

  // Morse code mapping
  final Map<String, String> _morseToText = {
    '.-': 'A',
    '-...': 'B',
    '-.-.': 'C',
    '-..': 'D',
    '.': 'E',
    '..-.': 'F',
    '--.': 'G',
    '....': 'H',
    '..': 'I',
    '.---': 'J',
    '-.-': 'K',
    '.-..': 'L',
    '--': 'M',
    '-.': 'N',
    '---': 'O',
    '.--.': 'P',
    '--.-': 'Q',
    '.-.': 'R',
    '...': 'S',
    '-': 'T',
    '..-': 'U',
    '...-': 'V',
    '.--': 'W',
    '-..-': 'X',
    '-.--': 'Y',
    '--..': 'Z',
    '-----': '0',
    '.----': '1',
    '..---': '2',
    '...--': '3',
    '....-': '4',
    '.....': '5',
    '-....': '6',
    '--...': '7',
    '---..': '8',
    '----.': '9',
    '/': ' ',
  };

  final Map<String, String> _textToMorse = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '----..',
    '9': '----.',
    ' ': '/',
  };

  void _processText() {
    try {
      String input = _inputController.text;
      String result = '';

      switch (_selectedType) {
        case 'Base64':
          if (_isEncode) {
            result = base64Encode(utf8.encode(input));
          } else {
            result = utf8.decode(base64Decode(input));
          }
          break;
        case 'URL':
          if (_isEncode) {
            result = Uri.encodeComponent(input);
          } else {
            result = Uri.decodeComponent(input);
          }
          break;
        case 'Unicode':
          if (_isEncode) {
            result = input.runes
                .map(
                  (rune) => rune > 127
                      ? '\\u${rune.toRadixString(16).padLeft(4, '0')}'
                      : String.fromCharCode(rune),
                )
                .join();
          } else {
            result = input.replaceAllMapped(
              RegExp(r'\\u([0-9a-fA-F]{4})'),
              (match) =>
                  String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
            );
          }
          break;
        case 'Morse':
          if (_isEncode) {
            result = input
                .toUpperCase()
                .split('')
                .map((char) => _textToMorse[char] ?? char)
                .join(' ');
          } else {
            List<String> morseWords = input.split(' / ');
            result = morseWords
                .map((word) {
                  return word
                      .split(' ')
                      .map((morse) => _morseToText[morse] ?? '')
                      .join('');
                })
                .join(' ');
          }
          break;
      }

      _outputController.text = result;
    } catch (e) {
      _outputController.text = 'Error: Invalid input';
    }
  }

  void _copyToClipboard() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _clear() {
    _inputController.clear();
    _outputController.clear();
  }

  void _swapInputOutput() {
    String temp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = temp;
    setState(() {
      _isEncode = !_isEncode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Mode Switch - Compact
                Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isEncode ? 'ENCODE' : 'DECODE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: _isEncode,
                                onChanged: (value) =>
                                    setState(() => _isEncode = value),
                                activeColor: Colors.black,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.star_rate,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Rate App',
                                onPressed: () async {
                                  final url =
                                      'https://apps.apple.com/de/app/simple-base-codec/id6748936578';
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(
                                      Uri.parse(url),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.privacy_tip,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Policy',
                                onPressed: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PolicyScreen(url: null),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Type Selection - Compact
                Container(
                  height: 35,
                  child: Row(
                    children: _types.map((type) {
                      bool isSelected = type == _selectedType;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: 8),

                // Input - Fixed height
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _inputController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Input text...',
                      hintStyle: TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Process Button - Compact
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _processText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      '${_isEncode ? 'ENCODE' : 'DECODE'} $_selectedType',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Output - Fixed height
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey[50],
                  ),
                  child: TextField(
                    controller: _outputController,
                    maxLines: null,
                    expands: true,
                    readOnly: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Output...',
                      hintStyle: TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Action Buttons - Compact
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: OutlinedButton(
                          onPressed: _copyToClipboard,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Copy',
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: OutlinedButton(
                          onPressed: _swapInputOutput,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Swap',
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
