import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'firebase_options.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Supabase
  await Supabase.initialize(
    url: 'https://erkbmehsbymitprwctxp.supabase.co',
    anonKey: 'sb_publishable_uewrozpZ0MwPt_p7d9lbCQ_HNn4ucMl',
  );

  // Inicializamos Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Para mayor seguridad: Cerramos sesión al iniciar "frío"
  await FirebaseAuth.instance.signOut();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tareas Privadas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Ocurrió un error';
        if (e.code == 'user-not-found') {
          message = 'Usuario no encontrado';
        } else if (e.code == 'wrong-password') {
          message = 'Contraseña incorrecta';
        } else if (e.code == 'invalid-email') {
          message = 'Email no válido';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario registrado con éxito')),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Error al registrar'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_person_rounded, size: 100, color: Colors.deepPurple),
                const SizedBox(height: 32),
                Text(
                  'Bienvenido',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa tu correo' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Iniciar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _handleRegister,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Registrarse'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  int _currentIndex = 0;

  // Variables para la Galería
  String? _selectedFolderId;
  String? _selectedFolderName;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Carpeta de Clase'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre de la clase (ej: Matemáticas)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance.collection('class_folders').add({
                    'name': controller.text,
                    'userId': user!.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  print('Error al crear carpeta: $e');
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadMedia(XFile media, String type) async {
    final nameController = TextEditingController();
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nombre de la ${type == 'image' ? 'Foto' : 'Video'}'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: 'Ej: ${type == 'image' ? 'Pizarra de hoy' : 'Explicación ejercicio'}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final name = nameController.text;
                Navigator.pop(context);
                
                try {
                  final bytes = await media.readAsBytes();
                  final fileExt = media.path.split('.').last;
                  final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                  final filePath = '${FirebaseAuth.instance.currentUser!.uid}/$fileName';

                  await Supabase.instance.client.storage
                      .from('media')
                      .uploadBinary(filePath, bytes);

                  final url = Supabase.instance.client.storage
                      .from('media')
                      .getPublicUrl(filePath);

                  await FirebaseFirestore.instance.collection('class_images').add({
                    'folderId': _selectedFolderId,
                    'userId': FirebaseAuth.instance.currentUser!.uid,
                    'name': name,
                    'url': url,
                    'type': type,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                } catch (e) {
                  print('Error al guardar media: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al subir media: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (_selectedFolderId == null) return;
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) _uploadMedia(photo, 'image');
  }

  Future<void> _takeVideo() async {
    if (_selectedFolderId == null) return;
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) _uploadMedia(video, 'video');
  }

  Future<void> _pickFromGallery() async {
    if (_selectedFolderId == null) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Imagen de Galería'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
              if (image != null) _uploadMedia(image, 'image');
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Video de Galería'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
              if (video != null) _uploadMedia(video, 'video');
            },
          ),
        ],
      ),
    );
  }

  void _showTaskDialog({DocumentSnapshot? doc}) async {
    final Map<String, dynamic>? data = doc != null ? doc.data() as Map<String, dynamic> : null;
    
    final titleController = TextEditingController(text: data?['title'] ?? '');
    final contentController = TextEditingController(text: data?['content'] ?? '');
    
    DateTime selectedDate = data?['deadlineDate'] != null 
        ? (data!['deadlineDate'] as Timestamp).toDate() 
        : DateTime.now();
        
    TimeOfDay selectedTime = data?['deadlineTime'] != null 
        ? TimeOfDay(
            hour: int.parse(data!['deadlineTime'].split(':')[0]), 
            minute: int.parse(data['deadlineTime'].split(':')[1]))
        : TimeOfDay.now();

    final bool isEditing = doc != null;
    bool isPinned = data?['isPinned'] == 1 || data?['isPinned'] == true;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Editar Tarea' : 'Nueva Tarea',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Anclar',
                        icon: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: isPinned ? Colors.deepPurple : Colors.grey,
                        ),
                        onPressed: () {
                          setModalState(() => isPinned = !isPinned);
                        },
                      ),
                      if (isEditing)
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(doc.id);
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Contenido', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Fecha Límite'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Hora Límite'),
                      subtitle: Text(selectedTime.format(context)),
                      leading: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final taskData = {
                        'userId': user.uid,
                        'title': titleController.text,
                        'content': contentController.text,
                        'createdAt': FieldValue.serverTimestamp(),
                        'deadlineDate': Timestamp.fromDate(selectedDate),
                        'deadlineTime': '${selectedTime.hour}:${selectedTime.minute}',
                        'isPinned': isPinned,
                      };

                      if (isEditing) {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(doc.id)
                            .update(taskData);
                      } else {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .add(taskData);
                      }
                      
                      if (mounted) Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEditing ? 'Actualizar' : 'Guardar'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('tasks').doc(id).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Mis Tareas' : 'Galería de Clases', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_selectedFolderId != null && _currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _selectedFolderId = null;
                _selectedFolderName = null;
              }),
            ),
          CircleAvatar(
            backgroundColor: Colors.deepPurple[50],
            child: Text(
              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_currentIndex == 0 || (_currentIndex == 2 && _selectedFolderId != null))
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _currentIndex == 0 ? 'Buscar en tus tareas...' : 'Buscar fotos en esta carpeta...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear), 
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        }
                      ) 
                    : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          Expanded(
            child: _buildBody(user!.uid),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _selectedFolderId = null; 
          });
        },
        selectedItemColor: Colors.deepPurple,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tareas'),
          BottomNavigationBarItem(icon: Icon(Icons.collections_rounded), label: 'Galería'),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 1) {
            if (_selectedFolderId == null) {
              _createFolder();
            } else {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Tomar Foto'),
                      onTap: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.videocam),
                      title: const Text('Grabar Video'),
                      onTap: () {
                        Navigator.pop(context);
                        _takeVideo();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Seleccionar de Galería'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromGallery();
                      },
                    ),
                  ],
                ),
              );
            }
          } else {
            _showTaskDialog();
          }
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: Icon(_currentIndex == 1 && _selectedFolderId != null ? Icons.add_a_photo : Icons.add),
      ),
    );
  }

  Widget _buildBody(String uid) {
    switch (_currentIndex) {
      case 0:
        return _buildTasksGrid(uid);
      case 1:
        return _selectedFolderId == null ? _buildFoldersGrid(uid) : _buildImagesGrid(uid);
      default:
        return Container();
    }
  }

  Widget _buildFoldersGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('class_folders')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final folders = snapshot.data?.docs ?? [];
        
        if (folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('Crea una carpeta para tus clases', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            final data = folder.data() as Map<String, dynamic>;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedFolderId = folder.id;
                  _selectedFolderName = data['name'];
                });
              },
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder, size: 60, color: Colors.amber),
                    const SizedBox(height: 8),
                    Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagesGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('class_images')
          .where('folderId', isEqualTo: _selectedFolderId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allImages = snapshot.data?.docs ?? [];
        final filteredImages = allImages.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'].toString().toLowerCase();
          final query = _searchController.text.toLowerCase();
          return name.contains(query);
        }).toList();

        if (filteredImages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(_searchController.text.isEmpty ? 'No hay fotos en "$_selectedFolderName"' : 'No se encontraron fotos', style: const TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: filteredImages.length,
          itemBuilder: (context, index) {
            final item = filteredImages[index];
            final data = item.data() as Map<String, dynamic>;
            final bool isVideo = data['type'] == 'video';
            final String url = data['url'] ?? data['imageUrl'] ?? '';

            return Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        isVideo 
                          ? Container(color: Colors.black12, child: const Icon(Icons.play_circle_fill, size: 40, color: Colors.white70))
                          : Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                        if (isVideo)
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: Icon(Icons.videocam, size: 16, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
                Text(data['name'], style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTasksGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((doc) {
          final title = doc['title'].toString().toLowerCase();
          final content = doc['content'].toString().toLowerCase();
          final query = _searchController.text.toLowerCase();
          return title.contains(query) || content.contains(query);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchController.text.isNotEmpty ? Icons.search_off : Icons.task_outlined, 
                  size: 80, 
                  color: Colors.grey[300]
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isNotEmpty ? 'No se encontraron resultados' : 'No hay tareas todavía',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18)
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final bool isPinned = data['isPinned'] == true;
            
            final DateTime deadline = (data['deadlineDate'] as Timestamp).toDate();
            final String deadlineStr = DateFormat('dd MMM').format(deadline);
            final String timeStr = data['deadlineTime'] ?? '';

            return GestureDetector(
              onTap: () => _showTaskDialog(doc: doc),
              onLongPress: () => _confirmDelete(doc.id),
              child: Card(
                elevation: isPinned ? 4 : 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isPinned 
                    ? BorderSide(color: Colors.deepPurple.withOpacity(0.3), width: 1)
                    : BorderSide.none,
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPinned)
                            const Icon(Icons.push_pin, size: 16, color: Colors.deepPurple),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          data['content'] ?? '',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 14, color: Colors.deepPurple),
                          const SizedBox(width: 4),
                          Text(deadlineStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}
