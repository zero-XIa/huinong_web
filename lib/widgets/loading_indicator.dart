import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/provider/app_provider.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final elderMode = appProvider.isElderlyMode;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: elderMode ? 48 : 40,
            height: elderMode ? 48 : 40,
            child: CircularProgressIndicator(
              strokeWidth: elderMode ? 4 : 3,
              color: theme.primaryColor,
            ),
          ),
          if (message != null && message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                message!,
                style: TextStyle(
                  fontSize: elderMode ? 18 : 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static void show(BuildContext context, {String message = '加载中...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: LoadingIndicator(message: '识别中...'),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}