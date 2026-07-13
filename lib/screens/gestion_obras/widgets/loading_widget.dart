import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({
    super.key,
    this.message = 'Cargando datos...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSpinner(),
          const SizedBox(height: 20),
          _buildMessage(),
        ],
      ),
    );
  }

  // Indicador de carga
  Widget _buildSpinner() {
    return const SizedBox(
      width: 45,
      height: 45,
      child: CircularProgressIndicator(
        color: Colors.orange,
        strokeWidth: 5,
        strokeCap: StrokeCap.round,
      ),
    );
  }

  // Texto de estado
  Widget _buildMessage() {
    return Text(
      message.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.white.withOpacity(0.7),
        letterSpacing: 1.5,
      ),
    );
  }
}