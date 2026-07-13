import '../../db/daos/gestion_incidentes/incidente_dao.dart';
import '../../models/gestion_incidentes/incidente.dart';
import '../../models/gestion_obras/obra.dart';

class IncidenteService {
  final IncidenteDao _dao = IncidenteDao();

  /// Registra un nuevo incidente validando que la obra no esté finalizada
  Future<int> crearIncidente({
    required Obra obra,
    required Incidente incidente,
  }) async {
    _validarIncidente(obra, incidente);

    if (obra.estado == 'FINALIZADA') {
      throw Exception('No se pueden registrar incidentes en una obra finalizada');
    }

    return await _dao.insertarIncidente(incidente);
  }

  /// Actualiza un incidente existente verificando su existencia y el estado de la obra
  Future<int> actualizarIncidente({
    required Obra obra,
    required Incidente incidente,
  }) async {
    if (incidente.idReporte == null) {
      throw Exception('El incidente no existe');
    }

    _validarIncidente(obra, incidente);

    if (obra.estado == 'FINALIZADA') {
      throw Exception('No se pueden modificar incidentes de una obra finalizada');
    }

    return await _dao.actualizarIncidente(incidente);
  }

  /// Método unificado para persistir incidentes (Creación o Edición) según su ID
  Future<int> guardarIncidente({
    required Obra obra,
    required Incidente incidente,
  }) async {
    return (incidente.idReporte == null)
        ? await crearIncidente(obra: obra, incidente: incidente)
        : await actualizarIncidente(obra: obra, incidente: incidente);
  }

  /// Elimina un incidente del sistema si la obra asociada aún permite modificaciones
  Future<void> eliminarIncidente({
    required Obra obra,
    required int idReporte,
  }) async {
    if (obra.estado == 'FINALIZADA') {
      throw Exception('No se pueden eliminar incidentes de una obra finalizada');
    }
    await _dao.eliminarIncidente(idReporte);
  }

  /// Obtiene todos los incidentes asociados a una obra específica
  Future<List<Incidente>> listarPorObra(int idObra) {
    return _dao.listarPorObra(idObra);
  }

  /// Recupera incidentes aplicando filtros de tipo, severidad, estado, fechas y búsqueda textual
  Future<List<Incidente>> listarConFiltros({
    required int idObra,
    String? tipo,
    String? severidad,
    String? estado,
    String? textoBusqueda,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    return _dao.listarConFiltros(
      idObra: idObra,
      tipo: tipo,
      severidad: severidad,
      estado: estado,
      textoBusqueda: textoBusqueda,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  /// Actualiza el estado de flujo de un incidente validando contra los estados permitidos
  Future<void> cambiarEstado({
    required Obra obra,
    required int idReporte,
    required String nuevoEstado,
  }) async {
    const estadosValidos = ['REPORTADO', 'EN_ANALISIS', 'RESUELTO', 'CERRADO'];

    if (!estadosValidos.contains(nuevoEstado)) {
      throw Exception('Estado no válido');
    }

    if (obra.estado == 'FINALIZADA') {
      throw Exception('No se pueden cambiar estados en una obra finalizada');
    }

    await _dao.actualizarEstado(idReporte, nuevoEstado);
  }

  /// Valida la integridad de los datos del incidente y su relación con la obra actual
  void _validarIncidente(Obra obra, Incidente incidente) {
    if (incidente.descripcion.trim().isEmpty) {
      throw Exception('La descripción es obligatoria');
    }

    final tiposValidos = [
      'ACCIDENTE', 'INCIDENTE', 'CONDICION_INSEGURA',
      'ACTO_INSEGURO', 'FALLA_EQUIPO', 'DERRAME_MATERIAL', 'OTRO'
    ];

    if (!tiposValidos.contains(incidente.tipo)) {
      throw Exception('Tipo de incidente inválido');
    }

    final severidadesValidas = ['BAJA', 'MEDIA', 'ALTA', 'CRITICA'];
    if (!severidadesValidas.contains(incidente.severidad)) {
      throw Exception('Nivel de severidad inválido');
    }

    if (incidente.idObra != obra.idObra) {
      throw Exception('El incidente no pertenece a la obra seleccionada');
    }
  }
}
