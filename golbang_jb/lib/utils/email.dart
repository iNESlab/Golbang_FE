import 'package:flutter_email_sender/flutter_email_sender.dart';

Future<void> sendEmail({
  required String subject,
  required String body,
  required List<String> recipients,
  required List<String> attachmentPaths,
}) async {
  final email = Email(
    body: body,
    subject: subject,
    recipients: recipients,
    attachmentPaths: attachmentPaths,
    isHTML: false,
  );

  await FlutterEmailSender.send(email);
}
