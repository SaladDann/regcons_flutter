import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../db/app_db.dart';
import '../../db/daos/gestion_obras/avance_dao.dart';
import '../../models/gestion_obras/avance.dart';

class AvancesActividadScreen extends StatefulWidget {
  final int idActividad;
  final int idObra;
  final String nombreActividad;

  const AvancesActividadScreen({
    super.key,
    required this.idActividad,
    required this.idObra,
    required this.nombreActividad,
  });

  @override
  State<AvancesActividadScreen> createState() => _AvancesActividadScreenState();
}

class _AvancesActividadScreenState extends State<AvancesActividadScreen> {
  final _picker = ImagePicker();
  late AvanceDao _avanceDao;

  List<Avance> _todosLosAvances = [];
  List<Avance> _avancesFiltrados = [];

  bool _cargando = true;
  bool _estaBuscando = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDao();
  }

  Future<void> _initDao() async {
    final db = await AppDatabase().database;
    _avanceDao = AvanceDao(db);
    await _cargarAvances();
  }

  Future<void> _cargarAvances() async {
    setState(() => _cargando = true);
    final avances = await _avanceDao.getByActividad(widget.idActividad);
    avances.sort((a, b) => b.fecha.compareTo(a.fecha));
    setState(() {
      _todosLosAvances = avances;
      _avancesFiltrados = avances;
      _cargando = false;
    });
  }

  void _filtrarPorDia(String query) {
    setState(() {
      _avancesFiltrados = _todosLosAvances.where((av) {
        final fechaStr = "${av.fecha.day}/${av.fecha.month}/${av.fecha.year}";
        return fechaStr.contains(query);
      }).toList();
    });
  }

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: esError ? Colors.redAccent : Colors.green,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  esError ? Icons.warning_amber : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => overlayEntry.remove(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  void _mostrarFormularioAvance({Avance? avanceExistente}) {
    final descripcionCtrl = TextEditingController(text: avanceExistente?.descripcion);
    final horasCtrl = TextEditingController(text: avanceExistente?.horasTrabajadas != null ? avanceExistente!.horasTrabajadas.toString() : "");
    List<String> evidenciasTemporales = [];
    if (avanceExistente?.evidenciaFoto != null) {
      evidenciasTemporales.add(avanceExistente!.evidenciaFoto!);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181B35),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text(
                  avanceExistente == null ? 'Nuevo Registro de Avance' : 'Editar Registro de Avance',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descripcionCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecor('¿Qué se hizo hoy?', Icons.description),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: horasCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecor('Horas dedicadas', Icons.timer_outlined),
                ),
                const SizedBox(height: 20),
                const Text('EVIDENCIAS FOTOGRÁFICAS', style: TextStyle(color: Colors.orange, fontSize: 11, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAddBtn(() async {
                      String? path = await _gestionarCaptura();
                      if (path != null) setModalState(() => evidenciasTemporales.insert(0, path));
                    }),
                    Expanded(
                      child: SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: evidenciasTemporales.length,
                          itemBuilder: (context, index) => _buildPhotoPreview(
                            evidenciasTemporales[index],
                                () => setModalState(() => evidenciasTemporales.removeAt(index)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          if (descripcionCtrl.text.trim().isEmpty || evidenciasTemporales.isEmpty) {
                            _mensaje('Descripción y al menos una foto son obligatorias', esError: true);
                            return;
                          }

                          final nuevoAvance = Avance(
                            idAvance: avanceExistente?.idAvance,
                            idActividad: widget.idActividad,
                            idObra: widget.idObra,
                            fecha: avanceExistente?.fecha ?? DateTime.now(),
                            horasTrabajadas: double.tryParse(horasCtrl.text) ?? 0,
                            descripcion: descripcionCtrl.text.trim(),
                            evidenciaFoto: evidenciasTemporales.first,
                            estado: avanceExistente?.estado ?? 'REGISTRADO',
                            sincronizado: 0,
                          );

                          if (avanceExistente == null) {
                            await _avanceDao.insert(nuevoAvance);
                            _mensaje('Avance registrado correctamente');
                          } else {
                            await _avanceDao.update(nuevoAvance);
                            _mensaje('Avance actualizado correctamente');
                          }

                          Navigator.pop(context);
                          _cargarAvances();
                        },
                        child: Text(
                          avanceExistente == null ? 'GUARDAR' : 'ACTUALIZAR',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _gestionarCaptura() async {
    final ImageSource? fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1D2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("EVIDENCIA FOTOGRÁFICA", style: TextStyle(color: Colors.white, letterSpacing: 1.2)),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceBtn(Icons.camera_alt_rounded, "CÁMARA", ImageSource.camera, Colors.orange),
                  _buildSourceBtn(Icons.photo_library_rounded, "GALERÍA", ImageSource.gallery, Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (fuente != null) {
      try {
        final XFile? photo = await _picker.pickImage(source: fuente, imageQuality: 70);
        return photo?.path;
      } catch (_) {
        _mensaje('Error al capturar la foto', esError: true);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B35),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: _estaBuscando
            ? TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Buscar día (ej: 08/2)...',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
          onChanged: _filtrarPorDia,
        )
            : Column(
          children: [
            const Text('AVANCES DE ACTIVIDAD', style: TextStyle(fontSize: 10, color: Colors.orange)),
            Text(widget.nombreActividad, style: const TextStyle(fontSize: 16, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_estaBuscando ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _estaBuscando = !_estaBuscando;
                if (!_estaBuscando) {
                  _searchCtrl.clear();
                  _avancesFiltrados = _todosLosAvances;
                }
              });
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioAvance(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('NUEVO AVANCE', style: TextStyle(color: Colors.white)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _avancesFiltrados.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _avancesFiltrados.length,
        itemBuilder: (context, index) => _itemAvance(_avancesFiltrados[index]),
      ),
    );
  }

  Widget _itemAvance(Avance avance) {
    final hora = "${avance.fecha.hour.toString().padLeft(2, '0')}:${avance.fecha.minute.toString().padLeft(2, '0')}";
    final fecha = "${avance.fecha.day}/${avance.fecha.month}/${avance.fecha.year}";

    return Card(
      color: const Color(0xFF181B35).withOpacity(0.9),
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF0D0F1F), child: Icon(Icons.construction, color: Colors.orange, size: 20)),
            title: Text(fecha, style: const TextStyle(color: Colors.white)),
            subtitle: Text('A las $hora', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 22),
                  onPressed: () => _mostrarFormularioAvance(avanceExistente: avance),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
                  onPressed: () => _confirmarEliminar(avance),
                ),
              ],
            ),
          ),
          if (avance.descripcion != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(avance.descripcion!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            ),
          if (avance.evidenciaFoto != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () => _verFotoGrande(avance.evidenciaFoto!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(File(avance.evidenciaFoto!), height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.orange.withOpacity(0.7)),
                const SizedBox(width: 5),
                Text('${avance.horasTrabajadas} horas dedicadas', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 90, height: 90, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.orange, size: 28), SizedBox(height: 4), Text('AÑADIR', style: TextStyle(color: Colors.orange, fontSize: 10))]),
    ),
  );

  Widget _buildPhotoPreview(String path, VoidCallback onDelete) => Container(
    width: 90, height: 90, margin: const EdgeInsets.only(right: 8),
    child: Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(path), width: 90, height: 90, fit: BoxFit.cover)),
      Positioned(top: 4, right: 4, child: GestureDetector(onTap: onDelete, child: const CircleAvatar(radius: 11, backgroundColor: Colors.redAccent, child: Icon(Icons.close, size: 14, color: Colors.white)))),
    ]),
  );

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.orange, size: 22),
      filled: true, fillColor: Colors.black26,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.orange, width: 2)),
    );
  }

  Widget _buildSourceBtn(IconData icon, String label, ImageSource source, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(children: [
        CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 30)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }

  void _verFotoGrande(String path) {
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: Stack(alignment: Alignment.topRight, children: [ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(path), fit: BoxFit.contain)), IconButton(icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)), onPressed: () => Navigator.pop(context))])));
  }

  void _confirmarEliminar(Avance avance) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar registro?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('MANTENER', style: TextStyle(color: Colors.white54))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(context, true), child: const Text('ELIMINAR')),
        ],
      ),
    );
    if (confirmar == true && avance.idAvance != null) {
      await _avanceDao.delete(avance.idAvance!);
      _cargarAvances();
    }
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_toggle_off, size: 80, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 16), Text('No hay registros', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16))]));
  }
}



