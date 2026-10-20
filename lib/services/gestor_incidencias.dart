import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos;
  List<Incidencia> incidencias = [];
  int get cantidadPendientes => contar('Pendiente');

  GestorIncidencias({AlmacenLocal? datos}) : datos = datos ?? AlmacenLocal();

  Future<void> iniciar() async {
    incidencias = await datos.leer();
  }

  List<Incidencia> filtrar({
    String texto = '',
    String estado = 'Todos',
    String prioridad = 'Todas',
  }) {
    final consulta = texto.trim().toLowerCase();
    return incidencias.where((x) {
      final coincideTexto = consulta.isEmpty ||
          x.titulo.toLowerCase().contains(consulta) ||
          x.descripcion.toLowerCase().contains(consulta);

      final coincideEstado =
          estado == 'Todos' || x.estado.toLowerCase() == estado.toLowerCase();

      final coincidePrioridad = prioridad == 'Todas' ||
          x.prioridad.toLowerCase() == prioridad.toLowerCase();

      return coincideTexto && coincideEstado && coincidePrioridad;
    }).toList();
  }

  List<Incidencia> buscar(String texto) {
    return filtrar(texto: texto);
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) {
    return incidencias.where((x) => x.estado == estado).length;
  }

  Future<void> cambiarEstado(String id, String estado) async {
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].estado = estado;
        await datos.guardar(incidencias);
        break;
      }
    }
  }

  Future<void> cambiarPrioridad(String id, String nuevaPrioridad) async {
    if (!Incidencia.prioridadesValidas.contains(nuevaPrioridad)) return;
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].prioridad = nuevaPrioridad;
        await datos.guardar(incidencias);
        break;
      }
    }
  }

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria, {String prioridad = Incidencia.prioridadPorDefecto}) async {
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
      prioridad: prioridad,
    );
    incidencias.insert(0, nuevo);
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
