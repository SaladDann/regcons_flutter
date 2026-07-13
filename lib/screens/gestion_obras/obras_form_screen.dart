import 'package:flutter/material.dart';
import '../../models/gestion_obras/obra.dart';
import '../../services/gestion_obras/obra_service.dart';

class ObraFormScreen extends StatefulWidget {
  final Obra? obra;
  // 1. Agregamos el ID del usuario al constructor
  final int idUsuarioActual;

  const ObraFormScreen({
    super.key,
    this.obra,
    required this.idUsuarioActual
  });

  @override
  State<ObraFormScreen> createState() => _ObraFormScreenState();
}

class _ObraFormScreenState extends State<ObraFormScreen> {
  // --- ESTADO Y CONTROLADORES ---
  final _formKey = GlobalKey<FormState>();
  final _obraService = ObraService();

  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController clienteCtrl;
  late TextEditingController direccionCtrl;
  late TextEditingController presupuestoCtrl;

  DateTime? fechaInicio;
  DateTime? fechaFin;
  String estado = 'PLANIFICADA';
  bool _guardando = false;

  bool get esEdicion => widget.obra != null;

  @override
  void initState() {
    super.initState();
    final o = widget.obra;
    nombreCtrl = TextEditingController(text: o?.nombre ?? '');
    descripcionCtrl = TextEditingController(text: o?.descripcion ?? '');
    clienteCtrl = TextEditingController(text: o?.cliente ?? '');
    direccionCtrl = TextEditingController(text: o?.direccion ?? '');
    presupuestoCtrl = TextEditingController(text: o?.presupuesto?.toString() ?? '');
    fechaInicio = o?.fechaInicio;
    fechaFin = o?.fechaFin;
    estado = o?.estado ?? 'PLANIFICADA';
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    clienteCtrl.dispose();
    direccionCtrl.dispose();
    presupuestoCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (fechaInicio != null && fechaFin != null && fechaFin!.isBefore(fechaInicio!)) {
      _notificar('La fecha fin no puede ser anterior al inicio', error: true);
      return;
    }

    setState(() => _guardando = true);

    final obra = Obra(
      idObra: widget.obra?.idObra,
      nombre: nombreCtrl.text.trim(),
      descripcion: descripcionCtrl.text.trim(),
      cliente: clienteCtrl.text.trim(),
      direccion: direccionCtrl.text.trim(),
      presupuesto: double.tryParse(presupuestoCtrl.text),
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: estado,
      porcentajeAvance: widget.obra?.porcentajeAvance ?? 0,
    );

    try {
      if (esEdicion) {
        await _obraService.actualizarObra(obra);
      } else {
        // 2. Usamos directamente widget.idUsuarioActual
        // Ya no necesitamos SharedPreferences aquí
        await _obraService.crearObra(obra, widget.idUsuarioActual);
      }

      if (mounted) {
        _notificar(esEdicion ? 'Obra actualizada' : 'Obra registrada');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _notificar('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // Comprueba si existen cambios pendientes de guardar
  bool _hayCambios() {
    final o = widget.obra;
    if (nombreCtrl.text != (o?.nombre ?? '')) return true;
    if (descripcionCtrl.text != (o?.descripcion ?? '')) return true;
    if (estado != (o?.estado ?? 'PLANIFICADA')) return true;
    return false;
  }

  // --- INTERFAZ DE USUARIO (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _seccionTitulo('Información General'),
                  _buildTextField(nombreCtrl, 'Nombre de la Obra', Icons.business, requerido: true),
                  _buildTextField(descripcionCtrl, 'Descripción', Icons.notes, multilinea: true),

                  _seccionTitulo('Detalles de Contacto'),
                  _buildTextField(clienteCtrl, 'Cliente / Entidad', Icons.person_outline),
                  _buildTextField(direccionCtrl, 'Ubicación / Dirección', Icons.location_on_outlined),

                  _seccionTitulo('Presupuesto y Tiempos'),
                  _buildTextField(presupuestoCtrl, 'Presupuesto total', Icons.monetization_on_outlined, numero: true),

                  Row(
                    children: [
                      _fechaBtn('Inicio', fechaInicio, () => _pickFecha(true), Icons.calendar_today),
                      const SizedBox(width: 12),
                      _fechaBtn('Fin', fechaFin, () => _pickFecha(false), Icons.event_available),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildEstadoDropdown(),

                  const SizedBox(height: 40),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF181B35).withOpacity(0.95),
      elevation: 0,
      centerTitle: true,
      title: Text(esEdicion ? 'EDITAR OBRA' : 'NUEVA OBRA',
          style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1)),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.orange),
        onPressed: _confirmarCancelar,
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
        child: Image.asset('assets/images/login_bg.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.15))
    );
  }

  Widget _buildTextField(TextEditingController c, String label, IconData icon,
      {bool requerido = false, bool multilinea = false, bool numero = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        maxLines: multilinea ? 3 : 1,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        validator: requerido ? (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null : null,
        decoration: _inputDecor(label, icon),
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    return DropdownButtonFormField<String>(
      value: estado,
      dropdownColor: const Color(0xFF1E2130),
      style: const TextStyle(color: Colors.white),
      onChanged: (v) => setState(() => estado = v!),
      decoration: _inputDecor('Estado de la Obra', Icons.info_outline),
      items: ['PLANIFICADA', 'ACTIVA', 'SUSPENDIDA', 'FINALIZADA']
          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _guardando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : Text(esEdicion ? 'GUARDAR CAMBIOS' : 'REGISTRAR PROYECTO',
                style: const TextStyle(letterSpacing: 1.2)),
          ),
        ),
        TextButton(
          onPressed: _confirmarCancelar,
          child: const Text('CANCELAR Y SALIR', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) => InputDecoration(
    labelText: label.toUpperCase(),
    prefixIcon: Icon(icon, color: Colors.orange, size: 22),
    labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
    filled: true,
    fillColor: const Color(0xFF181B35),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
  );

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 12, left: 4),
      child: Text(titulo.toUpperCase(),
          style: const TextStyle(color: Colors.orange, fontSize: 11, letterSpacing: 1.5)),
    );
  }

  Widget _fechaBtn(String label, DateTime? fecha, VoidCallback onTap, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF181B35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fecha == null ? label : "${fecha.day}/${fecha.month}/${fecha.year}",
                  style: TextStyle(color: fecha == null ? Colors.white38 : Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _notificar(String msj, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msj),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmarCancelar() {
    if (!_hayCambios()) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        title: const Text('¿DESCARTAR CAMBIOS?', style: TextStyle(color: Colors.white)),
        content: const Text('Se perderá la información ingresada.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('VOLVER')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('DESCARTAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFecha(bool inicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (inicio ? fechaInicio : fechaFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.orange, surface: Color(0xFF181B35)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => inicio ? fechaInicio = picked : fechaFin = picked);
  }
}