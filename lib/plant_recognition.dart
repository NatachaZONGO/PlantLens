import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:http/http.dart' as http;


class PlantSpeciesRecognition extends StatefulWidget {
  final int modelType;
  const PlantSpeciesRecognition(this.modelType, {super.key});

  @override
  State<PlantSpeciesRecognition> createState() => _PlantSpeciesRecognitionState();
}

class _PlantSpeciesRecognitionState extends State<PlantSpeciesRecognition>
    with TickerProviderStateMixin {
  File? _image;
  String _result = '';
  String _errorMessage = '';
  double _confidence = 0;
  bool _busy = false;
  bool _modelLoaded = false;
  late Interpreter _interpreter;
  List<String> _labels = [];

  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

  final Map<String, Map<String, dynamic>> _speciesInfo = {
    'marguerite': {'emoji': '🌼', 'color': const Color(0xFFFFF176)},
    'pissenlit': {'emoji': '🌾', 'color': const Color(0xFFA5D6A7)},
    'roses': {'emoji': '🌹', 'color': const Color(0xFFF48FB1)},
    'tournesols': {'emoji': '🌻', 'color': const Color(0xFFFFCC80)},
    'tulipes': {'emoji': '🌸', 'color': const Color(0xFFCE93D8)},
    'daisy': {'emoji': '🌼', 'color': const Color(0xFFFFF176)},
    'dandelion': {'emoji': '🌾', 'color': const Color(0xFFA5D6A7)},
    'sunflowers': {'emoji': '🌻', 'color': const Color(0xFFFFCC80)},
    'tulips': {'emoji': '🌸', 'color': const Color(0xFFCE93D8)},
    'other': {'emoji': '❓', 'color': const Color(0xFFE0E0E0)},
  };

  Color get _modelColor =>
      widget.modelType == 1 ? const Color(0xFF00C853) : const Color(0xFF2979FF);
  String get _modelName =>
      widget.modelType == 1 ? 'TensorFlow Lite' : 'Cloud Vision API';

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _resultAnimation = CurvedAnimation(parent: _resultController, curve: Curves.elasticOut);
    loadModel();
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  Future<void> loadModel() async {
    String labelsData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelsData.split('\n');
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
    setState(() => _modelLoaded = true);
  }

  Future<void> chooseImageGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _busy = true;
      _image = File(pickedFile.path);
      _result = '';
      _confidence = 0;
    });

    if (widget.modelType == 1) {
    await analyzeImage(_image!);
    } else if (widget.modelType == 0) {
        await visionAPICall(_image!);
    }

    setState(() => _busy = false);
    if (_result.isNotEmpty) _resultController.forward(from: 0);
  }

  Future<void> analyzeImage(File image) async {
    try {
      Uint8List imageBytes = await image.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);

      // Vérifier si l'image est valide
      if (decodedImage == null) {
        setState(() {
          _result = 'ERREUR';
          _errorMessage = 'Image invalide ou corrompue';
          _confidence = 0;
        });
        return;
      }

      img.Image resizedImage =
          img.copyResize(decodedImage, width: 224, height: 224);

      var inputBytes = Float32List(1 * 224 * 224 * 3);
      var index = 0;
      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          var pixel = resizedImage.getPixel(x, y);
          inputBytes[index++] = pixel.r / 255.0;
          inputBytes[index++] = pixel.g / 255.0;
          inputBytes[index++] = pixel.b / 255.0;
        }
      }
      var input = inputBytes.reshape([1, 224, 224, 3]);
      var output = Float32List(6).reshape([1, 6]);
      _interpreter.run(input, output);

      List<double> scores = List<double>.from(output[0]);
      int maxIndex = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
      double maxScore = scores[maxIndex] * 100;

      // Seuil de confiance : 85%
      if (maxScore < 85) {
        setState(() {
          _result = 'NON_RECONNUE';
          _errorMessage =
              'Image non reconnue comme une fleur connue.\nConfiance trop faible: ${maxScore.toStringAsFixed(1)}%';
          _confidence = maxScore;
        });
      } else {
        setState(() {
          _result = _labels[maxIndex];
          _errorMessage = '';
          _confidence = maxScore;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'ERREUR';
        _errorMessage = 'Erreur lors de l\'analyse de l\'image';
        _confidence = 0;
      });
    }
  }

  Future<void> visionAPICall(File image) async {
    try {
      // Encoder l'image en Base64
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Construire la requête JSON
      var requestBody = {
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {
                "type": "LABEL_DETECTION",
                "maxResults": 3
              }
            ]
          }
        ]
      };

      // Remplace par ta vraie clé API GCP
      const String apiKey = "VOTRE_CLE_API_GCP";
      final String url =
          "https://vision.googleapis.com/v1/images:annotate?key=$apiKey";

      // Envoyer la requête HTTP POST
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Décoder la réponse JSON
        var responseJson = json.decode(response.body);
        var labels =
            responseJson["responses"][0]["labelAnnotations"];

        if (labels != null && labels.isNotEmpty) {
          String topLabel = labels[0]["description"];
          double topScore =
              (labels[0]["score"] as double) * 100;

          setState(() {
            _result = topLabel;
            _confidence = topScore;
            _errorMessage = '';
          });
        } else {
          setState(() {
            _result = 'NON_RECONNUE';
            _errorMessage = 'Aucun label détecté par Cloud Vision';
            _confidence = 0;
          });
        }
      } else if (response.statusCode == 400 ||
          response.statusCode == 403) {
        setState(() {
          _result = 'ERREUR';
          _errorMessage =
              'Clé API invalide ou non configurée.\nVeuillez configurer une clé API GCP valide.';
          _confidence = 0;
        });
      } else {
        setState(() {
          _result = 'ERREUR';
          _errorMessage =
              'Erreur serveur (${response.statusCode}).\nVérifiez votre connexion internet.';
          _confidence = 0;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'ERREUR';
        _errorMessage =
            'Impossible de joindre Cloud Vision API.\nVérifiez votre connexion internet.';
        _confidence = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF0),
      appBar: AppBar(
        backgroundColor: _modelColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analyse végétale',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _modelLoaded ? Colors.white : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(_modelName, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Zone image cliquable
            GestureDetector(
              onTap: chooseImageGallery,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _modelColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: _modelColor.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _modelColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_photo_alternate_rounded,
                                  color: _modelColor, size: 52),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Appuyez ici pour\nchoisir une image',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _modelColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ou utilisez le bouton en bas',
                              style: TextStyle(color: Colors.black38, fontSize: 12),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_image!, fit: BoxFit.cover),
                            if (_busy)
                              Container(
                                color: Colors.black.withValues(alpha: 0.38),
                                child: Center(
                                  child: CircularProgressIndicator(color: _modelColor),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_result.isNotEmpty) _buildResultCard(),
            if (_result.isEmpty && !_busy && _image == null) _buildTipsCard(),
            if (_busy) _buildLoadingCard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: chooseImageGallery,
        backgroundColor: _modelColor,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text('Choisir image',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildResultCard() {
    // Cas d'erreur ou image non reconnue
    if (_result == 'ERREUR' || _result == 'NON_RECONNUE') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.red.shade200, width: 2),
        ),
        child: Column(
          children: [
            const Text('🤔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              _result == 'ERREUR' ? 'Erreur !' : 'Non reconnue',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              '✅ Espèces reconnues :',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: ['🌼 Marguerite', '🌻 Tournesol', '🌹 Rose',
                         '🌸 Tulipe', '🌾 Pissenlit']
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s,
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    // Cas normal - fleur reconnue
    final info = _speciesInfo[_result.toLowerCase()] ??
        {'emoji': '🌿', 'color': const Color(0xFFA5D6A7)};
    final emoji = info['emoji'] as String;
    final color = info['color'] as Color;

    // Avertissement si confiance entre 60% et 75%
    bool isLowConfidence = _confidence <92;

    return ScaleTransition(
      scale: _resultAnimation,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(
                  _result.toUpperCase(),
                  style: TextStyle(
                    color: _modelColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _confidence / 100,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation(
                        isLowConfidence ? Colors.orange : color),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_confidence.toStringAsFixed(1)}% de confiance',
                  style: TextStyle(
                    color: isLowConfidence ? Colors.orange : Colors.black45,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Avertissement confiance faible
          if (isLowConfidence) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confiance modérée. Essayez avec une image plus nette.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 Conseils',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          _tip('Prenez une photo claire et nette'),
          _tip('Centrez la fleur dans l\'image'),
          _tip('Bonne luminosité pour meilleur résultat'),
          _tip('Espèces: marguerite, pissenlit, rose, tournesol, tulipe'),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 3, color: _modelColor),
          ),
          const SizedBox(width: 16),
          Text('Analyse en cours...',
              style: TextStyle(
                  color: _modelColor, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}