import 'package:pocketbase/pocketbase.dart';

// Для локальной разработки используем адрес по умолчанию.
// При публикации проекта этот адрес заменится на реальный URL сервера.
final pb = PocketBase('http://127.0.0.1:8090');