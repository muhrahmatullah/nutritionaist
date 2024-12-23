import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

import 'firebase_options.dart';
import 'model/nutrition_info.dart';

const String prompt = '''
  You are an AI nutrition assistant specialized in calculating the nutritional breakdown of food. Your role is to provide accurate estimates of protein, carbs, fat, and total calories based on the food's name and weight in grams provided by the user. 
  If the input query is unrelated to calorie or nutrition calculation, 
  your output should indicate that the query is irrelevant.
  
  When generating the output, follow these rules:

The output must be in JSON format with the following fields:

relevant: Indicate whether the query pertains to calorie/nutrition breakdown. Return true if relevant, false otherwise.
protein: Provide the protein content as a string in the format X.X gram.
carbs: Provide the carbohydrate content as a string in the format X.X gram.
fat: Provide the fat content as a string in the format X.X gram.
Calories: Provide the total calories as a string in the format XXX cal.
If the food input is not recognized or does not have nutritional data, return "relevant": false and do not include the other fields.

Ensure all outputs are precise, properly formatted, and suitable for use in applications.

For example

Input = "food_name": "Grilled Chicken", "weight_grams": 100
Output
{
  "relevant": true,
  "protein": "31.0 gram",
  "carbs": "0.0 gram",
  "fat": "3.6 gram",
  "Calories": "165 cal"
}
—--------------------
Input = "What is the weather today?"
Output
{
  "relevant": true,
}
Make your response clear, accurate, and formatted exactly as shown in the examples above.
  ''';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Nutritaionist'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GenerativeModel geminiModel = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-1.5-flash',
    systemInstruction: Content.system('you are an expert image generator'),
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  List<TextEditingController> foodControllers = [];
  List<TextEditingController> weightControllers = [];

  @override
  void initState() {
    super.initState();
    _addNewField();
  }

  void _addNewField() {
    setState(() {
      foodControllers.add(TextEditingController());
      weightControllers.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    setState(() {
      foodControllers.removeAt(index);
      weightControllers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    String result = '';
    for (int i = 0; i < foodControllers.length; i++) {
      result += foodControllers[i].text;
      result += ' ${weightControllers[i].text} grams\n';
    }
    print(result);
    final res = await geminiModel.generateContent([Content.text('input: $result')]);
    print(res.text);
    if (res.text != null) {
      try {
        Map<String, dynamic> jsonMap = jsonDecode(res.text!);
        NutritionInfo nutritionInfo = NutritionInfo.fromJson(jsonMap);
        if (nutritionInfo.relevant) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Nutrition Information'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text('Protein: ${nutritionInfo.protein}'),
                    Text('Carbs: ${nutritionInfo.carbs}'),
                    Text('Fat: ${nutritionInfo.fat}'),
                    Text('Calories: ${nutritionInfo.calories}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Not relevant'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Got it'),
                  ),
                ],
              );
            },
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: LlmChatView(provider: VertexProvider(model: geminiModel)));
  }
}
