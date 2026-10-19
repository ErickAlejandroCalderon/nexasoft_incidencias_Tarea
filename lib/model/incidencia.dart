class Incidencia {
  static const List<String> prioridadesValidas = ['Baja', 'Media', 'Alta'];
  static const String prioridadPorDefecto = 'Media';

  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String fecha;
  String prioridad;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.fecha,
    this.prioridad = prioridadPorDefecto,
  }) {
    if (!prioridadesValidas.contains(prioridad)) {
      prioridad = prioridadPorDefecto;
    }
  }

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
    final pRaw = m['prioridad']?.toString() ?? prioridadPorDefecto;
    final pValida = prioridadesValidas.contains(pRaw) ? pRaw : prioridadPorDefecto;
    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      fecha: m['fecha']?.toString() ?? '',
      prioridad: pValida,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'fecha': fecha,
      'prioridad': prioridad,
    };
  }
}
