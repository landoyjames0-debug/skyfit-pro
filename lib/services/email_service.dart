import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_9fusbdp';
  static const String _templateId = 'template_l0nipho';
  static const String _publicKey = '3yVg5d5m0pdHlTxCe';

  /// Generates a 6-digit OTP
  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Sends OTP email via EmailJS
  static Future<bool> sendOTP({
    required String toName,
    required String toEmail,
    required String otpCode,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_name': toName,
            'email': toEmail,
            'otp_code': otpCode,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
