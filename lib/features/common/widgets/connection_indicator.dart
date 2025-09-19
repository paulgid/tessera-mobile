import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/websocket_provider.dart';
import '../../../core/services/websocket_service.dart' as ws;

/// Widget to display WebSocket connection status
class ConnectionIndicator extends ConsumerWidget {
  final bool showText;

  const ConnectionIndicator({super.key, this.showText = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(webSocketConnectionProvider);

    return connectionState.when(
      data: (state) => _buildIndicator(context, state),
      error: (error, _) =>
          _buildIndicator(context, ws.ConnectionState.disconnected),
      loading: () => _buildIndicator(context, ws.ConnectionState.connecting),
    );
  }

  Widget _buildIndicator(BuildContext context, ws.ConnectionState state) {
    final Color color;
    final IconData icon;
    final String text;

    switch (state) {
      case ws.ConnectionState.connected:
        color = Colors.green;
        icon = Icons.wifi;
        text = 'Connected';
        break;
      case ws.ConnectionState.connecting:
        color = Colors.orange;
        icon = Icons.wifi_protected_setup;
        text = 'Connecting...';
        break;
      case ws.ConnectionState.disconnected:
        color = Colors.red;
        icon = Icons.wifi_off;
        text = 'Disconnected';
        break;
    }

    Widget iconWidget = Icon(icon, color: color, size: 20);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          if (showText) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simplified connection dot indicator
class ConnectionDot extends ConsumerWidget {
  final double size;

  const ConnectionDot({super.key, this.size = 8});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(webSocketConnectionProvider);

    return connectionState.when(
      data: (state) => _buildDot(state),
      error: (_, __) => _buildDot(ws.ConnectionState.disconnected),
      loading: () => _buildDot(ws.ConnectionState.connecting),
    );
  }

  Widget _buildDot(ws.ConnectionState state) {
    final Color color;
    switch (state) {
      case ws.ConnectionState.connected:
        color = Colors.green;
        break;
      case ws.ConnectionState.connecting:
        color = Colors.orange;
        break;
      case ws.ConnectionState.disconnected:
        color = Colors.red;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: size / 2,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}
