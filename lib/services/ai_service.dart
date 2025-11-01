import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';
import '../models/menu_item.dart';
import '../models/user_model.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
      if (!ApiKeys.isConfigured) {
        print('⚠️ WARNING: ${ApiKeys.configurationMessage}');
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: ApiKeys.geminiApiKey,
    );
  }

  /// Get food recommendations based on user preferences and menu
  Future<AIRecommendation> getRecommendations({
    required UserModel user,
    required List<MenuItem> availableMenu,
    String? occasion,
  }) async {
    try {
      // Get current day
      final today = _getTodayName();
      
      // Prepare menu context
      final menuContext = _prepareMenuContext(availableMenu);
      
      // Build prompt
      final prompt = _buildPrompt(
        user: user,
        menuContext: menuContext,
        today: today,
        occasion: occasion,
      );

      // Get AI response
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response from AI');
      }

      // Parse response
      return _parseResponse(response.text!, availableMenu);
    } catch (e) {
      print('AI Service Error: $e');
      // Return fallback recommendations
      return _getFallbackRecommendations(availableMenu);
    }
  }

  /// Get quick suggestion for a specific meal type
  Future<String> getQuickSuggestion({
    required String mealType,
    required List<MenuItem> menu,
  }) async {
    try {
      final items = menu.where((item) => 
        item.category.toLowerCase() == mealType.toLowerCase()
      ).take(5).toList();

      if (items.isEmpty) return 'No items available for $mealType';

      final itemNames = items.map((e) => e.name).join(', ');
      
      final prompt = '''
Based on these $mealType items: $itemNames

Give a one-line recommendation (max 15 words) for what to order today.
Just the recommendation, no explanation.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Try something delicious from our $mealType menu!';
    } catch (e) {
      return 'Try our fresh $mealType items today!';
    }
  }

  String _buildPrompt({
    required UserModel user,
    required String menuContext,
    required String today,
    String? occasion,
  }) {
    return '''
You are a helpful food recommendation assistant for a college canteen.

User Profile:
- Name: ${user.name}
- Preferences: ${user.preferences.isEmpty ? 'None specified' : user.preferences.join(', ')}
- Day: $today
${occasion != null ? '- Occasion: $occasion' : ''}

Available Menu Today:
$menuContext

Task: Recommend 3-5 food items from the available menu that would be perfect for this user.

Consider:
1. Day of the week (people prefer lighter food on Mondays, heartier on Fridays)
2. User preferences if specified
3. Balanced nutrition (mix of main course, sides, beverages)
4. Popular combinations

Format your response EXACTLY like this:
RECOMMENDATIONS:
1. [Item Name] - [One line reason]
2. [Item Name] - [One line reason]
3. [Item Name] - [One line reason]

COMBO SUGGESTION:
[Suggest a combo of 2-3 items that go well together]

REASON:
[One paragraph explaining why these recommendations suit the user]
''';
  }

  String _prepareMenuContext(List<MenuItem> menu) {
    if (menu.isEmpty) return 'No items available';
    
    final categories = <String, List<String>>{};
    
    for (var item in menu) {
      if (!categories.containsKey(item.category)) {
        categories[item.category] = [];
      }
      categories[item.category]!.add(
        '${item.name} (₹${item.price.toInt()}) ${item.isVeg ? "🌱" : "🍖"}'
      );
    }

    final buffer = StringBuffer();
    categories.forEach((category, items) {
      buffer.writeln('$category:');
      buffer.writeln(items.take(10).join(', '));
      buffer.writeln();
    });

    return buffer.toString();
  }

  AIRecommendation _parseResponse(String response, List<MenuItem> menu) {
    final recommendations = <MenuItem>[];
    String comboSuggestion = '';
    String reason = '';

    try {
      // Extract recommendations
      final recSection = response.split('RECOMMENDATIONS:')[1].split('COMBO SUGGESTION:')[0];
      final lines = recSection.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      for (var line in lines) {
        // Extract item name from "1. Item Name - Reason" format
        final match = RegExp(r'\d+\.\s*([^-]+)').firstMatch(line);
        if (match != null) {
          final itemName = match.group(1)?.trim() ?? '';
          // Find matching menu item
          final item = menu.firstWhere(
            (m) => m.name.toLowerCase() == itemName.toLowerCase(),
            orElse: () => menu.first,
          );
          if (!recommendations.contains(item)) {
            recommendations.add(item);
          }
        }
      }

      // Extract combo suggestion
      if (response.contains('COMBO SUGGESTION:')) {
        comboSuggestion = response
            .split('COMBO SUGGESTION:')[1]
            .split('REASON:')[0]
            .trim();
      }

      // Extract reason
      if (response.contains('REASON:')) {
        reason = response.split('REASON:')[1].trim();
      }
    } catch (e) {
      print('Parse error: $e');
    }

    // Ensure we have at least 3 recommendations
    if (recommendations.length < 3) {
      final popular = menu.take(5).toList();
      for (var item in popular) {
        if (!recommendations.contains(item) && recommendations.length < 5) {
          recommendations.add(item);
        }
      }
    }

    return AIRecommendation(
      recommendedItems: recommendations.take(5).toList(),
      comboSuggestion: comboSuggestion.isEmpty 
          ? 'Try combining our popular dishes for a complete meal!' 
          : comboSuggestion,
      reason: reason.isEmpty 
          ? 'These items are popular and highly rated by students.' 
          : reason,
    );
  }

  AIRecommendation _getFallbackRecommendations(List<MenuItem> menu) {
    // Fallback: Just return top items from different categories
    final recommendations = <MenuItem>[];
    
    final categories = ['Breakfast', 'Rice', 'Curry', 'Snacks', 'Beverages'];
    
    for (var category in categories) {
      final item = menu.firstWhere(
        (m) => m.category == category,
        orElse: () => menu.isNotEmpty ? menu.first : _createDummyItem(),
      );
      if (!recommendations.contains(item)) {
        recommendations.add(item);
      }
      if (recommendations.length >= 5) break;
    }

    return AIRecommendation(
      recommendedItems: recommendations,
      comboSuggestion: 'Try our popular combo meals for a complete dining experience!',
      reason: 'These are our most popular items, loved by students every day.',
    );
  }

  MenuItem _createDummyItem() {
    return MenuItem(
      id: 'dummy',
      name: 'Special Item',
      category: 'Special',
      price: 50,
      description: 'Try our daily special',
      isVeg: true,
    );
  }

  String _getTodayName() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[DateTime.now().weekday - 1];
  }
}

class AIRecommendation {
  final List<MenuItem> recommendedItems;
  final String comboSuggestion;
  final String reason;

  AIRecommendation({
    required this.recommendedItems,
    required this.comboSuggestion,
    required this.reason,
  });
}