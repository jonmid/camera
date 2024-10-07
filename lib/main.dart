import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera to Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _imageFile;
  final picker = ImagePicker();
  bool _uploading = false;
  String? _downloadURL;

  Future<void> _pickImage() async {
    setState(() {
      _imageFile = null;
      _downloadURL = null;
    });
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      final fileName = path.basename(_imageFile!.path);
      final storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');

      await storageRef.putFile(_imageFile!);

      String downloadURL = await storageRef.getDownloadURL();
      setState(() {
        _downloadURL = downloadURL;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }

    setState(() {
      _uploading = false;
    });
  }

  Future<void> _launchURL(String url) async {
    Uri urlParse = Uri.parse(url);
    if (await launchUrl(urlParse)) {
      await launchUrl(urlParse);
    } else {
      throw 'Could not launch $urlParse';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Camera to Firebase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null) ...[
              Image.file(_imageFile!, width: 200),
              const SizedBox(height: 10),
              _uploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _uploadImage,
                      child: const Text('Upload Image'),
                    ),
              if (_downloadURL != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => _launchURL(_downloadURL!),
                    child: Text(
                      'URL img firebase: $_downloadURL',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ] else
              const Text('No image has been selected.'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Take Photo',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
