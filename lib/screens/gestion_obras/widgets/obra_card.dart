import 'package:flutter/material.dart';
import '../../../models/gestion_obras/obra.dart';

class ObraCard extends StatelessWidget {
  final Obra obra;
  final VoidCallback? onEditar;
  final VoidCallback? onFinalizar;
  final VoidCallback? onEliminar;
  final VoidCallback? onTap;

  const ObraCard({
    super.key,
    required this.obra,
    this.onEditar,
    this.onFinalizar,
    this.onEliminar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorEstado = obra.estadoColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF181B35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorEstado),
              const SizedBox(height: 16),
              _buildProgressSection(colorEstado),
              const SizedBox(height: 16),
              _buildInfoGrid(),
              const Divider(height: 32, color: Colors.white10),
              _buildActionButtons(colorEstado),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES DE ESTRUCTURA ---

  // Cabecera con nombre, cliente y badge de estado
  Widget _buildHeader(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                obra.nombre.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (obra.cliente != null)
                Text(
                  obra.cliente!,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        _buildStatusBadge(color),
      ],
    );
  }

  // Sección de progreso visual
  Widget _buildProgressSection(Color color) {
    final double progreso = (obra.porcentajeAvance ?? 0) / 100;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AVANCE TÉCNICO',
                style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
            Text('${(progreso * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progreso.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.1),
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  // Cuadrícula de información secundaria (Dirección, fecha, presupuesto)
  Widget _buildInfoGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        if (obra.direccion?.isNotEmpty ?? false)
          _buildInfoItem(Icons.location_on_rounded, obra.direccion!),
        _buildInfoItem(Icons.calendar_month_rounded, obra.fechaInicioFormatted),
        if (obra.presupuesto != null)
          _buildInfoItem(
            Icons.payments_rounded,
            '\$${obra.presupuesto!.toStringAsFixed(2)}',
            color: Colors.greenAccent,
          ),
      ],
    );
  }

  // Fila de botones de acción táctiles
  Widget _buildActionButtons(Color colorEstado) {
    final bool esFinalizada = obra.estado == 'FINALIZADA';
    return Row(
      children: [
        _buildCircularAction(
          icon: Icons.edit_document,
          color: Colors.blueAccent,
          onPressed: onEditar,
        ),
        const SizedBox(width: 12),
        _buildCircularAction(
          icon: Icons.delete_forever_rounded,
          color: Colors.redAccent,
          onPressed: onEliminar,
        ),
        const Spacer(),
        _buildMainButton(
          label: esFinalizada ? 'COMPLETADA' : 'FINALIZAR',
          icon: esFinalizada ? Icons.verified_rounded : Icons.task_alt_rounded,
          color: esFinalizada ? Colors.green : Colors.cyan,
          onPressed: esFinalizada ? null : onFinalizar,
        ),
      ],
    );
  }

  // --- ELEMENTOS ATÓMICOS (UI) ---
  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        obra.estado.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10,),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {Color color = Colors.white70}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.orange, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildCircularAction({required IconData icon, required Color color, required VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(10),
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildMainButton({required String label, required IconData icon, required Color color, required VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white10,
        disabledForegroundColor: Colors.white24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}