import 'package:flutter/material.dart';
import 'package:room_rental_app/ai/gemini_service.dart';
import 'package:room_rental_app/ai_logic/chat_ai_logic_room.dart';

class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({super.key});
  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userText = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isLoading = true;
    });
    _controller.clear();

    String prompt = "";

    if (ChatAiLogic.isAskTotalRooms(userText)) {
      final total = await ChatAiLogic.countTotalRooms();

      prompt = """
      Bạn là trợ lý AI của chủ trọ. 
      Dưới đây là dữ liệu Firestore:
      - Tổng số phòng chủ trọ đang sở hữu: $total
      Câu hỏi: "$userText"
      Hãy trả lời rõ ràng và tự nhiên.
      """;
    }

    else if (ChatAiLogic.isAskAvailableRooms(userText)) {
      final count = await ChatAiLogic.countAvailableRooms();

      prompt = """
      Bạn là trợ lý AI của chủ trọ.
      Dữ liệu Firestore:
      - Số phòng chưa thuê: $count
      Câu hỏi của người dùng: "$userText"
      Hãy trả lời ngắn gọn, tự nhiên, đúng số liệu và thân thiện.
      """;
    }

    else if (ChatAiLogic.isAskMaintainRoom(userText)) {
      final maintain = await ChatAiLogic.countMaintainRooms();

      prompt = """
      Bạn là trợ lý AI của chủ trọ.
      Dữ liệu Firestore:
      - Số phòng đang trong quá trình bảo trì: $maintain
      Câu hỏi của người dùng: "$userText"
      Hãy trả lời ngắn gọn, tự nhiên, đúng số liệu và thân thiện.
      """;
    }

    else if (ChatAiLogic.isAskRentedRoom(userText)) {
      final total = await ChatAiLogic.countTotalRooms();
      final rented = total - await ChatAiLogic.countAvailableRooms();

      prompt = """
      Bạn là trợ lý AI của chủ trọ.
      Dữ liệu Firestore:
      - Số phòng đã thuê: $rented
      Câu hỏi của người dùng: "$userText"
      Hãy trả lời ngắn gọn, tự nhiên, đúng số liệu và thân thiện.
      """;
    }

    else if (userText.toLowerCase().contains("phong re nhat") ||
        userText.toLowerCase().contains("phong gia thap nhat") ||
        userText.toLowerCase().contains("phong co gia thue thap nhat")) {
      final cheapestRooms = await ChatAiLogic.getCheapestRooms();

      String roomsInfo = "";

      if (cheapestRooms.isEmpty) {
        roomsInfo = "Không tìm thấy phòng giá rẻ nào trong hệ thống.";
      } else {
        for (var r in cheapestRooms) {
          roomsInfo += """
        *Phòng:* ${r['title']}
        *Giá:* ${r['price']} VND
        *Trạng thái:* ${r['status']}
        *Mô tả:* ${r['description']}
      """;
        }
      }

      prompt = """
      Bạn là trợ lý AI của chủ trọ.
      Dữ liệu Firestore:
      - Các phòng rẻ nhất:
      $roomsInfo
      Câu hỏi của người dùng: "$userText"
      Hãy trả lời ngắn gọn, tự nhiên, đúng số liệu và thân thiện.
      """;
    }

    else if (userText.toLowerCase().contains("phong dat nhat") ||
        userText.toLowerCase().contains("phong gia cao nhat") ||
        userText.toLowerCase().contains("phong co gia thue cao nhat")) {
      final expensiveRooms = await ChatAiLogic.getExpensiveRooms();

      String roomsInfo = "";

      if (expensiveRooms.isEmpty) {
        roomsInfo = "Không tìm thấy phòng giá rẻ nào trong hệ thống.";
      } else {
        for (var r in expensiveRooms) {
          roomsInfo += """
        *Phòng:* ${r['title']}
        *Giá:* ${r['price']} VND
        *Trạng thái:* ${r['status']}
        *Mô tả:* ${r['description']}
      """;
        }
      }

      prompt = """
      Bạn là trợ lý AI của chủ trọ.
      Dữ liệu Firestore:
      - Các phòng đắt nhất:
      $roomsInfo
      Câu hỏi của người dùng: "$userText"
      Hãy trả lời ngắn gọn, tự nhiên, đúng số liệu và thân thiện.
      """;
    }

    else {
      prompt = """
      Bạn là trợ lý AI cho chủ trọ Việt Nam.
      Trả lời ngắn gọn, tự nhiên.
      Câu hỏi: "$userText"
      """;
    }

    final aiResponse = await GeminiService.generateResponse(prompt);

    setState(() {
      _messages.add({'role': 'ai', 'text': aiResponse});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.smart_toy, size: 60, color: Colors.orange),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chào chủ trọ! 👋\nHỏi mình bất cứ gì nhé!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16, top: 8),
                            child: Row(
                              children: [
                                CircularProgressIndicator(strokeWidth: 2),
                                SizedBox(width: 12),
                                Text('AI đang suy nghĩ...'),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.orange.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: Text(
                            msg['text']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: isUser ? Colors.orange.shade900 : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  backgroundColor: Colors.orange,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}