const fs = require('node:fs');
function edit(file, fn) { const s = fs.readFileSync(file,'utf8').replaceAll('\r\n','\n'); fs.writeFileSync(file,fn(s)); }
edit('lib/screens/warmup_screen.dart', s => {
  s=s.replace('extends State<WarmupScreen> {','extends State<WarmupScreen> with WidgetsBindingObserver {');
  s=s.replace('    _stepTimer?.cancel();\n    super.dispose();','    WidgetsBinding.instance.removeObserver(this);\n    _stepTimer?.cancel();\n    super.dispose();');
  s=s.replace('    super.initState();\n    _startCountdown();','    super.initState();\n    WidgetsBinding.instance.addObserver(this);');
  s=s.replace('  void _startCountdown() {', `  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _stepTimer?.cancel();
      if (mounted) setState(() => _isTimerRunning = false);
    }
  }

  void _startCountdown() {`);
  s=s.replace(`        if (_isResting) {
          _advanceAfterRest();
        } else {
          _beginRest();
        }`, `        setState(() { _secondsRemaining = 0; _isTimerRunning = false; });`);
  s=s.replace('    setState(() => _isTimerRunning = true);\n    _startCountdown();', '    if (_secondsRemaining == 0) return;\n    setState(() => _isTimerRunning = true);\n    _startCountdown();');
  s=s.replace('    });\n    _startCountdown();\n  }\n\n  void _beginRest()', '    });\n  }\n\n  void _beginRest()');
  const a=s.indexOf('  void _beginRest()'); const b=s.indexOf('  void _advanceAfterRest()',a);
  s=s.slice(0,a)+s.slice(b);
  s=s.replace('      _isTimerRunning = true;\n    });\n    _startCountdown();\n  }\n\n  void _startMainWorkout()', '      _isTimerRunning = false;\n    });\n  }\n\n  void _startMainWorkout()');
  s=s.replace('  void _startMainWorkout() {','  void _startMainWorkout() {\n    _stepTimer?.cancel();');
  s=s.replace("  String _formatTime(int seconds) => '00:${seconds.toString().padLeft(2, '0')}';", "  String _formatTime(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';");
  s=s.replace('final progress = 1 - (_secondsRemaining / totalSeconds);','final progress = (1 - (_secondsRemaining / totalSeconds)).clamp(0.0, 1.0);');
  s=s.replace("'Pause timer' : 'Resume timer'", "'Pause timer' : 'Start timer'");
  s=s.replace("? 'The next step starts automatically.'\n                      : 'A $_restDurationSeconds-second rest follows automatically.'", "? 'Continue when you are ready.'\n                      : 'Press Start. Move on when you are ready.'");
  s=s.replace('                Row(\n                  children: [\n                    FilledButton.icon(', '                Wrap(\n                  spacing: 4,\n                  children: [\n                    FilledButton.icon(');
  s=s.replace("tooltip: 'Reset timer',", "tooltip: 'Reset timer',");
  s=s.replace('                    const SizedBox(width: 8),\n                    IconButton(', `                    TextButton(onPressed: () => setState(() => _secondsRemaining += 15), child: const Text('+15 seconds')),
                    IconButton(`);
  s=s.replace('onPressed: _isResting ? _advanceAfterRest : _beginRest,','onPressed: _advanceAfterRest,');
  s=s.replace("_isResting ? 'Skip Rest' : 'Skip to Rest'", "_currentStep == _warmupSteps.length - 1 ? 'Start main workout' : 'Next / Skip step'");
  return s;
});
edit('lib/models/app_state.dart', s => s.replace('    currentDayIndex = 1;', `    currentDayIndex = ((profile['currentDayIndex'] as num?)?.toInt() ?? 1).clamp(1, 1000000);
    notifyListeners();`).replace('    currentDayIndex = currentDayIndex < 5 ? currentDayIndex + 1 : 1;', '    currentDayIndex++;'));
