import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PostLabQuizModal extends StatefulWidget {
  final VoidCallback onQuizCompleted;

  const PostLabQuizModal({super.key, required this.onQuizCompleted});

  @override
  State<PostLabQuizModal> createState() => _PostLabQuizModalState();
}

class _PostLabQuizModalState extends State<PostLabQuizModal> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  int _score = 0;
  bool _quizFinished = false;

  final questions = [
    {
      'question': '1. Which OSI Layer is responsible for logical IP routing between subnets?',
      'options': ['Layer 1 (Physical)', 'Layer 2 (Data Link)', 'Layer 3 (Network)', 'Layer 4 (Transport)'],
      'correct': 2,
    },
    {
      'question': '2. What is the broadcast IP address for subnet 192.168.1.0/24?',
      'options': ['192.168.1.0', '192.168.1.1', '192.168.1.254', '192.168.1.255'],
      'correct': 3,
    },
    {
      'question': '3. Which cable type is required to connect two host PCs directly without a switch?',
      'options': ['Straight-Through Cable', 'Crossover Cable', 'Console Cable', 'Coaxial Cable'],
      'correct': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_quizFinished) {
      final passed = _score >= 2;
      return AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(passed ? Icons.emoji_events : Icons.refresh, color: passed ? Colors.amber : AppColors.error),
            const SizedBox(width: 10),
            Text(passed ? 'Module Knowledge Check Passed!' : 'Quiz Attempt Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You scored $_score / ${questions.length} correct answers.'),
            const SizedBox(height: 12),
            if (passed)
              const Text(
                '🎉 Outstanding! You earned +100 XP and unlocked the Module Master Badge!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                'Review the OSI & Subnetting materials and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (passed) widget.onQuizCompleted();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: passed ? AppColors.success : AppColors.primaryAccent,
              foregroundColor: const Color(0xFF0F172A),
            ),
            child: Text(passed ? 'Claim XP & Continue' : 'Try Again'),
          ),
        ],
      );
    }

    final q = questions[_currentQuestionIndex];

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.school, color: AppColors.primaryAccent),
          const SizedBox(width: 10),
          Text('Post-Lab Quiz (${_currentQuestionIndex + 1}/${questions.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
              backgroundColor: theme.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
            ),
            const SizedBox(height: 16),
            Text(
              q['question'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...List.generate((q['options'] as List).length, (idx) {
              final isSel = _selectedAnswer == idx;
              final text = (q['options'] as List)[idx] as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedAnswer = idx),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryAccent.withOpacity(0.15) : theme.canvasColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSel ? AppColors.primaryAccent : theme.dividerColor,
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSel ? AppColors.primaryAccent : theme.hintColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _selectedAnswer == null
              ? null
              : () {
                  if (_selectedAnswer == q['correct']) {
                    _score++;
                  }
                  if (_currentQuestionIndex < questions.length - 1) {
                    setState(() {
                      _currentQuestionIndex++;
                      _selectedAnswer = null;
                    });
                  } else {
                    setState(() {
                      _quizFinished = true;
                    });
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: const Color(0xFF0F172A),
          ),
          child: Text(_currentQuestionIndex < questions.length - 1 ? 'Next Question' : 'Finish Quiz'),
        ),
      ],
    );
  }
}
