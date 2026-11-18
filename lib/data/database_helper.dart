import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Se encarga de abrir la base de datos SQLite y crear sus tablas.
///
/// Usa el patrón Singleton (visto en S20): existe UNA sola instancia
/// en toda la app, así nunca se abren dos conexiones al mismo archivo,
/// lo que podría bloquear o corromper la base de datos.
class DatabaseHelper {
  static const String _nombreBaseDatos = 'gastito.db';

  // Si en el futuro cambiamos la estructura de la tabla, subimos este número
  // y agregamos un onUpgrade (migración), como se vio en S20.
  static const int _version = 1;

  static const String tablaMovimientos = 'movimientos';

  // --- Singleton ---
  // 1. Constructor privado: nadie fuera de esta clase puede hacer DatabaseHelper().
  DatabaseHelper._privado();

  // 2. La única instancia, creada una sola vez.
  static final DatabaseHelper instancia = DatabaseHelper._privado();

  // 3. La conexión se guarda aquí después de abrirse por primera vez.
  static Database? _database;

  /// Devuelve la conexión. Si aún no existe, la abre; si ya existe, la reutiliza.
  Future<Database> get database async {
    _database ??= await _abrirBaseDatos(); // "??=" asigna solo si es null.
    return _database!;
  }

  Future<Database> _abrirBaseDatos() async {
    // Carpeta privada de la app donde Android guarda las bases de datos.
    final carpeta = await getDatabasesPath();
    final ruta = join(carpeta, _nombreBaseDatos);

    return openDatabase(
      ruta,
      version: _version,
      onCreate: _crearTablas, // Solo se ejecuta la primera vez que se crea el archivo.
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaMovimientos (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo        TEXT    NOT NULL,
        monto       REAL    NOT NULL,
        categoria   TEXT    NOT NULL,
        descripcion TEXT    NOT NULL,
        fecha       TEXT    NOT NULL,
        ruta_imagen TEXT,
        latitud     REAL,
        longitud    REAL
      )
    ''');
  }
}