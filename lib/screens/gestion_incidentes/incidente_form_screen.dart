import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/gestion_incidentes/incidente.dart';
import '../../models/gestion_obras/obra.dart';
import '../../services/gestion_incidentes/incidente_service.dart';

class IncidenteFormScreen extends StatefulWidget {
  final Obra obra;
  final Incidente? incidente;

  const IncidenteFormScreen({super.key, required this.obra, this.incidente});

  @override
  State<IncidenteFormScreen> createState() => _IncidenteFormScreenState();
}

class _IncidenteFormScreenState extends State<IncidenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final IncidenteService _service = IncidenteService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descripcionCtrl = TextEditingController();

  late String _tipo;
  late String _severidad;
  List<String> _evidencias = [];
  int _idUsuarioActual = 0; // Variable para almacenar el ID real

  final Map<String, dynamic> _configTipos = {
    'ACCIDENTE': {'icon': Icons.emergency, 'color': Colors.redAccent},
    'INCIDENTE': {'icon': Icons.warning_rounded, 'color': Colors.orange},
    'CONDICION_INSEGURA': {'icon': Icons.construction, 'color': Colors.amber},
    'ACTO_INSEGURO': {'icon': Icons.person_off, 'color': Colors.yellow},
    'FALLA_EQUIPO': {'icon': Icons.settings_suggest, 'color': Colors.blueAccent},
    'DERRAME_MATERIAL': {'icon': Icons.opacity, 'color': Colors.cyan},
    'OTRO': {'icon': Icons.more_horiz, 'color': Colors.grey},
  };

  @override
  void initState() {
    super.initState();
    _initFields();
    _cargarUsuario(); // Cargamos el ID al iniciar
  }

  void _initFields() {
    final incidente = widget.incidente;
    _tipo = incidente?.tipo ?? 'INCIDENTE';
    _severidad = incidente?.severidad ?? 'BAJA';
    _descripcionCtrl.text = incidente?.descripcion ?? '';
    _evidencias = List.from(incidente?.evidenciasFoto ?? []);
  }

  // Recupera el ID del usuario logueado
  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _idUsuarioActual = prefs.getInt('id_usuario') ?? 0;
      });
    }
  }

  /// Captura de evidencia fotográfica
  Future<void> _agregarEvidencia() async {
    final ImageSource? fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1D2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _buildSourcePicker(),
    );

    if (fuente != null) {
      final XFile? photo = await _picker.pickImage(source: fuente, imageQuality: 70);
      if (photo != null) {
        setState(() => _evidencias.insert(0, photo.path));
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación de seguridad
    if (_idUsuarioActual == 0 && widget.incidente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Sesión de usuario no válida.')),
      );
      return;
    }

    final reporte = Incidente(
      idReporte: widget.incidente?.idReporte,
      idObra: widget.obra.idObra!,
      // Priorizamos el ID del incidente existente si es edición, sino el ID logueado
      idUsuario: widget.incidente?.idUsuario ?? _idUsuarioActual,
      tipo: _tipo,
      severidad: _severidad,
      descripcion: _descripcionCtrl.text.trim(),
      fechaEvento: widget.incidente?.fechaEvento ?? DateTime.now(),
      estado: widget.incidente?.estado ?? 'REPORTADO',
      evidenciasFoto: _evidencias,
    );

    try {
      await _service.guardarIncidente(obra: widget.obra, incidente: reporte);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderObra(),
              const SizedBox(height: 25),
              _buildSectionHeader('CATEGORÍA DEL INCIDENTE'),
              _buildTipoDropdown(),
              const SizedBox(height: 25),
              _buildSectionHeader('NIVEL DE SEVERIDAD'),
              _buildSeveridadSelector(),
              const SizedBox(height: 25),
              _buildSectionHeader('DESCRIPCIÓN DE LOS HECHOS'),
              _buildDescriptionField(),
              const SizedBox(height: 25),
              _buildSectionHeader('EVIDENCIAS FOTOGRÁFICAS'),
              _buildEvidenciasRow(),
              const SizedBox(height: 35),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES UI ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A1D2E),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.incidente != null ? 'EDITAR REPORTE' : 'NUEVO REPORTE',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildSectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(text, style: const TextStyle(color: Colors.orange, fontSize: 11, letterSpacing: 1.1)),
  );

  Widget _buildHeaderObra() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10)
    ),
    child: Row(
      children: [
        const Icon(Icons.location_city, color: Colors.orange, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.obra.nombre, style: const TextStyle(color: Colors.white, fontSize: 14))),
      ],
    ),
  );

  Widget _buildTipoDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: _tipo,
        dropdownColor: const Color(0xFF1A1D2E),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(border: InputBorder.none),
        items: _configTipos.entries.map((e) => DropdownMenuItem(
          value: e.key,
          child: Row(children: [Icon(e.value['icon'], color: e.value['color'], size: 18), const SizedBox(width: 10), Text(e.key)]),
        )).toList(),
        onChanged: (v) => setState(() => _tipo = v!),
      ),
    ),
  );

  Widget _buildSeveridadSelector() {
    final sevColors = {'BAJA': Colors.green, 'MEDIA': Colors.yellow, 'ALTA': Colors.orange, 'CRITICA': Colors.red};
    return Row(
      children: sevColors.entries.map((entry) {
        bool isSelected = _severidad == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _severidad = entry.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 45,
              decoration: BoxDecoration(
                color: isSelected ? entry.value : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? entry.value : Colors.white24),
              ),
              child: Center(
                child: Text(entry.key, style: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontSize: 10)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionField() => TextFormField(
    controller: _descripcionCtrl,
    maxLines: 4,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1A1D2E),
      hintText: "Detalle lo sucedido...",
      hintStyle: const TextStyle(color: Colors.white24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
    ),
    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
  );

  Widget _buildEvidenciasRow() {
    return Row(
      children: [
        _buildAddPhotoButton(),
        Expanded(
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _evidencias.length,
              itemBuilder: (context, index) => _buildPhotoPreview(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() => GestureDetector(
    onTap: _agregarEvidencia,
    child: Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, color: Colors.orange, size: 28),
          const SizedBox(height: 6),
          Text('AÑADIR', style: TextStyle(color: Colors.orange, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    ),
  );

  Widget _buildPhotoPreview(int index) => Container(
    width: 100,
    margin: const EdgeInsets.only(right: 8),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _evidencias[index].startsWith('http')
              ? Image.network(_evidencias[index], fit: BoxFit.cover)
              : Image.file(File(_evidencias[index]), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _evidencias.removeAt(index)),
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSourcePicker() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("CAPTURA DE EVIDENCIA", style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceOption(Icons.camera_alt, "CÁMARA", ImageSource.camera, Colors.orange),
              _buildSourceOption(Icons.photo_library, "GALERÍA", ImageSource.gallery, Colors.blueAccent),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildSourceOption(IconData icon, String label, ImageSource source, Color color) => GestureDetector(
    onTap: () => Navigator.pop(context, source),
    child: Column(
      children: [
        CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: _guardar,
      child: Text(
          widget.incidente != null ? 'ACTUALIZAR REPORTE' : 'GUARDAR REPORTE',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
      ),
    ),
  );

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }
}