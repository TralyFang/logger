import 'dart:convert';

import 'package:logger/src/logger.dart';
import 'package:logger/src/log_printer.dart';

/// 输出一行日志的打印器
/// 格式：日期 类名和方法名 级别 内容
/// 例如：
/// 2021-06-14 16:58:28.883515 _MyHomePageState.demo I Info message
class OneLinePrinter extends LogPrinter {
  static final levelName = {
    Level.verbose: '|V|',
    Level.debug: '|D|',
    Level.info: '|I|',
    Level.warning: '|W|',
    Level.error: '|E|',
    Level.wtf: '|F|',
  };

  /// Matches a stacktrace line as generated on Android/iOS devices.
  /// For example:
  /// #1      Logger.log (package:logger/src/logger.dart:115:29)
  static final _deviceStackTraceRegex = RegExp(r'#[0-9]+[\s]+(.+) \(([^\s]+)\)');

  @override
  List<String> log(LogEvent event) {
    var messageStr = stringifyMessage(event.message);
    var lineInfo = _classAndMethod(StackTrace.current);

    return _formatAndPrint(
      event.level,
      messageStr,
      lineInfo,
    );
  }

  /// 从调用堆栈中找类名和方法名
  String _classAndMethod(StackTrace? stackTrace) {
    var lines = stackTrace.toString().split('\n');
    var info = '';
    var count = 0;

    for (var line in lines) {
      if (_discardDeviceStacktraceLine(line) || line.isEmpty) {
        continue;
      }

      var match = _deviceStackTraceRegex.matchAsPrefix(line);
      if (match != null) {
        // 匹配到的第一组为类名和方法名
        info = '${match.group(1)}';
      }

      // 取到方法名后退出循环
      if (++count == 1) {
        break;
      }
    }

    return info;
  }

  /// 忽略日志类的堆栈信息
  bool _discardDeviceStacktraceLine(String line) {
    var match = _deviceStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }

    var group = match.group(2)!;
    return group.contains('log_util.dart') || group.startsWith('package:logger');
  }

  // Handles any object that is causing JsonEncoder() problems
  Object toEncodableFallback(dynamic object) {
    return object.toString();
  }

  String stringifyMessage(dynamic message) {
    if (message is Map || message is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
      return encoder.convert(message);
    } else {
      return message.toString();
    }
  }

  /// [level] 日志等级
  /// [message] 日志内容
  /// [lineInfo] 类名和方法名
  List<String> _formatAndPrint(
    Level level,
    String message,
    String? lineInfo,
  ) {
    // This code is non trivial and a type annotation here helps understanding.
    // ignore: omit_local_variable_types
    List<String> buffer = [];
    buffer.add('${DateTime.now()} $lineInfo ${levelName[level]} ${message.replaceAll('\n', ' ')}\n');
    return buffer;
  }
}
