import '../../db/app_db.dart';
import '../../db/daos/gestion_obras/avance_dao.dart';
import '../../db/daos/gestion_obras/actividad_dao.dart';
import '../../models/gestion_obras/avance.dart';
import '../../models/gestion_obras/actividad.dart';

class AvanceService {
  late AvanceDao _avanceDao;
  late ActividadDao _actividadDao;
  bool _inicializado = false;

  /// Inicializa los DAOs necesarios para la gestión de avances
  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _avanceDao = AvanceDao(db);
      _actividadDao = ActividadDao(db);
      _inicializado = true;
    }
  }

  /// Registra un nuevo avance de obra validando la existencia de la actividad asociada
  Future<Avance> crearAvance({
    required int idActividad,
    required int idObra,
    required DateTime fecha,
    double? horasTrabajadas,
    String? descripcion,
    String? evidenciaFoto,
    String estado = 'REGISTRADO',
  }) async {
    await _initialize();

    final actividad = await _actividadDao.getById(idActividad);
    if (actividad == null) throw Exception('La actividad no existe');

    final nuevoAvance = Avance(
      idActividad: idActividad,
      idObra: idObra,
      fecha: fecha,
      horasTrabajadas: horasTrabajadas,
      descripcion: descripcion,
      evidenciaFoto: evidenciaFoto,
      estado: estado,
      sincronizado: 0,
    );

    final id = await _avanceDao.insert(nuevoAvance);
    nuevoAvance.idAvance = id;
    return nuevoAvance;
  }

  /// Actualiza los datos de un avance existente en la base de datos
  Future<Avance> actualizarAvance(Avance avance) async {
    await _initialize();
    if (avance.idAvance == null) throw Exception('El avance no tiene ID');
    await _avanceDao.update(avance);
    return avance;
  }

  /// Elimina un registro de avance de forma permanente
  Future<void> eliminarAvance(int idAvance) async {
    await _initialize();
    final avance = await _avanceDao.getById(idAvance);
    if (avance == null) throw Exception('El avance no existe');
    await _avanceDao.delete(idAvance);
  }

  /// Recupera el historial de avances vinculado a una actividad específica
  Future<List<Avance>> obtenerAvancesPorActividad(int idActividad) async {
    await _initialize();
    return await _avanceDao.getByActividad(idActividad);
  }

  /// Obtiene todos los avances registrados para una obra completa
  Future<List<Avance>> obtenerAvancesPorObra(int idObra) async {
    await _initialize();
    return await _avanceDao.getByObra(idObra);
  }

  /// Filtra los avances registrados dentro de un rango de fechas determinado
  Future<List<Avance>> obtenerAvancesPorFechaRange(DateTime inicio, DateTime fin) async {
    await _initialize();
    return await _avanceDao.getByFechaRange(inicio, fin);
  }

  /// Retorna el último registro de avance cargado para una actividad
  Future<Avance?> obtenerUltimoAvance(int idActividad) async {
    await _initialize();
    return await _avanceDao.getUltimoByActividad(idActividad);
  }

  /// Actualiza el estado del avance validando contra el flujo permitido por el sistema
  Future<void> cambiarEstadoAvance(int idAvance, String nuevoEstado) async {
    await _initialize();
    const estadosValidos = ['REGISTRADO', 'EN_PROCESO', 'FINALIZADO', 'CANCELADO'];
    if (!estadosValidos.contains(nuevoEstado)) throw Exception('Estado no válido: $nuevoEstado');
    await _avanceDao.updateEstado(idAvance, nuevoEstado);
  }

  /// Devuelve el conteo total de avances para una actividad
  Future<int> contarAvancesPorActividad(int idActividad) async {
    await _initialize();
    return await _avanceDao.countByActividad(idActividad);
  }

  /// Devuelve el conteo total de avances para una obra
  Future<int> contarAvancesPorObra(int idObra) async {
    await _initialize();
    return await _avanceDao.countByObra(idObra);
  }

  /// Calcula el acumulado de horas hombre trabajadas en una actividad
  Future<double> sumarHorasPorActividad(int idActividad) async {
    await _initialize();
    return await _avanceDao.sumHorasByActividad(idActividad);
  }

  /// Elimina masivamente todos los registros de avance de una actividad
  Future<void> eliminarAvancesPorActividad(int idActividad) async {
    await _initialize();
    await _avanceDao.deleteByActividad(idActividad);
  }

  /// Realiza una búsqueda de avances basada en coincidencias de texto
  Future<List<Avance>> buscarAvances(String query) async {
    await _initialize();
    return await _avanceDao.search(query);
  }

  /// Genera un mapa con métricas y estadísticas globales de los avances registrados
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    await _initialize();
    return await _avanceDao.getEstadisticas();
  }

  /// Genera un resumen consolidado de una actividad incluyendo sus avances y horas totales
  Future<Map<String, dynamic>> obtenerResumenActividad(int idActividad) async {
    await _initialize();

    final actividad = await _actividadDao.getById(idActividad);
    if (actividad == null) throw Exception('La actividad no existe');

    final avances = await _avanceDao.getByActividad(idActividad);
    final totalHoras = avances.fold<double>(0, (sum, a) => sum + (a.horasTrabajadas ?? 0));

    return {
      'actividad': actividad,
      'avances': avances,
      'total_avances': avances.length,
      'total_horas': totalHoras,
    };
  }

  /// Crea un informe de avances filtrado por obra o fechas con cálculo de horas totales
  Future<Map<String, dynamic>> generarReporteAvances({
    int? idObra,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    await _initialize();

    List<Avance> avances;
    if (idObra != null) {
      avances = await _avanceDao.getByObra(idObra);
    } else if (fechaInicio != null && fechaFin != null) {
      avances = await _avanceDao.getByFechaRange(fechaInicio, fechaFin);
    } else {
      avances = await _avanceDao.getAll();
    }

    final totalHoras = avances.fold<double>(0, (sum, a) => sum + (a.horasTrabajadas ?? 0));

    return {
      'total_avances': avances.length,
      'total_horas': totalHoras,
      'periodo': fechaInicio != null && fechaFin != null
          ? '${fechaInicio.toIso8601String()} - ${fechaFin.toIso8601String()}'
          : 'Todos',
      'avances': avances,
    };
  }

  /// Calcula el rendimiento porcentual de avances registrados en los últimos 7 días
  Future<double> calcularAvanceSemanal(int idObra) async {
    await _initialize();

    final hoy = DateTime.now();
    final hace7Dias = hoy.subtract(const Duration(days: 7));
    final avances = await obtenerAvancesPorObra(idObra);

    final avancesSemana = avances.where((a) =>
    a.fecha.isAfter(hace7Dias) && a.fecha.isBefore(hoy)
    ).toList();

    if (avances.isEmpty) return 0.0;
    return (avancesSemana.length / avances.length) * 100;
  }
}




