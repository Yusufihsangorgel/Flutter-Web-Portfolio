/// Builds the local email handoff used by the static portfolio contact form.
///
/// The browser only opens the visitor's mail client. No form content is sent
/// to a third party and the UI never claims that delivery has already happened.
Uri buildContactMailtoUri({
  required String recipient,
  required String senderName,
  required String senderEmail,
  required String message,
}) => Uri(
  scheme: 'mailto',
  path: recipient,
  queryParameters: {
    'subject': 'Portfolio message from $senderName',
    'body': 'Name: $senderName\nReply-to: $senderEmail\n\n$message',
  },
);
