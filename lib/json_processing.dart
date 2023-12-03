import 'dart:convert';
import 'package:http/http.dart' as http;

class JsonProcessing {
  static bool isLoopStart(String label) => label.startsWith('LOOPSIGN_START');

  static bool isLoopEnd(String label) => label == 'LOOPSIGN_END';

  static Map<String, String> parseMarker(String label) {
    final parts = label.split('_');
    if (parts.length == 3) {
      return {'color': parts[0].toLowerCase(), 'sign': 'ARROW_${parts[2]}'};
    }
    return {};
  }

  static List<Map<String, dynamic>> sortDetections(List<Map<String, dynamic>> results) {
    results.sort((a, b) => a['box'][1].compareTo(b['box'][1])); // Compare by the Y-coordinate
    return results;
  }

  static List<dynamic> processMarkers(List<Map<String, dynamic>> results) {
    List<dynamic> jsonObjects = [];
    Map<String, dynamic>? currentLoop;

    for (var result in results) {
      String label = result['tag'];

      if (isLoopStart(label)) {
        currentLoop = {
          'loopsign': {'cycles': int.parse(label.split('_').last), 'children': <Map<String, dynamic>>[]}
        };
        continue;
      }

      if (isLoopEnd(label)) {
        if (currentLoop != null) {
          jsonObjects.add(currentLoop);
          currentLoop = null;
        }
        continue;
      }

      var markerInfo = parseMarker(label);
      if (markerInfo.isNotEmpty) {
        if (currentLoop != null) {
          currentLoop['loopsign']['children'].add({'singlesign': markerInfo});
        } else {
          jsonObjects.add({'singlesign': markerInfo});
        }
      }
    }

    return jsonObjects;
  }

  static String generateJson(List<Map<String, dynamic>> results) {
    final processedMarkers = processMarkers(results);
    return jsonEncode(processedMarkers);
  }

  static Future<void> sendJsonToApi(String jsonOutput) async {
    var url = Uri.parse('https://httpbin.org/post');
    var response = await http.post(url, body: jsonOutput, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      // Handle successful response
      print("Data sent successfully: ${response.body}");
    } else {
      // Handle error response
      print("Failed to send data: ${response.statusCode}");
    }
  }
}
