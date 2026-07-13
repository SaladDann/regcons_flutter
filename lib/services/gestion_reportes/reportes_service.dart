import '../../db/app_db.dart';
import '../../db/daos/gestion_incidentes/incidente_dao.dart';
import '../../db/daos/gestion_obras/actividad_dao.dart';
import '../../db/daos/gestion_obras/avance_dao.dart';
import '../../db/daos/gestion_obras/obra_dao.dart';
import '../../models/gestion_obras/avance.dart';
import '../../models/gestion_reportes/reportes.dart';

class ReporteService {
  final AppDatabase _db = AppDatabase();
  final IncidenteDao _incidenteDao = IncidenteDao();

  /// Consolida toda la información de una obra para la generación de reportes ejecutivos
  Future<ReporteObraModel> generarDataReporte(int idObra, String responsable) async {
    final dbClient = await _db.database;

    final obraDao = ObraDao(dbClient);
    final actividadDao = ActividadDao(dbClient);
    final avanceDao = AvanceDao(dbClient);

    final obra = await obraDao.getById(idObra);
    if (obra == null) throw Exception('No se encontró la obra con ID: $idObra');

    final porcentajeAvance = await obraDao.calcularPorcentajeAvance(idObra);
    final statsAct = await actividadDao.getEstadisticasByObra(idObra);
    final listaActividades = await actividadDao.getByObra(idObra);
    final List<Avance> todosLosAvances = await avanceDao.getByObra(idObra);

    // Cálculo eficiente de horas hombre totales
    final acumuladoHoras = todosLosAvances.fold<double>(
        0.0,
            (sum, avance) => sum + (avance.horasTrabajadas ?? 0.0)
    );

    final incidentes = await _incidenteDao.listarPorObra(idObra);

    final riesgosCriticos = await _incidenteDao.listarConFiltros(
      idObra: idObra,
      severidad: 'CRITICA',
    );

    return ReporteObraModel(
      obra: obra,
      porcentajeAvance: porcentajeAvance,
      totalActividades: statsAct['total'] ?? 0,
      actividades: listaActividades,
      totalIncidentes: incidentes.length,
      incidentes: incidentes,
      riesgosActivos: riesgosCriticos.length,
      fechaGeneracion: DateTime.now(),
      responsable: responsable,
      totalHorasTrabajadas: acumuladoHoras,
      ultimosAvances: todosLosAvances,
      avanceSemanal: _calcularAvance7D(todosLosAvances),
    );
  }

  /// Determina el rendimiento de registros de avance en el último ciclo de 7 días
  double _calcularAvance7D(List<Avance> avances) {
    if (avances.isEmpty) return 0.0;

    final hace7Dias = DateTime.now().subtract(const Duration(days: 7));
    final recientes = avances.where((a) => a.fecha.isAfter(hace7Dias)).length;

    return (recientes / avances.length) * 100;
  }
}