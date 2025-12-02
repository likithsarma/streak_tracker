import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '30 Day Challenge Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardPage(),
    const HabitsPage(),
    const JournalPage(),
    const CalendarPage(),
    const StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Habits'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
          ],
        ),
      ),
    );
  }
}

// Dashboard Page
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _progress = {};
  int _currentDay = 1;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalPoints = 0;
  bool _hasStreakFreeze = true;
  String _dailyQuote = '';
  List<dynamic> _customHabits = [];

  final List<String> _motivationalQuotes = [
    "The only way to do great work is to love what you do. - Steve Jobs",
    "Success is not final, failure is not fatal: it is the courage to continue that counts. - Winston Churchill",
    "Believe you can and you're halfway there. - Theodore Roosevelt",
    "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
    "It does not matter how slowly you go as long as you do not stop. - Confucius",
    "Everything you've ever wanted is on the other side of fear. - George Addair",
    "Believe in yourself. You are braver than you think. - Roy T. Bennett",
    "I am not a product of my circumstances. I am a product of my decisions. - Stephen Covey",
    "The only impossible journey is the one you never begin. - Tony Robbins",
    "Success is walking from failure to failure with no loss of enthusiasm. - Winston Churchill",
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _setDailyQuote();
  }

  void _setDailyQuote() {
    final today = DateTime.now().day;
    setState(() {
      _dailyQuote = _motivationalQuotes[today % _motivationalQuotes.length];
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final startDate = prefs.getString('start_date');
    
    if (startDate == null) {
      await prefs.setString('start_date', DateTime.now().toIso8601String());
      setState(() => _currentDay = 1);
    } else {
      final start = DateTime.parse(startDate);
      final diff = DateTime.now().difference(start).inDays + 1;
      setState(() => _currentDay = diff > 30 ? 30 : diff);
    }

    final progressData = prefs.getString('progress') ?? '{}';
    setState(() => _progress = json.decode(progressData));
    
    final customHabitsData = prefs.getString('custom_habits') ?? '[]';
    setState(() => _customHabits = json.decode(customHabitsData));
    
    _calculateStreaks();
    _calculatePoints();
    
    _bestStreak = prefs.getInt('best_streak') ?? 0;
    _hasStreakFreeze = prefs.getBool('streak_freeze') ?? true;
  }

  void _calculateStreaks() {
    int streak = 0;
    int current = 0;
    final today = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      if (_progress.containsKey(dateStr)) {
        final dayData = _progress[dateStr];
        final completed = _isFullyCompleted(dayData);
        
        if (completed) {
          current++;
          if (current > streak) streak = current;
        } else if (i == 0 && _hasStreakFreeze) {
          // Use streak freeze for today
          continue;
        } else {
          current = 0;
        }
      } else if (i == 0 && _hasStreakFreeze) {
        continue;
      } else {
        current = 0;
      }
    }
    
    setState(() => _currentStreak = current);
  }

  bool _isFullyCompleted(Map<String, dynamic> dayData) {
    final defaultHabits = ['exercise', 'sleep', 'water', 'reading'];
    for (var habit in defaultHabits) {
      if (dayData[habit] != true) return false;
    }
    for (var customHabit in _customHabits) {
      final habitKey = customHabit['name'].toString().toLowerCase();
      if (dayData[habitKey] != true) return false;
    }
    return true;
  }

  void _calculatePoints() {
    int points = 0;
    _progress.forEach((date, dayData) {
      dayData.forEach((habit, completed) {
        if (completed == true && habit != 'note') points += 10;
      });
    });
    setState(() => _totalPoints = points);
  }

  int _getCompletedDays() {
    return _progress.values.where((day) => _isFullyCompleted(day)).length;
  }

  void _showReflectionDialog() {
    final gratitudeController = TextEditingController();
    final learningController = TextEditingController();
    final tomorrowController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evening Reflection 🌙'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gratitudeController,
                decoration: const InputDecoration(
                  labelText: 'What are you grateful for today?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: learningController,
                decoration: const InputDecoration(
                  labelText: 'What did you learn today?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tomorrowController,
                decoration: const InputDecoration(
                  labelText: 'Top priority for tomorrow?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final reflectionsData = prefs.getString('reflections') ?? '{}';
              final reflections = json.decode(reflectionsData);
              
              reflections[today] = {
                'gratitude': gratitudeController.text,
                'learning': learningController.text,
                'tomorrow': tomorrowController.text,
              };
              
              await prefs.setString('reflections', json.encode(reflections));
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reflection saved! 🌟')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _resetChallenge() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Challenge?'),
        content: const Text('This will delete all your progress and start fresh. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              setState(() {
                _progress = {};
                _currentDay = 1;
                _currentStreak = 0;
                _totalPoints = 0;
              });
              Navigator.pop(context);
              _loadProgress();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedDays = _getCompletedDays();
    final progressPercent = (completedDays / 30 * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '30 Day Challenge',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Day $_currentDay/30',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _resetChallenge,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: completedDays / 30,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$progressPercent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$completedDays of 30 days',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Daily Quote
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade300, Colors.orange.shade400],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.format_quote, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dailyQuote,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Quick Stats
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('🔥 Streak', '$_currentStreak days', Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('⭐ Points', '$_totalPoints', Colors.purple)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('🏆 Best', '$_bestStreak days', Colors.blue)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Today's Progress
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHabitCard('Exercise', '30 minutes', Icons.fitness_center, Colors.orange),
                    _buildHabitCard('Sleep', '7-8 hours', Icons.bedtime, Colors.blue),
                    _buildHabitCard('Water', '8 glasses', Icons.water_drop, Colors.cyan),
                    _buildHabitCard('Reading', '30 minutes', Icons.book, Colors.green),
                    
                    // Custom Habits
                    ..._customHabits.map((habit) => _buildHabitCard(
                      habit['name'],
                      habit['goal'] ?? '',
                      IconData(habit['icon'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons'),
                      Color(habit['color'] ?? Colors.purple.value),
                    )),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showReflectionDialog,
                            icon: const Icon(Icons.nightlight),
                            label: const Text('Evening Reflection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(String title, String goal, IconData icon, Color color) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isCompleted = _progress[today]?[title.toLowerCase()] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (goal.isNotEmpty)
                  Text(
                    goal,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? Colors.green : Colors.grey[300],
            size: 28,
          ),
        ],
      ),
    );
  }
}

// Habits Page
class HabitsPage extends StatefulWidget {
  const HabitsPage({Key? key}) : super(key: key);

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  Map<String, dynamic> _todayProgress = {};
  List<dynamic> _customHabits = [];
  
  final List<Map<String, dynamic>> _defaultHabits = [
    {'name': 'Exercise', 'icon': Icons.fitness_center, 'color': Colors.orange},
    {'name': 'Sleep', 'icon': Icons.bedtime, 'color': Colors.blue},
    {'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {'name': 'Reading', 'icon': Icons.book, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayProgress();
    _loadCustomHabits();
  }

  Future<void> _loadCustomHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final customHabitsData = prefs.getString('custom_habits') ?? '[]';
    setState(() {
      _customHabits = json.decode(customHabitsData);
    });
  }

  Future<void> _loadTodayProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString('progress') ?? '{}';
    final allProgress = json.decode(progressData);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    setState(() {
      _todayProgress = allProgress[today] ?? {};
    });
  }

  Future<void> _toggleHabit(String habitName) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString('progress') ?? '{}';
    final allProgress = json.decode(progressData);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    if (allProgress[today] == null) {
      allProgress[today] = {};
    }
    
    final key = habitName.toLowerCase();
    final newValue = !(allProgress[today][key] ?? false);
    allProgress[today][key] = newValue;
    
    await prefs.setString('progress', json.encode(allProgress));
    
    if (newValue) {
      _showNoteDialog(habitName);
    }
    
    _loadTodayProgress();
  }

  void _showNoteDialog(String habitName) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Add a note for $habitName'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'How did it go? (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final notesData = prefs.getString('habit_notes') ?? '{}';
                  final notes = json.decode(notesData);
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  
                  if (notes[today] == null) notes[today] = {};
                  notes[today][habitName.toLowerCase()] = controller.text;
                  
                  await prefs.setString('habit_notes', json.encode(notes));
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addCustomHabit() {
    final nameController = TextEditingController();
    final goalController = TextEditingController();
    Color selectedColor = Colors.purple;
    IconData selectedIcon = Icons.star;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Habit Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(
                    labelText: 'Goal (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose Icon:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Icons.star,
                    Icons.favorite,
                    Icons.psychology,
                    Icons.emoji_events,
                    Icons.spa,
                    Icons.self_improvement,
                  ].map((icon) => InkWell(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == icon ? Colors.purple.withOpacity(0.2) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 32),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.indigo,
                    Colors.teal,
                    Colors.amber,
                  ].map((color) => InkWell(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final customHabitsData = prefs.getString('custom_habits') ?? '[]';
                  final customHabits = json.decode(customHabitsData);
                  
                  customHabits.add({
                    'name': nameController.text,
                    'goal': goalController.text,
                    'icon': selectedIcon.codePoint,
                    'color': selectedColor.value,
                  });
                  
                  await prefs.setString('custom_habits', json.encode(customHabits));
                  _loadCustomHabits();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHabits = [..._defaultHabits];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Habits'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addCustomHabit,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Track Your Habits',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to mark as complete and add notes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ...allHabits.map((habit) => _buildHabitTile(habit)),
          ..._customHabits.map((habit) => _buildHabitTile({
            'name': habit['name'],
            'icon': IconData(habit['icon'], fontFamily: 'MaterialIcons'),
            'color': Color(habit['color']),
          })),
        ],
      ),
    );
  }

  Widget _buildHabitTile(Map<String, dynamic> habit) {
    final isCompleted = _todayProgress[habit['name'].toLowerCase()] == true;

    return GestureDetector(
      onTap: () => _toggleHabit(habit['name']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCompleted ? habit['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? habit['color'] : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: habit['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(habit['icon'], color: habit['color'], size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'Completed ✓' : 'Not yet completed',
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? Colors.green : Colors.grey[300],
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

// Journal Page
class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  Map<String, dynamic> _reflections = {};
  Map<String, dynamic> _habitNotes = {};

  @override
  void initState() {
    super.initState();
    _loadReflections();
    _loadHabitNotes();
  }

  Future<void> _loadReflections() async {
    final prefs = await SharedPreferences.getInstance();
    final reflectionsData = prefs.getString('reflections') ?? '{}';
    setState(() {
      _reflections = json.decode(reflectionsData);
    });
  }

  Future<void> _loadHabitNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = prefs.getString('habit_notes') ?? '{}';
    setState(() {
      _habitNotes = json.decode(notesData);
    });
  }

  void _exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final allData = {
      'reflections': _reflections,
      'habit_notes': _habitNotes,
      'progress': prefs.getString('progress') ?? '{}',
    };
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: SingleChildScrollView(
          child: Text(
            json.encode(allData),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = _reflections.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal & Notes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _exportData,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: sortedDates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No reflections yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your evening reflection from the dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final reflection = _reflections[date];
                final dateTime = DateTime.parse(date);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.deepPurple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, MMMM d').format(dateTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReflectionItem('🙏 Gratitude', reflection['gratitude']),
                      _buildReflectionItem('📚 Learning', reflection['learning']),
                      _buildReflectionItem('🎯 Tomorrow', reflection['tomorrow']),
                      
                      if (_habitNotes[date] != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Habit Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_habitNotes[date] as Map).entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${entry.key}: ${entry.value}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildReflectionItem(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// Calendar Page
class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<String, dynamic> _progress = {};
  List<dynamic> _customHabits = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadCustomHabits();
  }

  Future<void> _loadCustomHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final customHabitsData = prefs.getString('custom_habits') ?? '[]';
    setState(() {
      _customHabits = json.decode(customHabitsData);
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString('progress') ?? '{}';
    setState(() {
      _progress = json.decode(progressData);
    });
  }

  bool _isFullyCompleted(Map<String, dynamic>? dayData) {
    if (dayData == null) return false;
    final defaultHabits = ['exercise', 'sleep', 'water', 'reading'];
    for (var habit in defaultHabits) {
      if (dayData[habit] != true) return false;
    }
    for (var customHabit in _customHabits) {
      final habitKey = customHabit['name'].toString().toLowerCase();
      if (dayData[habitKey] != true) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('30-Day Calendar'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your 30-Day Journey',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Heat map of your progress',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 30,
              itemBuilder: (context, index) {
                final dayNumber = index + 1;
                final date = today.subtract(Duration(days: 29 - index));
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final dayData = _progress[dateStr];
                final isCompleted = _isFullyCompleted(dayData);
                final isToday = DateFormat('yyyy-MM-dd').format(today) == dateStr;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green
                        : dayData != null && dayData.isNotEmpty
                            ? Colors.orange.withOpacity(0.5)
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: Colors.deepPurple, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: isCompleted || (dayData != null && dayData.isNotEmpty)
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendItem(Colors.green, 'All habits completed'),
          _buildLegendItem(Colors.orange.withOpacity(0.5), 'Partially completed'),
          _buildLegendItem(Colors.grey[200]!, 'Not started'),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.deepPurple, width: 3),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

// Stats Page
class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, dynamic> _progress = {};
  List<dynamic> _customHabits = [];
  int _totalDays = 0;
  int _completedDays = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  Map<String, int> _habitStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString('progress') ?? '{}';
    final customHabitsData = prefs.getString('custom_habits') ?? '[]';
    
    setState(() {
      _progress = json.decode(progressData);
      _customHabits = json.decode(customHabitsData);
      _totalDays = _progress.length;
    });
    
    _calculateStats();
  }

  void _calculateStats() {
    int completed = 0;
    Map<String, int> stats = {};
    
    _progress.forEach((date, dayData) {
      if (_isFullyCompleted(dayData)) {
        completed++;
      }
      
      dayData.forEach((habit, value) {
        if (value == true && habit != 'note') {
          stats[habit] = (stats[habit] ?? 0) + 1;
        }
      });
    });
    
    setState(() {
      _completedDays = completed;
      _habitStats = stats;
    });
    
    _calculateStreaks();
  }

  bool _isFullyCompleted(Map<String, dynamic> dayData) {
    final defaultHabits = ['exercise', 'sleep', 'water', 'reading'];
    for (var habit in defaultHabits) {
      if (dayData[habit] != true) return false;
    }
    for (var customHabit in _customHabits) {
      final habitKey = customHabit['name'].toString().toLowerCase();
      if (dayData[habitKey] != true) return false;
    }
    return true;
  }

  void _calculateStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;
    
    final sortedDates = _progress.keys.toList()..sort();
    
    for (var date in sortedDates) {
      if (_isFullyCompleted(_progress[date])) {
        tempStreak++;
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }
    
    // Check current streak from today backwards
    final today = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      if (_progress.containsKey(dateStr) && _isFullyCompleted(_progress[dateStr])) {
        currentStreak++;
      } else {
        break;
      }
    }
    
    await prefs.setInt('best_streak', bestStreak);
    
    setState(() {
      _currentStreak = currentStreak;
      _bestStreak = bestStreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _totalDays > 0 
        ? (_completedDays / _totalDays * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '📅 Total Days',
                  '$_totalDays',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '✅ Completed',
                  '$_completedDays',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '🔥 Current Streak',
                  '$_currentStreak',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '🏆 Best Streak',
                  '$_bestStreak',
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            '📊 Completion Rate',
            '$completionRate%',
            Colors.teal,
            fullWidth: true,
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Habit Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._habitStats.entries.map((entry) {
            final percentage = _totalDays > 0 
                ? (entry.value / _totalDays * 100).toInt()
                : 0;
            return _buildHabitProgressBar(
              entry.key.toUpperCase(),
              entry.value,
              _totalDays,
              percentage,
            );
          }),
          
          if (_habitStats.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.analytics, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No data yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start tracking your habits to see statistics',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: fullWidth ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitProgressBar(String habit, int completed, int total, int percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                habit,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$completed/$total',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForPercentage(percentage),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage% completion',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return Colors.red;
  }
}