import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Gmail2FAService {
  // Gmail SMTP Configuration
  // Replace these with your Gmail credentials
  static const String _gmailUsername = 'pawtechsender@gmail.com'; 
  static const String _gmailAppPassword = 'fhxx wjje ragh myti'; // Replace with actual app password 
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a 6-digit verification code
  static String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Sends verification code via Gmail SMTP
  static Future<bool> sendVerificationCode(String email, String userName) async {
    try {
      final code = _generateCode();
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      // Store code in Firestore with expiry
      await _firestore.collection('verification_codes').doc(email).set({
        'code': code,
        'expiryTime': Timestamp.fromDate(expiryTime),
        'attempts': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('📧 Sending Gmail 2FA code to: $email');
      print('📧 Generated code: $code');

      // Configure Gmail SMTP
      final smtpServer = gmail(_gmailUsername, _gmailAppPassword);

      // Create the email message
      final message = Message()
        ..from = Address(_gmailUsername, 'PawTech Security')
        ..recipients.add(email)
        ..subject = 'Your PawTech Verification Code'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #1E3A8A; margin: 0;">🐾 PawTech</h1>
              <p style="color: #64748B; margin: 5px 0;">Secure Access Verification</p>
            </div>
            
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 15px; padding: 30px; text-align: center; color: white;">
              <h2 style="color: white; margin-bottom: 15px;">Hello $userName! 👋</h2>
              <p style="color: #E2E8F0; margin-bottom: 25px;">
                Enter this verification code in the PawTech app to complete your secure login:
              </p>
              
              <div style="background: white; border-radius: 10px; padding: 25px; margin: 25px 0; box-shadow: 0 4px 15px rgba(0,0,0,0.1);">
                <span style="font-size: 36px; font-weight: bold; letter-spacing: 10px; color: #1E3A8A;">
                  $code
                </span>
              </div>
              
              <p style="color: #E2E8F0; font-size: 14px; margin-top: 20px;">
                ⏰ This code will expire in 10 minutes
              </p>
            </div>
            
            <div style="margin-top: 30px; padding: 20px; background: #F8FAFC; border-radius: 10px; border-left: 4px solid #10B981;">
              <h3 style="color: #065F46; margin: 0 0 10px 0;">🔒 Security Tips:</h3>
              <ul style="color: #064E3B; margin: 0; padding-left: 20px;">
                <li>Never share this code with anyone</li>
                <li>PawTech will never ask for this code via phone or email</li>
                <li>If you didn't request this code, please ignore this email</li>
              </ul>
            </div>
            
            <div style="margin-top: 30px; text-align: center;">
              <p style="color: #64748B; font-size: 12px;">
                This email was sent from PawTech Security System<br>
                © 2024 PawTech. All rights reserved.
              </p>
            </div>
          </div>
        ''';

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('📧 Gmail send report: ${sendReport.toString()}');
      
      return true;
    } catch (e) {
      print('❌ Error sending Gmail verification code: $e');
      
      // Provide specific help for common authentication errors
      if (e.toString().contains('535') && e.toString().contains('Username and Password not accepted')) {
        print('🔑 AUTHENTICATION ERROR: Gmail login failed');
        print('💡 Common fixes:');
        print('   1. Make sure 2-Step Verification is enabled on pawtechsender@gmail.com');
        print('   2. Generate an App Password (not regular password)');
        print('   3. Use the 16-character app password in the service');
        print('   4. Visit: https://support.google.com/accounts/answer/185833');
      } else if (e.toString().contains('534') && e.toString().contains('Application-specific password required')) {
        print('🔐 App Password Required: You need to create an app password');
        print('💡 Visit: https://myaccount.google.com/apppasswords');
      }
      
      return false;
    }
  }

  /// Verifies the entered code
  static Future<bool> verifyCode(String email, String enteredCode) async {
    try {
      final doc = await _firestore.collection('verification_codes').doc(email).get();
      
      if (!doc.exists) {
        print('🔍 No verification code found for: $email');
        return false;
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiryTime = (data['expiryTime'] as Timestamp).toDate();
      final attempts = data['attempts'] as int;

      print('🔍 Verifying code for: $email');
      print('🔍 Stored code: $storedCode, Entered: $enteredCode');
      print('🔍 Expiry: $expiryTime, Now: ${DateTime.now()}');
      print('🔍 Attempts: $attempts');

      // Check expiry
      if (DateTime.now().isAfter(expiryTime)) {
        print('⏰ Code expired, deleting...');
        await doc.reference.delete();
        return false;
      }

      // Check attempts limit
      if (attempts >= 3) {
        print('🚫 Too many attempts, deleting code...');
        await doc.reference.delete();
        return false;
      }

      // Verify code
      if (enteredCode == storedCode) {
        print('✅ Code verified successfully!');
        await doc.reference.delete();
        return true;
      } else {
        print('❌ Code mismatch, incrementing attempts...');
        await doc.reference.update({'attempts': attempts + 1});
        return false;
      }
    } catch (e) {
      print('❌ Error verifying code: $e');
      return false;
    }
  }

  /// Test function to verify Gmail SMTP setup
  static Future<bool> testEmailSetup(String testEmail) async {
    try {
      print('🧪 Testing Gmail SMTP configuration...');
      
      // Configure Gmail SMTP
      final smtpServer = gmail(_gmailUsername, _gmailAppPassword);

      // Create test message
      final message = Message()
        ..from = Address(_gmailUsername, 'PawTech Test')
        ..recipients.add(testEmail)
        ..subject = '🧪 Gmail SMTP Test - PawTech 2FA'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #10B981;">✅ Gmail SMTP Test Successful!</h1>
            <p>If you received this email, your Gmail 2FA configuration is working correctly!</p>
            <div style="background: #F3F4F6; padding: 15px; border-radius: 8px; margin: 20px 0;">
              <h3>Test Details:</h3>
              <p><strong>From:</strong> $_gmailUsername</p>
              <p><strong>To:</strong> $testEmail</p>
              <p><strong>Time:</strong> ${DateTime.now()}</p>
              <p><strong>Test Code:</strong> <span style="background: #E5E7EB; padding: 5px; border-radius: 4px;">123456</span></p>
            </div>
            <p style="color: #6B7280; font-size: 14px;">
              You can now use this Gmail configuration for 2FA in your PawTech app!
            </p>
          </div>
        ''';

      // Send test email
      final sendReport = await send(message, smtpServer);
      print('✅ Gmail test email sent successfully: ${sendReport.toString()}');
      
      return true;
    } catch (e) {
      print('❌ Gmail SMTP test failed: $e');
      
      // Provide helpful error messages
      if (e.toString().contains('535-5.7.8 Username and Password not accepted')) {
        print('🔑 Gmail Login Error: Please check your email and app password');
        print('💡 Make sure you\'re using an App Password, not your regular Gmail password');
        print('💡 Go to Google Account > Security > 2-Step Verification > App passwords');
      } else if (e.toString().contains('534-5.7.9 Application-specific password required')) {
        print('🔐 App Password Required: You need to enable 2FA and create an app password');
        print('💡 Visit: https://myaccount.google.com/apppasswords');
      }
      
      return false;
    }
  }

  /// Get configuration status
  static bool isConfigured() {
    return _gmailUsername != 'your.email@gmail.com' && 
           _gmailAppPassword != 'your-app-password' &&
           _gmailUsername.isNotEmpty && 
           _gmailAppPassword.isNotEmpty;
  }

  /// Get configuration instructions
  static String getSetupInstructions() {
    return '''
To configure Gmail 2FA:

1. Go to your Google Account settings
2. Security → 2-Step Verification (enable if not already)
3. App passwords → Generate new app password
4. Choose "Mail" and your device
5. Copy the 16-character password
6. Update gmail_2fa_service.dart with your credentials

Replace:
- _gmailUsername: 'your.email@gmail.com'
- _gmailAppPassword: 'your-app-password'

With your actual Gmail and app password.
    ''';
  }
}
