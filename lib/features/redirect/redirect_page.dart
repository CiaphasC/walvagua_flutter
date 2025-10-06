import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectPage extends StatelessWidget {
  const RedirectPage({super.key, required this.redirectUrl});

  final String redirectUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WallVagua'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estamos en mantenimiento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Por ahora no podemos mostrar el contenido de la app. '
              'Puedes visitar nuestro sitio para más información.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openUrl(context),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir enlace'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(redirectUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace no disponible.')),
      );
      return;
    }
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }
}
