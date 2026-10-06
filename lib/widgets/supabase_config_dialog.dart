import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SupabaseConfigDialog extends StatefulWidget {
  final VoidCallback? onConfigured;

  const SupabaseConfigDialog({super.key, this.onConfigured});

  @override
  State<SupabaseConfigDialog> createState() => _SupabaseConfigDialogState();
}

class _SupabaseConfigDialogState extends State<SupabaseConfigDialog> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;
  bool _isSuccess = false;

  static const Color bgColor = Color(0xFF1E2038);
  static const Color cardColor = Color(0xFF272948);
  static const Color accentCyan = Color(0xFF38C3FF);
  static const Color accentPurple = Color(0xFF8C62FF);

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final creds = await _supabaseService.getCredentials();
    setState(() {
      _urlController.text = creds['url'] ?? '';
      _keyController.text = creds['anonKey'] ?? '';
      _isLoading = false;
      _isSuccess = _supabaseService.isConfigured;
      _statusMessage = _supabaseService.isConfigured
          ? 'Conectado ao Supabase com sucesso!'
          : 'Não conectado ao Supabase.';
    });
  }

  Future<void> _saveConfig() async {
    final url = _urlController.text.trim();
    final anonKey = _keyController.text.trim();

    if (url.isEmpty || anonKey.isEmpty) {
      setState(() {
        _statusMessage = 'Por favor, preencha a URL e a Anon Key.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = 'Conectando ao Supabase...';
    });

    final success = await _supabaseService.updateConfig(url, anonKey);

    setState(() {
      _isSaving = false;
      _isSuccess = success;
      _statusMessage = success
          ? 'Conectado com sucesso!'
          : 'Falha ao conectar. Verifique as chaves e a conexão.';
    });

    if (success) {
      widget.onConfigured?.call();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _resetDefaults() async {
    setState(() => _isSaving = true);
    await _supabaseService.resetToDefaults();
    await _loadCurrentConfig();
    setState(() => _isSaving = false);
    widget.onConfigured?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: _isLoading
            ? const Center(
                heightFactor: 3,
                child: CircularProgressIndicator(color: accentCyan),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_sync_rounded,
                              color: accentCyan, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configurar Supabase',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Sincronização em nuvem e storage',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Badge
                    if (_statusMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isSuccess
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              color: _isSuccess
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: _isSuccess
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Campo URL
                    const Text('Supabase Project URL',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardColor,
                        hintText: 'https://xyz.supabase.co',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon:
                            const Icon(Icons.link, color: accentCyan, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Anon Key
                    const Text('Anon Public Key',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _keyController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardColor,
                        hintText: 'eyJhbGci...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Botões de Ação
                    Row(
                      children: [
                        TextButton(
                          onPressed: _resetDefaults,
                          child: const Text('Restaurar Padrão',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: _isSaving ? null : _saveConfig,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Salvar',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
