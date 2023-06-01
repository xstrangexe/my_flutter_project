import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static sendEmail({
    required String recepientEmail,
    required lon,
    required lat,
    required distanceFromHome,
  }) async {
    String username = 'okbb0111@gmail.com';
    String password = 'auenniavegzgnubt';

    final smtpServer = gmail(username, password);
    DateTime currentTime = DateTime.now();
    String formattedTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime);

    final message = Message()
      ..from = Address(username, 'MemoryCare')
      ..recipients.add(recepientEmail)
      ..subject =
          '⚠️ Alert: Your Loved One Has Left the Safe Zone $formattedTime'
      ..html = '''
  <p>Dear Guardian,</p>

  <p>This is an automated notification to inform you that <strong>Midou</strong> has left their designated safe zone. Our monitoring system detected that they are now outside the 3km radius set for their safety.</p>

  <h3>Details of the incident:</h3>
  <ul>
    <li><strong>Time of Departure:</strong> $formattedTime</li>
    <li><strong>Current Location:</strong> <a href="https://www.google.com/maps/search/?api=1&query=$lat,$lon" target="_blank">Open in Google Maps</a>
 </li>
    <li><strong>Distance from Safe Location:</strong> ${distanceFromHome}m</li>
  </ul>

  <p>Please take the necessary actions to ensure the well-being and safety of your loved one. We recommend contacting them or visiting their current location to provide assistance and guidance.</p>

  <p>If you have any questions or require further assistance, please do not hesitate to reach out to us.</p>

  <p>Thank you for your attention and cooperation.</p>

  <p>Best regards,<br>
    MemoryCare</p>''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}
