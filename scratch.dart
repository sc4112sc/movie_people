import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  final url = 'http://app2.atmovies.com.tw/movie/fden33612209/';
  final response = await http.get(Uri.parse(url));
  print(response.statusCode);
  final doc = html_parser.parse(response.body);
  print(doc.querySelector('meta[property="og:description"]')?.attributes['content']);
}
