import 'dart:io';
import 'package:flutter/material.dart';
import 'package:enjaz/database_helper.dart';
import 'package:enjaz/achievement.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إنجازات ',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'ComicNeue',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> children = [
    {'name': 'سلمى', 'emoji': '🦄'},
    {'name': 'جنى', 'emoji': '🦋'},
    {'name': 'هنا', 'emoji': '🌟'},
  ];
  final Map<String, int?> selectedNumbers = {};
  Map<String, int> todayAchievements = {};

  @override
  void initState() {
    super.initState();
    for (var child in children) {
      selectedNumbers[child['name']!] = null;
    }
    _loadTodayAchievements();
  }

  Future<void> _loadTodayAchievements() async {
    for (var child in children) {
      final achievements = await DatabaseHelper.instance.getTodayAchievements(child['name']!);
      if (achievements.isNotEmpty) {
        setState(() {
          todayAchievements[child['name']!] = achievements.first.achievementNumber;
        });
      }
    }
  }

  Future<void> _saveAchievement(String childName, int number) async {
    try {
      await DatabaseHelper.instance.insertAchievement(
        childName,
        number,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3E0), // Soft pastel background
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.purple[100],
          title: const Text(
            'إنجازات ',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView.builder(
          itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            return Card(
              color: Colors.purple[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 6,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          child['emoji']!,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          child['name']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<int>(
                      future: DatabaseHelper.instance.getTotalAchievements(child['name']!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            'إجمالي الإنجازات: ${snapshot.data}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List>(
                      future: DatabaseHelper.instance.getTodayAchievements(child['name']!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final todayAchievement = snapshot.data!.first.achievementNumber;
                          return Text(
                            'إنجاز اليوم: $todayAchievement',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return const Text(
                            'إنجاز اليوم: لا يوجد',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.purple[200]!, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              Map<String, bool> selectedAchievements = {
                                'النوم قبل العاشرة': false,
                                'النوم نصف ساعه فقط بالنهار': false,
                                'الصلاة على وقتها': false,
                              };
                              
                              return StatefulBuilder(
                                builder: (BuildContext context, StateSetter setState) {
                                  return AlertDialog(
                                    title: const Text('إنجازات اليوم'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: selectedAchievements.keys.map((achievement) {
                                        return CheckboxListTile(
                                          title: Text(achievement),
                                          value: selectedAchievements[achievement],
                                          onChanged: (bool? value) {
                                            setState(() {
                                              selectedAchievements[achievement] = value ?? false;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('إلغاء'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          int totalAchievements = selectedAchievements.values
                                              .where((value) => value)
                                              .length;
                                          
                                          if (totalAchievements > 0) {
                                            await _saveAchievement(child['name']!, totalAchievements);
                                            if (mounted) {
                                              setState(() {
                                                todayAchievements[child['name']!] = totalAchievements;
                                              });
                                            }
                                          }
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        child: const Text('حفظ'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[100],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              todayAchievements[child['name']!] != null
                                  ? 'تم إنجاز ${todayAchievements[child['name']!]} مهام'
                                  : 'إضافة إنجازات اليوم',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
