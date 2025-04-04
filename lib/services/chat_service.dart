import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  OpenAI? _openAI;

  OpenAI get openAI {
    if (_openAI == null) {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      _openAI = OpenAI.instance.build(
        token: apiKey,
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),

      );
    }
    return _openAI!;
  }

  Future<String> sendMessage(String message) async {
    final request = ChatCompleteText(
      messages: [
        {"role": "system", "content": "You are an AI English tutor. "
            "Try to teach the user some vocabulary and grammar but make it using sentences "
            "and by correcting. Not make it explicitly. "
            "If user asks for something unrelated to learning english, "
            "such as 'what do you think about elon musk' "
            "remind the user about your aim and don't answer users question."},
        {"role": "user", "content": message},
      ],
      maxToken: 200,
      model: Gpt4oMiniChatModel(),
    );

    final response = await openAI.onChatCompletion(request: request);

    if (response != null &&
        response.choices != null &&
        response.choices!.isNotEmpty) {
      return response.choices!.first.message!.content;
    } else {
      return "AI yanıt veremedi.";
    }
  }
}
