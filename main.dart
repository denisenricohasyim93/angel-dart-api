import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:logging/logging.dart';
import 'package:pretty_logging/pretty_logging.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:convert';

main() async {
  // Open a connection (testdb should already exist)
  final connection = await MySqlConnection.connect(new ConnectionSettings(
      host: '172.17.0.3',
      port: 3306,
      user: 'root',
      password: 'supersecret',
      db: 'mysql',
  ));

  // Logging set up/boilerplate
  Logger.root.onRecord.listen(prettyLog);

  // Create our server.
  var app = Angel(
    logger: Logger('angel'),
    reflector: MirrorsReflector(),
  );

  // Index route. Returns JSON.
  app.get('/', (req, res) => 'Welcome to Angel!');

  // Accepts a URL like /greet/foo or /greet/bob.
  app.get(
    '/user',
    (req, res) async {
      
      var results = await connection.query('select User, Host from user');
      
      for (var row in results) {
        print('${row[0]}');
      }

      // Finally, close the connection
      await connection.close();
      // print(results['Fields']);
      res
        ..write(jsonEncode(results.toList()))
        ..close();
    },
  );

  // Handle any other query value of `name`.
  app.get(
    '/greet',
    ioc((@Query('name') String name) => 'Hello, $name!'),
  );

  // Simple fallback to throw a 404 on unknown paths.
  app.fallback((req, res) {
    throw AngelHttpException.notFound(
      message: 'Unknown path: "${req.uri.path}"',
    );
  });

  var http = AngelHttp(app);
  var server = await http.startServer('172.17.0.2', 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening at $url');
  print('Visit these pages to see Angel in action:');
}
