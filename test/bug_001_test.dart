import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/data/almacen_local.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';

class AlmacenLocalPrueba extends AlmacenLocal {
  List<Incidencia> _almacen = [];

  AlmacenLocalPrueba(List<Incidencia> inicial) {
    _almacen = inicial.map((x) => Incidencia.desdeJson(x.toJson())).toList();
  }

  @override
  Future<List<Incidencia>> leer() async {
    return _almacen.map((x) => Incidencia.desdeJson(x.toJson())).toList();
  }

  @override
  Future<void> guardar(List<Incidencia> lista) async {
    _almacen = lista.map((x) => Incidencia.desdeJson(x.toJson())).toList();
  }

  @override
  Future<void> restaurarDatosDeEjemplo() async {
    _almacen = [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BUG-001: Persistencia del cambio de estado y nuevas incidencias', () {
    late AlmacenLocalPrueba almacen;

    setUp(() {
      almacen = AlmacenLocalPrueba([
        Incidencia(
          id: 'INC-101',
          titulo: 'Impresora del almacén no responde',
          descripcion: 'Documentos permanecen en cola.',
          cliente: 'Almacenes del Centro',
          categoria: 'Hardware',
          estado: 'Pendiente',
          fecha: '2026-09-28',
        ),
        Incidencia(
          id: 'INC-102',
          titulo: 'WiFi intermitente en recepción',
          descripcion: 'Red inalámbrica se desconecta.',
          cliente: 'Clínica del Prado',
          categoria: 'Redes',
          estado: 'En proceso',
          fecha: '2026-09-29',
        ),
      ]);
    });

    test('El cambio de estado persiste al reiniciar la aplicación y no altera los demás registros', () async {
      // 1. Iniciar gestor
      final gestor1 = GestorIncidencias(datos: almacen);
      await gestor1.iniciar();

      final inc101Antes = gestor1.porId('INC-101');
      expect(inc101Antes, isNotNull);
      expect(inc101Antes!.id, 'INC-101');
      expect(inc101Antes.estado, 'Pendiente');

      final inc102Antes = gestor1.porId('INC-102');
      expect(inc102Antes!.estado, 'En proceso');

      // 2. Cambiar estado de INC-101 a Resuelta
      await gestor1.cambiarEstado('INC-101', 'Resuelta');

      // Comprobar en memoria
      expect(gestor1.porId('INC-101')!.estado, 'Resuelta');
      expect(gestor1.porId('INC-102')!.estado, 'En proceso',
          reason: 'El cambio de estado de INC-101 no debe alterar INC-102');

      // 3. Simular cerrar y abrir la aplicación (nueva instancia de GestorIncidencias)
      final gestor2 = GestorIncidencias(datos: almacen);
      await gestor2.iniciar();

      final inc101DespuesReinicio = gestor2.porId('INC-101');
      expect(inc101DespuesReinicio, isNotNull);
      expect(inc101DespuesReinicio!.id, 'INC-101',
          reason: 'El ID debe ser el mismo tras reiniciar');
      expect(inc101DespuesReinicio.estado, 'Resuelta',
          reason: 'El nuevo estado debe conservarse tras reiniciar');

      final inc102DespuesReinicio = gestor2.porId('INC-102');
      expect(inc102DespuesReinicio!.estado, 'En proceso');
    });

    test('Registrar una incidencia nueva y verificar que sigue existiendo tras reiniciar', () async {
      final gestor1 = GestorIncidencias(datos: almacen);
      await gestor1.iniciar();

      await gestor1.crear(
        'Fallo de monitor',
        'El monitor no enciende tras apagón',
        'Hospital Central',
        'Hardware',
      );

      final nuevaCreada = gestor1.incidencias.first;
      final nuevoId = nuevaCreada.id;
      expect(nuevaCreada.titulo, 'Fallo de monitor');
      expect(nuevaCreada.estado, 'Pendiente');

      // Simular reinicio
      final gestor2 = GestorIncidencias(datos: almacen);
      await gestor2.iniciar();

      final recuperada = gestor2.porId(nuevoId);
      expect(recuperada, isNotNull,
          reason: 'La incidencia recién creada debe seguir existiendo tras reiniciar');
      expect(recuperada!.titulo, 'Fallo de monitor');
      expect(recuperada.estado, 'Pendiente');
    });
  });
}
