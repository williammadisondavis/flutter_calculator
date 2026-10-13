import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

// The main app controls the light and dark themes.
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool isDarkMode = true;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 300),
      home: CalculatorPage(isDarkMode: isDarkMode, onThemeChanged: toggleTheme),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const CalculatorPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  // These variables hold the calculator's current state.
  String currentInput = '0';
  double? accumulator;
  String? pendingOperator;

  bool awaitingOperand = false;
  bool calculationFinished = false;
  String? errorMessage;

  // Convert a number into readable text.
  String formatNumber(double number) {
    if (!number.isFinite) {
      return 'Error';
    }

    if (number == 0) {
      return '0';
    }

    String result = number.toStringAsPrecision(12);

    if (result.contains('e') || result.contains('E')) {
      return result;
    }

    if (result.contains('.')) {
      result = result.replaceFirst(RegExp(r'0+$'), '');
      result = result.replaceFirst(RegExp(r'\.$'), '');
    }

    return result;
  }

  // Reset the entire calculator.
  void clearCalculator() {
    setState(() {
      currentInput = '0';
      accumulator = null;
      pendingOperator = null;
      awaitingOperand = false;
      calculationFinished = false;
      errorMessage = null;
    });
  }

  // Process number button presses.
  void enterDigit(String digit) {
    setState(() {
      if (errorMessage != null || calculationFinished) {
        currentInput = '0';
        accumulator = null;
        pendingOperator = null;
        awaitingOperand = false;
        calculationFinished = false;
        errorMessage = null;
      }

      if (awaitingOperand) {
        currentInput = digit;
        awaitingOperand = false;
      } else if (currentInput == '0') {
        currentInput = digit;
      } else if (currentInput == '-0') {
        currentInput = digit == '0' ? '-0' : '-$digit';
      } else if (currentInput.length < 15) {
        currentInput += digit;
      }
    });
  }

  // The four basic arithmetic operations.
  double? calculate(double first, double second, String operation) {
    switch (operation) {
      case '+':
        return first + second;
      case '−':
        return first - second;
      case '×':
        return first * second;
      case '÷':
        if (second == 0) {
          return null;
        }
        return first / second;
      default:
        return null;
    }
  }

  // Show a recoverable error instead of crashing.
  void showError() {
    currentInput = 'Error';
    errorMessage = 'Cannot divide by zero. Press AC to reset.';
    accumulator = null;
    pendingOperator = null;
    awaitingOperand = false;
    calculationFinished = false;
  }

  // Apply the previous operation before saving the next one.
  // This makes calculations evaluate LEFT TO RIGHT.
  void chooseOperator(String operation) {
    setState(() {
      if (errorMessage != null) {
        return;
      }

      if (pendingOperator != null) {
        // Pressing two operators in a row replaces the old one.
        if (awaitingOperand) {
          pendingOperator = operation;
          return;
        }

        final double second = double.parse(currentInput);
        final double? result = calculate(
          accumulator!,
          second,
          pendingOperator!,
        );

        if (result == null || !result.isFinite) {
          showError();
          return;
        }

        accumulator = result;
        currentInput = formatNumber(result);
      } else {
        accumulator = double.parse(currentInput);
      }

      pendingOperator = operation;
      awaitingOperand = true;
      calculationFinished = false;
    });
  }

  // Finish the calculation when equals is pressed.
  void pressEquals() {
    setState(() {
      if (errorMessage != null) {
        return;
      }

      // Equals does nothing without a complete operation.
      if (pendingOperator == null || awaitingOperand) {
        return;
      }

      final double second = double.parse(currentInput);
      final double? result = calculate(accumulator!, second, pendingOperator!);

      if (result == null || !result.isFinite) {
        showError();
        return;
      }

      currentInput = formatNumber(result);
      accumulator = null;
      pendingOperator = null;
      awaitingOperand = false;
      calculationFinished = true;
    });
  }

  // Toggle the sign of the current number.
  void toggleSign() {
    setState(() {
      if (errorMessage != null) {
        return;
      }

      if (awaitingOperand) {
        currentInput = '-0';
        awaitingOperand = false;
        return;
      }

      if (currentInput.startsWith('-')) {
        currentInput = currentInput.substring(1);
      } else {
        currentInput = '-$currentInput';
      }
    });
  }

  // Send each button to the correct function.
  void handleButton(String value) {
    if (RegExp(r'^[0-9]$').hasMatch(value)) {
      enterDigit(value);
    } else if (value == 'AC') {
      clearCalculator();
    } else if (value == '±') {
      toggleSign();
    } else if (value == '=') {
      pressEquals();
    } else {
      chooseOperator(value);
    }
  }

  // Build a button with consistent spacing and touch feedback.
  Widget calculatorButton(String value, {int flex = 1}) {
    final bool isOperator = ['+', '−', '×', '÷'].contains(value);
    final bool isEquals = value == '=';
    final bool isSpecial = value == 'AC' || value == '±';

    final ColorScheme colors = Theme.of(context).colorScheme;

    Color background = colors.surfaceContainerHigh;
    Color foreground = colors.onSurface;

    if (isOperator) {
      background = colors.secondaryContainer;
      foreground = colors.onSecondaryContainer;
    } else if (isSpecial) {
      background = colors.tertiaryContainer;
      foreground = colors.onTertiaryContainer;
    } else if (isEquals) {
      background = colors.primary;
      foreground = colors.onPrimary;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Semantics(
          label: value == '÷'
              ? 'Divide'
              : value == '×'
              ? 'Multiply'
              : value == '−'
              ? 'Subtract'
              : value == '+'
              ? 'Add'
              : value == '='
              ? 'Equals'
              : value == 'AC'
              ? 'All clear'
              : value == '±'
              ? 'Change sign'
              : value,
          child: ElevatedButton(
            onPressed: () => handleButton(value),
            style: ElevatedButton.styleFrom(
              backgroundColor: background,
              foregroundColor: foreground,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonRow(List<String> values) {
    return Expanded(
      child: Row(
        children: values.map((value) {
          return calculatorButton(value);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    String operationText = '';

    if (pendingOperator != null && accumulator != null) {
      operationText = '${formatNumber(accumulator!)} $pendingOperator';
    } else if (calculationFinished) {
      operationText = 'Result';
    } else {
      operationText = 'Ready';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Toggle light and dark theme',
            onPressed: widget.onThemeChanged,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Calculator display.
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        operationText,
                        style: TextStyle(
                          fontSize: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 75,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            currentInput,
                            style: const TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: TextStyle(color: colors.error, fontSize: 13),
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Calculator keypad.
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    buttonRow(['7', '8', '9', '÷']),
                    buttonRow(['4', '5', '6', '×']),
                    buttonRow(['1', '2', '3', '−']),
                    buttonRow(['AC', '0', '±', '+']),
                    Expanded(child: Row(children: [calculatorButton('=')])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
