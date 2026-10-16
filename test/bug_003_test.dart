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

  group('BUG-003: Exactitud y sincronización de los totales del tablero', () {
    late AlmacenLocalPrueba almacen;

    setUp(() {
      almacen = AlmacenLocalPrueba([
        Incidencia(
          id: 'INC-101',
          titulo: 'Impresora del almacén',
          descripcion: 'Documentos en cola',
          cliente: 'Almacenes',
          categoria: 'Hardware',
          estado: 'Pendiente',
          fecha: '2026-09-28',
        ),
        Incidencia(
          id: 'INC-102',
          titulo: 'WiFi recepción',
          descripcion: 'Red se desconecta',
          cliente: 'Clínica',
          categoria: 'Redes',
          estado: 'En proceso',
          fecha: '2026-09-29',
        ),
        Incidencia(
          id: 'INC-103',
          titulo: 'Pantalla azul',
          descripcion: 'Error tras iniciar',
          cliente: 'Servicios',
          categoria: 'Hardware',
          estado: 'Pendiente',
          fecha: '2026-09-30',
        ),
        Incidencia(
          id: 'INC-104',
          titulo: 'No llegan correos',
          descripcion: 'Notificaciones tardan',
          cliente: 'Almacenes',
          categoria: 'Software',
          estado: 'Resuelta',
          fecha: '2026-10-01',
        ),
      ]);
    });

    test('Los totales coinciden con el estado inicial (2 Pendientes, 1 En proceso, 1 Resuelta)', () async {
      final gestor = GestorIncidencias(datos: almacen);
      await gestor.iniciar();

      expect(gestor.contar('Pendiente'), 2);
      expect(gestor.contar('En proceso'), 1);
      expect(gestor.contar('Resuelta'), 1);
      expect(gestor.cantidadPendientes, 2);
    });

    test('El recuento se actualiza correctamente al pasar de Pendiente a Resuelta y viceversa', () async {
      final gestor = GestorIncidencias(datos: almacen);
      await gestor.iniciar();

      // Cambiar INC-101 de Pendiente a Resuelta
      await gestor.cambiarEstado('INC-101', 'Resuelta');

      expect(gestor.contar('Pendiente'), 1, reason: 'Pendientes debe decrementar de 2 a 1');
      expect(gestor.contar('Resuelta'), 2, reason: 'Resueltas debe incrementar de 1 a 2');
      expect(gestor.cantidadPendientes, 1);

      // Cambiar INC-101 de vuelta de Resuelta a Pendiente
      await gestor.cambiarEstado('INC-101', 'Pendiente');

      expect(gestor.contar('Pendiente'), 2, reason: 'Pendientes vuelve a 2');
      expect(gestor.contar('Resuelta'), 1, reason: 'Resueltas vuelve a 1');
      expect(gestor.cantidadPendientes, 2);
    });

    test('El recuento se actualiza al registrar una nueva incidencia y se conserva tras reiniciar', () async {
      final gestor1 = GestorIncidencias(datos: almacen);
      await gestor1.iniciar();

      expect(gestor1.contar('Pendiente'), 2);

      await gestor1.crear('Nueva falla', 'Detalle falla', 'Cliente X', 'Software');

      expect(gestor1.contar('Pendiente'), 3, reason: 'Se agregó una nueva pendiente');
      expect(gestor1.cantidadPendientes, 3);

      // Simular reinicio de la aplicación
      final gestor2 = GestorIncidencias(datos: almacen);
      await gestor2.iniciar();

      expect(gestor2.contar('Pendiente'), 3, reason: 'El total de pendientes debe conservarse tras reiniciar');
      expect(gestor2.contar('Resuelta'), 1);
      expect(gestor2.contar('En proceso'), 1);
    });

    test('Los totales generales no dependen de la búsqueda o de los filtros visuales', () async {
      final gestor = GestorIncidencias(datos: almacen);
      await gestor.iniciar();

      // Buscar algo que sólo arroje 1 resultado
      final resultadosBusqueda = gestor.buscar('WiFi');
      expect(resultadosBusqueda.length, 1);

      // Los totales generales del tablero NO deben verse afectados por la búsqueda
      expect(gestor.contar('Pendiente'), 2, reason: 'Los totales del tablero son globales y no dependen del filtro de búsqueda');
      expect(gestor.contar('En proceso'), 1);
      expect(gestor.contar('Resuelta'), 1);
    });
  });
}
