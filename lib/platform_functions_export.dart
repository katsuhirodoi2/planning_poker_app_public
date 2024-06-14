export 'functions/platform_none_functions.dart' // Stub implementation
    if (dart.library.io) 'functions/platform_mobile_functions.dart'
    if (dart.library.html) 'functions/platform_web_functions.dart';
