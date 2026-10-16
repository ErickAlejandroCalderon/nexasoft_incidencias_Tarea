import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos;
  List<Incidencia> incidencias = [];
  int cantidadPendientes = 0;

  GestorIncidencias({AlmacenLocal? datos}) : datos = datos ?? AlmacenLocal();

  Future<void> iniciar() async {
    incidencias = await datos.leer();
    cantidadPendientes =
        incidencias.where((x) => x.estado == 'Pendiente').length;
  }

  List<Incidencia> buscar(String texto) {
    final consulta = texto.trim().toLowerCase();
    if (consulta.isEmpty) return incidencias;
    return incidencias.where((x) {
      final titulo = x.titulo.toLowerCase();
      final descripcion = x.descripcion.toLowerCase();
      return titulo.contains(consulta) || descripcion.contains(consulta);
    }).toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) {
    if (estado == 'Pendiente') return cantidadPendientes;
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

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria) async {
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
    );
    incidencias.insert(0, nuevo);
    cantidadPendientes++;
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
