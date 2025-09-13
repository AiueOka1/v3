import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/providers/auth_provider.dart';
import 'package:pawtech/services/gmail_2fa_service.dart';
import 'package:pawtech/widgets/custom_button.dart';
import 'package:pawtech/screens/home/home_screen.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const TwoFactorVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<TwoFactorVerificationScreen> createState() => _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState extends State<TwoFactorVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _sendInitialCode();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _sendInitialCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    print('🔐 Attempting to send verification code to: ${widget.email}');
    
    final success = await Gmail2FAService.sendVerificationCode(
      widget.email, 
      'User', // You can get the actual name from auth provider if needed
    );
    
    print('🔐 Send verification code result: $success');
    
    setState(() {
      _isLoading = false;
      if (!success) {
        _error = 'Failed to send verification code. Please check your email and spam folder.';
      } else {
        _startResendCountdown();
      }
    });
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 1 minute cooldown
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _error = null;
    });

    final success = await Gmail2FAService.sendVerificationCode(widget.email, 'User');
    
    setState(() {
      _isResending = false;
      if (success) {
        _startResendCountdown();
        // Clear the input fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        _error = 'Failed to resend verification code. Please try again.';
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      setState(() {
        _error = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final isValidCode = await Gmail2FAService.verifyCode(widget.email, code);
    
    if (isValidCode) {
      // Code is valid, proceed with login
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final loginSuccess = await authProvider.completeLogin(widget.email, widget.password);
      
      if (loginSuccess && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false, // Remove all previous routes
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Login failed. Please try again.';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Invalid or expired code. Please try again.';
        // Clear the input fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (index == 5 && value.isNotEmpty) {
      final code = _controllers.map((c) => c.text).join();
      if (code.length == 6) {
        _verifyCode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Icon(
                Icons.security,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'We sent a 6-digit code to your email',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                widget.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Code Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildCodeInput(index)),
              ),
              const SizedBox(height: 24),
              
              // Error Message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Verify Code',
                  onPressed: _isLoading ? () {} : _verifyCode,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 24),
              
              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _isResending ? null : _resendCode,
                      child: Text(
                        _isResending ? 'Sending...' : 'Resend Code',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput(int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? colorScheme.primary
              : theme.textTheme.bodySmall?.color?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) => _onCodeChanged(index, value),
      ),
    );
  }
}
