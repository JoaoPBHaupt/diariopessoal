import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carrega as variáveis de ambiente
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY'] ?? '',
      appId: dotenv.env['APP_ID'] ?? '',
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['PROJECT_ID'] ?? '',
    ),
  );

  runApp(DiaryApp());
}

class DiaryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meu Diário Pessoal',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Criar Conta' : 'Login - Meu Diário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isRegistering ? () => _register(context) : () => _login(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        _isRegistering ? 'CRIAR CONTA' : 'ENTRAR',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                  });
                },
                child: Text(
                  _isRegistering
                      ? 'Já tem uma conta? Faça login'
                      : 'Não tem uma conta? Registre-se',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DiaryListScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Erro ao fazer login';
        
        if (e.code == 'user-not-found') {
          message = 'Usuário não encontrado';
        } else if (e.code == 'wrong-password') {
          message = 'Senha incorreta';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await dotenv.load(fileName: ".env");

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DiaryListScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Erro ao criar conta';
        
        if (e.code == 'weak-password') {
          message = 'A senha é muito fraca';
        } else if (e.code == 'email-already-in-use') {
          message = 'Este email já está em uso';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

class DiaryEntry {
  final int? id;
  final String title;
  final String content;
  final String date;
  final String userId;
  final String? firebaseId;
  final bool isSynced;

  DiaryEntry({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.userId,
    this.firebaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'userId': userId,
      'firebaseId': firebaseId,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DiaryEntry fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: map['date'],
      userId: map['userId'],
      firebaseId: map['firebaseId'],
      isSynced: map['isSynced'] == 1,
    );
  }

  static DiaryEntry fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: data['date'] ?? '',
      userId: data['userId'] ?? '',
      firebaseId: doc.id,
      isSynced: true,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE diary_entries(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  content TEXT,
  date TEXT,
  userId TEXT,
  firebaseId TEXT,
  isSynced INTEGER
)
''');
  }

  Future<int> insertEntry(DiaryEntry entry) async {
    final db = await instance.database;
    return await db.insert('diary_entries', entry.toMap());
  }

  Future<int> updateEntry(DiaryEntry entry) async {
    final db = await instance.database;
    return await db.update(
      'diary_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DiaryEntry>> getEntries(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'diary_entries',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return result.map((json) => DiaryEntry.fromMap(json)).toList();
  }

  Future<List<DiaryEntry>> getUnsyncedEntries(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'diary_entries',
      where: 'userId = ? AND isSynced = ?',
      whereArgs: [userId, 0],
    );

    return result.map((json) => DiaryEntry.fromMap(json)).toList();
  }

  Future<void> markAsSynced(int id, String firebaseId) async {
    final db = await instance.database;
    await db.update(
      'diary_entries',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

class DiaryListScreen extends StatefulWidget {
  @override
  _DiaryListScreenState createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  late List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  late User _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _loadEntries();
    _startSyncTimer();
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _syncEntries(this.context);
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _entries = await DatabaseHelper.instance.getEntries(_currentUser.uid);
    } catch (e) {
      print('Erro ao carregar entradas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncEntries(BuildContext context) async {
    try {
      final unsyncedEntries = await DatabaseHelper.instance.getUnsyncedEntries(_currentUser.uid);
      
      for (var entry in unsyncedEntries) {
        final docRef = await _firestore
            .collection('users')
            .doc(_currentUser.uid)
            .collection('diary_entries')
            .add(entry.toFirestore());
        
        await DatabaseHelper.instance.markAsSynced(entry.id!, docRef.id);
      }
      
      if (unsyncedEntries.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${unsyncedEntries.length} entradas sincronizadas com sucesso!')),
        );
        _loadEntries();
      }
    } catch (e) {
      print('Erro ao sincronizar entradas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sincronizar com a nuvem')),
      );
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry, BuildContext context) async {
    try {
      await DatabaseHelper.instance.deleteEntry(entry.id!);
      
      if (entry.firebaseId != null) {
        await _firestore
            .collection('users')
            .doc(_currentUser.uid)
            .collection('diary_entries')
            .doc(entry.firebaseId!)
            .delete();
      }
      
      _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entrada excluída com sucesso')),
      );
    } catch (e) {
      print('Erro ao excluir entrada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir entrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Diário Pessoal'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => _syncEntries(context),
            tooltip: 'Sincronizar com a nuvem',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Seu diário está vazio',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Toque no botão + para adicionar sua primeira entrada',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          entry.title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              entry.content.length > 50
                                  ? '${entry.content.substring(0, 50)}...'
                                  : entry.content,
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Icon(
                                  entry.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                                  size: 16,
                                  color: entry.isSynced ? Colors.green : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DiaryEntryScreen(
                                entry: entry,
                                onEntrySaved: _loadEntries,
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[300]),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Excluir entrada'),
                                content: Text('Tem certeza que deseja excluir esta entrada?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text('CANCELAR'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _deleteEntry(entry, context);
                                    },
                                    child: Text('EXCLUIR'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DiaryEntryScreen(
                onEntrySaved: _loadEntries,
              ),
            ),
          );
        },
      ),
    );
  }
}

class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? entry;
  final Function onEntrySaved;

  DiaryEntryScreen({this.entry, required this.onEntrySaved});

  @override
  _DiaryEntryScreenState createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late String _date;
  bool _isLoading = false;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _date = widget.entry!.date;
    } else {
      _date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  Future<void> _saveEntry(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final DiaryEntry newEntry = DiaryEntry(
          id: widget.entry?.id,
          title: _titleController.text,
          content: _contentController.text,
          date: _date,
          userId: _currentUser.uid,
          firebaseId: widget.entry?.firebaseId,
          isSynced: false,
        );

        if (widget.entry == null) {
          await DatabaseHelper.instance.insertEntry(newEntry);
        } else {
          await DatabaseHelper.instance.updateEntry(newEntry);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entrada salva com sucesso!')),
        );
        
        widget.onEntrySaved();
        Navigator.of(context).pop();
      } catch (e) {
        print('Erro ao salvar entrada: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar entrada')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Nova Entrada' : 'Editar Entrada'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : () => _saveEntry(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Data: $_date',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um título';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Conteúdo',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o conteúdo';
                          }
                          return null;
                        },
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}