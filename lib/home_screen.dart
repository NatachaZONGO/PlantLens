import 'package:flutter/material.dart';
import 'plant_recognition.dart';
import 'choose_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF0),
      drawer: _buildDrawer(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF00C853),
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
          onPressed: () => _showInfoDialog(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFF00C853),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('🌿', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PlantLens',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Reconnaissance végétale par IA',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Stats
          Row(
            children: [
              _buildStatCard('5', 'Espèces', Icons.eco_rounded, const Color(0xFF00C853)),
              const SizedBox(width: 12),
              _buildStatCard('87%', 'Précision', Icons.analytics_rounded, const Color(0xFFFF6F00)),
              const SizedBox(width: 12),
              _buildStatCard('IA', 'Embarquée', Icons.memory_rounded, const Color(0xFF2979FF)),
            ],
          ),

          const SizedBox(height: 28),

          // Espèces EN HAUT
          const Text(
            '🌸 Espèces reconnues',
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _buildSpeciesRow(),

          const SizedBox(height: 28),

          const Text(
            '🤖 Choisir un modèle',
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sélectionnez la méthode d\'analyse',
            style: TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // TFLite Card
          _buildModelCard(
            context,
            title: 'TensorFlow Lite',
            subtitle: 'Hors-ligne • Rapide • Embarqué',
            description: 'Modèle IA directement sur votre appareil. Fonctionne sans connexion internet.',
            emoji: '🧠',
            color: const Color(0xFF00C853),
            lightColor: const Color(0xFFE8F5E9),
            modelType: 1,
            badge: 'RECOMMANDÉ',
          ),
          const SizedBox(height: 14),

          // Cloud Card
          _buildModelCard(
            context,
            title: 'Cloud Vision API',
            subtitle: 'Cloud • Google AI • Précis',
            description: 'Service Google Cloud pour une reconnaissance avancée. Nécessite internet.',
            emoji: '☁️',
            color: const Color(0xFF2979FF),
            lightColor: const Color(0xFFE3F2FD),
            modelType: 0,
            badge: 'CLOUD',
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.black45, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesRow() {
    final species = [
      {'emoji': '🌼', 'name': 'Marguerite', 'color': const Color(0xFFFFF9C4)},
      {'emoji': '🌻', 'name': 'Tournesol', 'color': const Color(0xFFFFE0B2)},
      {'emoji': '🌹', 'name': 'Rose', 'color': const Color(0xFFFCE4EC)},
      {'emoji': '🌸', 'name': 'Tulipe', 'color': const Color(0xFFF3E5F5)},
      {'emoji': '🌾', 'name': 'Pissenlit', 'color': const Color(0xFFE8F5E9)},
    ];

    return SizedBox(
      height: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: species.map((s) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: s['color'] as Color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(s['emoji'] as String, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    s['name'] as String,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required String emoji,
    required Color color,
    required Color lightColor,
    required int modelType,
    required String badge,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlantSpeciesRecognition(modelType)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Utiliser',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            color: const Color(0xFF00C853),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('🌿', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PlantLens',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('v1.0.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDrawerItem(context, Icons.home_rounded, 'Accueil', const Color(0xFF00C853), () => Navigator.pop(context)),
          _buildDrawerItem(context, Icons.memory_rounded, 'TensorFlow Lite', const Color(0xFF00C853), () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantSpeciesRecognition(1)));
          }),
          _buildDrawerItem(context, Icons.cloud_rounded, 'Cloud Vision API', const Color(0xFF2979FF), () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantSpeciesRecognition(0)));
          }),
          const Divider(indent: 20, endIndent: 20),
          _buildDrawerItem(context, Icons.info_rounded, 'À propos', Colors.black45, () {
            Navigator.pop(context);
            _showInfoDialog(context);
          }),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Projet Intelligence Embarquée\nUniversité Joseph KI-ZERBO',
              style: TextStyle(color: Colors.black26, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🌿 ', style: TextStyle(fontSize: 24)),
            Text('PlantLens',
                style: TextStyle(color: Color(0xFF00C853), fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Application de reconnaissance végétale par Intelligence Artificielle embarquée.\n\nReconnaît 5 espèces de fleurs avec une précision de 87%.\n\nProjet M2 RIoT/IE\nUniversité Joseph KI-ZERBO',
          style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}