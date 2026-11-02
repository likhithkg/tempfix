import 'package:web/web.dart' as web;

void submitPaymentForm(Map<String, String> params, String actionUrl) {
  final form = web.HTMLFormElement()
    ..method = 'POST'
    ..action = actionUrl;

  params.forEach((key, value) {
    final input = web.HTMLInputElement()
      ..type = 'hidden'
      ..name = key
      ..value = value;
    form.append(input);
  });

  web.document.body!.append(form);
  form.submit();
}
