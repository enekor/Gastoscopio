import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionApi {
  static Future<String> recognizeText(File imageFile) async {
    if (imageFile == null) {
      return 'No selected image';
    } else {
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(InputImage.fromFile(imageFile));
      String text = extractText(recognizedText);
      return text;
    }
  }

  static extractText(RecognizedText text) {
    String resultText = '';

    for (TextBlock block in text.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          resultText += element.text + ' ';
        }
        resultText += '\n';
      }
    }

    return resultText.isEmpty ? 'No text found in the image' : resultText;
  }
}
