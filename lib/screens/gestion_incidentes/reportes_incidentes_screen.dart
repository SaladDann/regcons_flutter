import 'package:flutter/material.dart';
import '../../models/gestion_incidentes/incidente.dart';
import '../../models/gestion_obras/obra.dart';
import '../../services/gestion_incidentes/incidente_service.dart';
import 'incidente_form_screen.dart';

class IncidentesScreen extends StatefulWidget {
  final Obra obra;
  const IncidentesScreen({super.key, required this.obra});

  @override
  State<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends State<IncidentesScreen> {
  final IncidenteService _service = IncidenteService();

  List<Incidente> _allIncidentes = [];
  List<Incidente> _filteredIncidentes = [];
  bool _isLoading = true;
  bool _isSearching = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedSeverity = 'TODOS';

  @override
  void initState() {
    super.initState();
    _cargarIncidentes();
  }

  /// Carga datos y sincroniza las listas localmente
  Future<void> _cargarIncidentes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.listarPorObra(widget.obra.idObra!);
      setState(() {
        _allIncidentes = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Filtra por texto (tipo/descripción/fecha) y severidad simultáneamente
  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredIncidentes = _allIncidentes.where((inc) {
        final matchesText = inc.tipo.toLowerCase().contains(query) ||
            inc.descripcion.toLowerCase().contains(query) ||
            inc.fechaEventoFormatted.contains(query);

        final matchesSeverity = _selectedSeverity == 'TODOS' ||
            inc.severidad.toUpperCase() == _selectedSeverity;

        return matchesText && matchesSeverity;
      }).toList();
    });
  }

  Color _getSeveridadColor(String sev) {
    switch (sev.toUpperCase()) {
      case 'CRITICA': return Colors.redAccent;
      case 'ALTA': return Colors.orangeAccent;
      case 'MEDIA': return Colors.yellowAccent;
      case 'BAJA': return Colors.greenAccent;
      default: return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esFinalizada = widget.obra.estado == 'FINALIZADA';

    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      appBar: _buildAppBar(),
      floatingActionButton: esFinalizada ? null : _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarIncidentes,
              color: Colors.orange,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : _buildMainList(esFinalizada),
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar con Switch de búsqueda
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF181B35),
      leading: _isSearching ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => setState(() {
          _isSearching = false;
          _searchCtrl.clear();
          _applyFilters();
        }),
      ) : null,
      title: _isSearching
          ? TextField(
        controller: _searchCtrl,
        onChanged: (_) => _applyFilters(),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Buscar por tipo, fecha...',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
      )
          : Text(widget.obra.nombre, style: const TextStyle(fontSize: 16, color: Colors.blueAccent)),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() => _isSearching = true),
          ),
      ],
    );
  }

  /// Selector de niveles para filtrado rápido en campo
  Widget _buildFilterBar() {
    final niveles = ['TODOS', 'BAJA', 'MEDIA', 'ALTA', 'CRITICA'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: niveles.length,
        itemBuilder: (context, index) {
          final nivel = niveles[index];
          final isSelected = _selectedSeverity == nivel;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(nivel, style: TextStyle(
                color: isSelected ? Colors.black : Colors.white60,
                fontSize: 11,
              )),
              selected: isSelected,
              selectedColor: Colors.orange,
              backgroundColor: const Color(0xFF181B35),
              onSelected: (val) {
                setState(() => _selectedSeverity = nivel);
                _applyFilters();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainList(bool esFinalizada) {
    if (_filteredIncidentes.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
      itemCount: _filteredIncidentes.length,
      itemBuilder: (context, index) => _buildIncidenteCard(_filteredIncidentes[index], esFinalizada),
    );
  }

  Widget _buildIncidenteCard(Incidente incidente, bool esFinalizada) {
    final colorSev = _getSeveridadColor(incidente.severidad);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: Key(incidente.idReporte.toString()),
          direction: esFinalizada ? DismissDirection.none : DismissDirection.endToStart,
          confirmDismiss: (dir) => _confirmarEliminacion(incidente),
          background: _buildDismissibleBg(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(incidente, colorSev),
                const SizedBox(height: 10),
                Text(
                  incidente.descripcion,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                _buildCardFooter(incidente, esFinalizada),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Incidente incidente, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: color),
              const SizedBox(width: 8),
              Text(incidente.tipo, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
        _buildRiskBadge(incidente.severidad, color),
      ],
    );
  }

  Widget _buildCardFooter(Incidente incidente, bool esFinalizada) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text(incidente.fechaEventoFormatted, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        if (!esFinalizada)
          Row(
            children: [
              _circleActionBtn(Icons.edit_outlined, Colors.blueAccent, () => _abrirFormulario(incidente: incidente)),
              const SizedBox(width: 12),
              _circleActionBtn(Icons.delete_outline, Colors.redAccent, () => _confirmarEliminacion(incidente)),
            ],
          ),
      ],
    );
  }

  Widget _buildRiskBadge(String severidad, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(severidad, style: TextStyle(color: color, fontSize: 10, letterSpacing: 0.5)),
    );
  }

  Widget _buildDismissibleBg() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.redAccent,
      child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
    );
  }

  Widget _circleActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.3))),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 70, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('SIN RESULTADOS',
              style: TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.orange,
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NUEVO INCIDENTE', style: TextStyle(color: Colors.white, letterSpacing: 0.5)),
      ),
    );
  }

  Future<bool> _confirmarEliminacion(Incidente incidente) async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Eliminar registro?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.eliminarIncidente(obra: widget.obra, idReporte: incidente.idReporte!);
      _cargarIncidentes();
      return true;
    }
    return false;
  }

  Future<void> _abrirFormulario({Incidente? incidente}) async {
    if (widget.obra.estado == 'FINALIZADA') return;
    await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IncidenteFormScreen(obra: widget.obra, incidente: incidente))
    );
    _cargarIncidentes();
  }
}