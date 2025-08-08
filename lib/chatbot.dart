import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:translator/translator.dart';


class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  final translator = GoogleTranslator();

  bool isLoading = false;
  bool isTamil = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLanguageDialog();
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Choose Language"),
        content: Text("Please select your preferred language."),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => isTamil = false);
              Navigator.pop(context);
            },
            child: Text("English"),
          ),
          TextButton(
            onPressed: () {
              setState(() => isTamil = true);
              Navigator.pop(context);
            },
            child: Text("தமிழ்"),
          ),
        ],
      ),
    );
  }

 Future<void> sendMessage() async {
  String userMessage = _controller.text.trim();
  if (userMessage.isEmpty) return;

  setState(() {
    messages.add({"role": "user", "text": userMessage});
    isLoading = true;
  });
  _controller.clear();

  try {
    String processedMessage = userMessage;

    // Translate to English if user selected Tamil
    if (isTamil) {
      processedMessage =
          (await translator.translate(userMessage, from: 'ta', to: 'en')).text;
    }

    var url = Uri.parse('http://172.16.142.229:5000/chat'); // your backend URL
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"prompt": processedMessage}),
    );

    if (response.statusCode == 200) {
      String botReply = jsonDecode(response.body)["response"];

      // Only translate response to Tamil if user selected Tamil
      if (isTamil) {
        botReply =
            (await translator.translate(botReply, from: 'en', to: 'ta')).text;
      }

      setState(() {
        messages.add({"role": "bot", "text": botReply});
      });
    } else {
      setState(() {
        messages.add({"role": "bot", "text": "Error: ${response.statusCode}"});
      });
    }
  } catch (e) {
    setState(() {
      messages.add({"role": "bot", "text": "❌ Failed to connect to server!"});
    });
  } finally {
    setState(() => isLoading = false);
  }
}


  Widget buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFF4CAF50) : Colors.grey[300],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Farmer Chatbot"),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isLoading) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Row(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 10),
                        Text("Typing..."),
                      ],
                    ),
                  );
                }
                final msg = messages[index];
                return buildMessageBubble(
                    msg["text"]!, msg["role"] == "user");
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      hintText: isTamil
                          ? "எதை கேட்க விரும்புகிறீர்கள்?"
                          : "Ask something...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton.small(
                  backgroundColor: Color(0xFF4CAF50),
                  onPressed: sendMessage,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
