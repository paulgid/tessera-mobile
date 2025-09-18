import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mosaic/mosaic_viewer.dart';

class IdEntryScreen extends StatefulWidget {
  const IdEntryScreen({super.key});

  @override
  State<IdEntryScreen> createState() => _IdEntryScreenState();
}

class _IdEntryScreenState extends State<IdEntryScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final List<String> _recentIds = ['MOS-234156', 'MOS-891234', 'MOS-456789'];

  bool _isValidating = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _mosaicId {
    return 'MOS-${_controllers.map((c) => c.text).join()}';
  }

  bool get _isComplete {
    return _controllers.every((c) => c.text.isNotEmpty);
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      // Handle backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    // Only allow digits
    if (!RegExp(r'^\d$').hasMatch(value)) {
      _controllers[index].clear();
      return;
    }

    // Move to next field
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // All fields filled, validate
      _validateAndJoin();
    }
  }

  Future<void> _validateAndJoin() async {
    if (!_isComplete) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    // Simulate API validation
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Mock validation - accept IDs ending in even numbers
    final lastDigit = int.parse(_controllers[5].text);
    if (lastDigit % 2 == 0) {
      // Valid ID - navigate to mosaic
      final mosaicId = _mosaicId; // Use the getter to construct the full ID
      // In a real app, we'd pass mosaicId to MosaicViewer
      debugPrint('Navigating to mosaic: $mosaicId');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MosaicViewer()),
      );
    } else {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Mosaic not found. Please check the ID and try again.';
      });
    }
  }

  void _fillId(String id) {
    final digits = id.replaceAll('MOS-', '');
    if (digits.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
      }
      _validateAndJoin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Mosaic ID'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(Icons.info_outline, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Enter Mosaic ID or\nScan QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ID Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MOS-',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                ..._buildDigitFields(),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (_isValidating) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Validating ID...'),
            ],

            const SizedBox(height: 40),

            // Number pad
            _buildNumberPad(),

            const SizedBox(height: 32),

            // OR divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // QR Scanner button
            OutlinedButton.icon(
              onPressed: () {
                // Show QR scanner
                _showQRScanner();
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_recentIds.isNotEmpty) ...[
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),

              // Recent IDs
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recently Used IDs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._recentIds.map((id) {
                final timeAgo = _getTimeAgo(_recentIds.indexOf(id));
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(id),
                  subtitle: Text(timeAgo),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _fillId(id),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDigitFields() {
    return List.generate(6, (index) {
      return Padding(
        padding: EdgeInsets.only(
          right: index == 2 ? 12 : 4,
          left: index == 3 ? 12 : 4,
        ),
        child: SizedBox(
          width: 40,
          height: 56,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: _controllers[index].text.isNotEmpty
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: _errorMessage != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : null,
            ),
            onChanged: (value) => _onDigitChanged(index, value),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNumberPad() {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.backspace, onPressed: _handleBackspace),
              _buildNumberButton('0'),
              _buildActionButton(
                Icons.check,
                onPressed: _isComplete ? _validateAndJoin : null,
                color: _isComplete ? Colors.green : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 80,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _handleNumberInput(number),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(number, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon, {
    VoidCallback? onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 80,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }

  void _handleNumberInput(String number) {
    // Find first empty field
    for (int i = 0; i < 6; i++) {
      if (_controllers[i].text.isEmpty) {
        _controllers[i].text = number;
        if (i < 5) {
          _focusNodes[i + 1].requestFocus();
        } else {
          _validateAndJoin();
        }
        break;
      }
    }
  }

  void _handleBackspace() {
    // Find last filled field
    for (int i = 5; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        _controllers[i].clear();
        _focusNodes[i].requestFocus();
        setState(() {
          _errorMessage = null;
        });
        break;
      }
    }
  }

  void _showQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'QR Scanner',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 100,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Camera permission required\nfor QR scanning',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Point camera at QR code',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Simulate QR scan
                  _fillId('MOS-123456');
                },
                child: const Text('Simulate Scan (Demo)'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(int index) {
    switch (index) {
      case 0:
        return '2 hours ago';
      case 1:
        return 'Yesterday';
      case 2:
        return '3 days ago';
      default:
        return '';
    }
  }
}
