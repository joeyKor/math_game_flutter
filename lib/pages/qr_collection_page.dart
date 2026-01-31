import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

class QRCollectionPage extends StatefulWidget {
  const QRCollectionPage({super.key});

  @override
  State<QRCollectionPage> createState() => _QRCollectionPageState();
}

class _QRCollectionPageState extends State<QRCollectionPage> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add via QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && _isScanning) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() => _isScanning = false);
                  _handleScannedCode(code);
                }
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: accent, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point the camera at a QR code',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedCode(String code) {
    int pointsValue = 0;
    String description = "QR Code Reward";

    try {
      if (code.contains('_')) {
        final parts = code.split('_');
        final prefixAndAmount = parts[0];
        description = parts.sublist(1).join('_');

        if (prefixAndAmount.startsWith('p')) {
          pointsValue = int.tryParse(prefixAndAmount.substring(1)) ?? 0;
        } else if (prefixAndAmount.startsWith('m')) {
          pointsValue = -(int.tryParse(prefixAndAmount.substring(1)) ?? 0);
        } else {
          pointsValue = int.tryParse(prefixAndAmount) ?? 0;
        }
      } else {
        if (code.startsWith("points:")) {
          pointsValue = int.tryParse(code.substring(7)) ?? 0;
        } else if (code.startsWith('p')) {
          pointsValue = int.tryParse(code.substring(1)) ?? 0;
        } else if (code.startsWith('m')) {
          pointsValue = -(int.tryParse(code.substring(1)) ?? 0);
        } else {
          pointsValue = int.tryParse(code) ?? 0;
        }
      }
    } catch (e) {
      pointsValue = 0;
    }

    if (pointsValue != 0) {
      _showApprovalDialog(pointsValue, description);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code format'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isScanning = true);
    }
  }

  void _showApprovalDialog(int pointsValue, String description) {
    final TextEditingController passwordController = TextEditingController();
    final accent = Theme.of(context).colorScheme.secondary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manager Approval Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action: ${pointsValue > 0 ? "Add" : "Deduct"} ${pointsValue.abs()} points',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.titleLarge?.color?.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Content: $description',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter Admin Password',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                ),
                fillColor: Colors.black.withOpacity(0.2),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text == '9891') {
                Navigator.pop(context); // Close approval dialog
                _performScoreUpdate(pointsValue, description);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect Password'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _performScoreUpdate(int pointsValue, String description) {
    Provider.of<UserProvider>(
      context,
      listen: false,
    ).addScore(pointsValue, gameName: description);

    final accent = Theme.of(context).colorScheme.secondary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(pointsValue > 0 ? 'Points Added!' : 'Points Deducted!'),
        content: Text(
          '${pointsValue.abs()} points have been ${pointsValue > 0 ? 'added to' : 'deducted from'} your account.\n\n$description',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context, true); // Go back with success signal
            },
            child: Text('OK', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }
}
