import 'package:regcons/db/app_db.dart';
import 'package:regcons/services/gestion_obras/usuario_obra_service.dart';
import '../../db/daos/gestion_obras/avance_dao.dart';
import '../../db/daos/gestion_obras/obra_dao.dart';
import '../../db/daos/gestion_obras/usuario_obra_dao.dart';
import '../../models/gestion_obras/obra.dart';
import '../../models/gestion_obras/usuario_obra.dart';
import 'actividad_service.dart';
import 'avance_service.dart';

class ObraService {
  late ObraDao _obraDao;
  bool _inicializado = false;

  /// Inicializa el DAO de obras asegurando la disponibilidad de la base de datos
  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _obraDao = ObraDao(db);
      _inicializado = true;
    }
  }

  // --- MÉTODOS DE FILTRADO POR USUARIO (SEGURIDAD) ---

  /// Recupera todas las obras (cualquier estado) vinculadas a un usuario específico
  Future<List<Obra>> obtenerObrasPorUsuario(int idUsuario) async {
    await _initialize();

    final usuarioObraService = UsuarioObraService();
    final idsPermitidos = await usuarioObraService.obtenerObrasDeUsuario(idUsuario);

    final todas = await _obraDao.getAll();

    final obrasFiltradas = todas.where((o) => idsPermitidos.contains(o.idObra)).toList();

    for (var obra in obrasFiltradas) {
      if (obra.idObra != null) {
        obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(obra.idObra!);
      }
    }
    return obrasFiltradas;
  }

  /// Obtiene solo las obras ACTIVAS vinculadas a un usuario (Para el Home)
  Future<List<Obra>> obtenerObrasActivasPorUsuario(int idUsuario) async {
    await _initialize();

    final usuarioObraService = UsuarioObraService();
    final idsPermitidos = await usuarioObraService.obtenerObrasDeUsuario(idUsuario);

    final todasActivas = await _obraDao.getActivas();

    final obrasFiltradas = todasActivas.where((obra) =>
        idsPermitidos.contains(obra.idObra)
    ).toList();

    for (var obra in obrasFiltradas) {
      if (obra.idObra != null) {
        obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(obra.idObra!);
      }
    }
    return obrasFiltradas;
  }

  /// Genera estadísticas filtradas específicamente para la sesión del usuario actual
  Future<Map<String, int>> getEstadisticasPorUsuario(int idUsuario) async {
    await _initialize();

    final usuarioObraService = UsuarioObraService();
    final idsPermitidos = await usuarioObraService.obtenerObrasDeUsuario(idUsuario);

    final todasLasObras = await _obraDao.getAll();

    final obrasDelUsuario = todasLasObras.where((obra) =>
        idsPermitidos.contains(obra.idObra)
    ).toList();

    return {
      'total': obrasDelUsuario.length,
      'activas': obrasDelUsuario.where((o) => o.estado == 'ACTIVA').length,
      'planificadas': obrasDelUsuario.where((o) => o.estado == 'PLANIFICADA').length,
      'finalizadas': obrasDelUsuario.where((o) => o.estado == 'FINALIZADA').length,
    };
  }

  // --- OPERACIONES CRUD ---

  /// Registra una nueva obra y crea el vínculo de propiedad inmediatamente
  /// Registra una nueva obra y la vincula al usuario que la creó
  Future<int> crearObra(Obra obra, int idUsuario) async {
    await _initialize();

    // 1. Usamos ObraDao para insertar la obra
    // Retorna el ID autogenerado de la nueva obra
    final idNuevaObra = await _obraDao.insert(obra);

    // 2. Usamos UsuarioObraDao para crear el permiso
    // Necesitamos la base de datos para inicializar el DAO pivot
    final db = await AppDatabase().database;
    final usuarioObraDao = UsuarioObraDao(db);

    await usuarioObraDao.insert(UsuarioObra(
      idUsuario: idUsuario,
      idObra: idNuevaObra,
    ));

    return idNuevaObra;
  }

  Future<int> actualizarObra(Obra obra) async {
    await _initialize();
    return await _obraDao.update(obra);
  }

  Future<int> eliminarObra(int idObra) async {
    await _initialize();
    return await _obraDao.delete(idObra);
  }

  // --- DETALLES Y PROCESAMIENTO ---

  Future<Obra?> obtenerObraPorId(int idObra) async {
    await _initialize();
    final obra = await _obraDao.getById(idObra);
    if (obra != null && obra.idObra != null) {
      obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(idObra);
    }
    return obra;
  }

  Future<Map<String, dynamic>> obtenerObraCompleta(int idObra) async {
    await _initialize();

    final obra = await _obraDao.getById(idObra);
    if (obra == null) throw Exception('Obra no encontrada');

    final actividadesService = ActividadService();
    final avancesService = AvanceService();

    final actividades = await actividadesService.obtenerActividadesPorObra(idObra);
    final resumen = await actividadesService.obtenerResumenObra(idObra);
    final reporteAvances = await avancesService.generarReporteAvances(idObra: idObra);

    obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(idObra);

    return {
      'obra': obra,
      'actividades': actividades,
      'resumen': resumen,
      'reporte_avances': reporteAvances,
      'porcentaje_avance': obra.porcentajeAvance,
      'total_actividades': actividades.length,
    };
  }

  /// Borrado en cascada (Limpia también la tabla intermedia Usuario-Obra)
  Future<void> eliminarObraCompleta(int idObra) async {
    await _initialize();
    final actividadService = ActividadService();
    final db = await AppDatabase().database;
    final actividades = await actividadService.obtenerActividadesPorObra(idObra);

    for (var actividad in actividades) {
      if (actividad.idActividad != null) {
        final avanceDao = AvanceDao(db);
        await avanceDao.deleteByActividad(actividad.idActividad!);
        await actividadService.eliminarActividad(actividad.idActividad!);
      }
    }

    try {
      await UsuarioObraService().eliminarTodosUsuariosDeObra(idObra);
    } catch (_) {}

    await _obraDao.delete(idObra);
  }

  Future<List<String>> getEstadosDisponibles() async {
    return ['PLANIFICADA', 'ACTIVA', 'SUSPENDIDA', 'FINALIZADA'];
  }

  Future<double> calcularPorcentajeAvance(int idObra) async {
    await _initialize();
    return await _obraDao.calcularPorcentajeAvance(idObra);
  }
}