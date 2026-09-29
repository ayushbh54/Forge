import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class GeminiBrainScreen extends StatefulWidget {
  final String? initialPrompt;
  const GeminiBrainScreen({super.key, this.initialPrompt});

  @override
  State<GeminiBrainScreen> createState() => _GeminiBrainScreenState();
}

class _GeminiBrainScreenState extends State<GeminiBrainScreen> {
  final List<String> _messages = ['Hello! I am Nirmaan AI Copilot. How can I assist you with your project today?'];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AppProvider>();
        _sendMessage(widget.initialPrompt!, provider);
      });
    }
  }

  void _sendMessage(String text, AppProvider provider) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(text);
      _controller.clear();
      _isLoading = true;
    });

    try {
      final res = await provider.apiService.geminiChat(
        'COPILOT_QUERY',
        {'query': text, 'message': text, 'projectId': provider.currentProjectId},
      );
      setState(() {
        if (res != null && res['reply'] != null) {
          _messages.add(res['reply'].toString());
        } else {
          _messages.add('Sorry, I could not process your request at the moment.');
        }
      });
    } catch (e) {
      setState(() {
        _messages.add('Error connecting to AI: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C38),
        title: const Text('Gemini AI Brain Copilot', style: TextStyle(color: Color(0xFFF1F5F9))),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildQuickPrompt('Analyze project health', provider),
                _buildQuickPrompt('Identify risks', provider),
                _buildQuickPrompt('Suggest schedule recovery', provider),
                _buildQuickPrompt('Budget forecast', provider),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                    ),
                  );
                }
                final isUser = index % 2 != 0;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF0284C7) : const Color(0xFF162347),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _messages[index],
                      style: const TextStyle(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF111C38),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFFF1F5F9)),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF162347),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) => _sendMessage(val, provider),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0284C7),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text, provider),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickPrompt(String text, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: const Color(0xFF162347),
        label: Text(text, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
        onPressed: () => _sendMessage(text, provider),
      ),
    );
  }
}
