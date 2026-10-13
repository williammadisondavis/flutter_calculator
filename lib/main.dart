import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

// Controls the light and dark themes.
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
  // Calculator state variables.
  String currentInput = '0';
  double? accumulator;
  String? pendingOperator;

  bool awaitingOperand = false;
  bool calculationFinished = false;
  String? errorMessage;

  // Format numbers without unnecessary decimal zeros.
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

  // Reset all calculator values.
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

  // Handle number input.
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

  // Perform the arithmetic operations.
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

  // Show a division-by-zero error.
  void showError() {
    currentInput = 'Error';
    errorMessage = 'Cannot divide by zero. Press AC to reset.';
    accumulator = null;
    pendingOperator = null;
    awaitingOperand = false;
    calculationFinished = false;
  }

  // Calculate left to right and save the next operator.
  void chooseOperator(String operation) {
    setState(() {
      if (errorMessage != null) {
        return;
      }

      if (pendingOperator != null) {
        // Replace the operator if no second number was entered.
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

  // Complete the calculation.
  void pressEquals() {
    setState(() {
      if (errorMessage != null) {
        return;
      }

      // Ignore equals if there is no completed second operand.
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

  // Change the sign of the entered number.
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

  // Process keypad buttons.
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

  // Create one calculator button.
  Widget calculatorButton(String value) {
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

    String label = value;

    switch (value) {
      case '÷':
        label = 'Divide';
        break;
      case '×':
        label = 'Multiply';
        break;
      case '−':
        label = 'Subtract';
        break;
      case '+':
        label = 'Add';
        break;
      case '=':
        label = 'Equals';
        break;
      case 'AC':
        label = 'All clear';
        break;
      case '±':
        label = 'Change sign';
        break;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Semantics(
          label: label,
          button: true,
          child: ElevatedButton(
            onPressed: () => handleButton(value),
            style: ElevatedButton.styleFrom(
              backgroundColor: background,
              foregroundColor: foreground,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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

  // Each row has the same height.
  Widget buttonRow(List<String> buttons) {
    return SizedBox(
      height: 68,
      child: Row(children: buttons.map(calculatorButton).toList()),
    );
  }

  // Build the calculator's display.
  Widget buildDisplay(ColorScheme colors) {
    String operationText = 'Ready';

    if (pendingOperator != null && accumulator != null) {
      operationText = '${formatNumber(accumulator!)} $pendingOperator';
    } else if (calculationFinished) {
      operationText = 'Result';
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 165),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            operationText,
            style: TextStyle(fontSize: 17, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          // Flexible text scaling prevents wide values overflowing.
          SizedBox(
            width: double.infinity,
            height: 67,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                currentInput,
                style: const TextStyle(
                  fontSize: 55,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // The error text can wrap instead of overflowing vertically.
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              softWrap: true,
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

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

      // LayoutBuilder detects available height.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Scrolling prevents vertical overflow on short windows.
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      buildDisplay(colors),
                      const SizedBox(height: 16),

                      // All keypad buttons stay accessible.
                      buttonRow(['7', '8', '9', '÷']),
                      buttonRow(['4', '5', '6', '×']),
                      buttonRow(['1', '2', '3', '−']),
                      buttonRow(['AC', '0', '±', '+']),
                      buttonRow(['=']),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
