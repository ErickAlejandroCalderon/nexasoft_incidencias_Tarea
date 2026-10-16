import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';

void main() {
  group('BUG-002: Búsqueda flexible e inclusiva (título, descripción, case-insensitive, trim)', () {
    late GestorIncidencias gestor;

    setUp(() {
      gestor = GestorIncidencias();
      gestor.incidencias = [
        Incidencia(
          id: 'INC-101',
          titulo: 'Impresora del almacén no responde',
          descripcion: 'La impresora aparece conectada, pero los documentos permanecen en cola.',
          cliente: 'Almacenes del Centro',
          categoria: 'Hardware',
          estado: 'Pendiente',
          fecha: '2026-09-28',
        ),
        Incidencia(
          id: 'INC-102',
          titulo: 'WiFi intermitente en recepción',
          descripcion: 'La red inalámbrica se desconecta de forma aleatoria durante la mañana.',
          cliente: 'Clínica del Prado',
          categoria: 'Redes',
          estado: 'En proceso',
          fecha: '2026-09-29',
        ),
        Incidencia(
          id: 'INC-106',
          titulo: 'Configuración de VPN',
          descripcion: 'El personal remoto no puede establecer túnel de conexión seguro.',
          cliente: 'Servicios del Norte',
          categoria: 'Redes',
          estado: 'En proceso',
          fecha: '2026-10-03',
        ),
      ];
    });

    test('Búsqueda ignora mayúsculas y minúsculas ("wifi", "WiFi", "WIFI")', () {
      final resMin = gestor.buscar('wifi');
      expect(resMin.length, 1);
      expect(resMin.first.id, 'INC-102');

      final resMay = gestor.buscar('WiFi');
      expect(resMay.length, 1);
      expect(resMay.first.id, 'INC-102');

      final resTodoMay = gestor.buscar('WIFI');
      expect(resTodoMay.length, 1);
      expect(resTodoMay.first.id, 'INC-102');
    });

    test('Búsqueda encuentra términos que aparecen únicamente en la descripción ("túnel")', () {
      final res = gestor.buscar('túnel');
      expect(res.length, 1);
      expect(res.first.id, 'INC-106');
      expect(res.first.descripcion.contains('túnel'), isTrue);
    });

    test('Búsqueda ignora espacios sobrantes al inicio y al final ("  wifi  ", "  túnel  ")', () {
      final resEspacios = gestor.buscar('   wifi   ');
      expect(resEspacios.length, 1);
      expect(resEspacios.first.id, 'INC-102');

      final resEspacios2 = gestor.buscar('  túnel  ');
      expect(resEspacios2.length, 1);
      expect(resEspacios2.first.id, 'INC-106');
    });

    test('Cadena vacía o sólo espacios devuelve todos los registros sin descartar ninguno', () {
      final vacio = gestor.buscar('');
      expect(vacio.length, 3);

      final soloEspacios = gestor.buscar('     ');
      expect(soloEspacios.length, 3);
    });
  });
}
