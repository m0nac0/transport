import 'package:http/http.dart' as http;

class UserAgentClient extends http.BaseClient {
  final String userAgent;
  final http.Client _inner;
  final String? referer;

  UserAgentClient(this.userAgent, this._inner,
      {this.referer = "https://www.mvg.de/"});

  UserAgentClient.standard({this.referer = "https://www.mvg.de/"})
      : userAgent =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36",
        _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = userAgent;
    request.headers.addAll({
      "accept": "application/json, text/plain, */*",
      "accept-encoding": "gzip, deflate, br, zstd",
      "accept-language": "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7",
      "content-type": "application/json",
      "priority": "u=1, i",
      if (referer != null) "referer": referer!,
      "sec-ch-ua":
          "'Google Chrome';v='129', 'Not=A?Brand';v='8', 'Chromium';v='129'",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "'Windows'",
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
    });
    return _inner.send(request);
  }
}

