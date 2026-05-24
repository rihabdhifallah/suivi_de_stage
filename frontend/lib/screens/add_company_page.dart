import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/theme/admin_theme.dart';
import 'package:http/http.dart' as http;

class AddCompanyPage extends StatefulWidget {
  const AddCompanyPage({super.key});

  @override
  State<AddCompanyPage> createState() => _AddCompanyPageState();
}

class _AddCompanyPageState extends State<AddCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _adresse = TextEditingController();
  final _secteur = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/companies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': _name.text.trim(),
          'email': _email.text.trim(),
          'telephone': _phone.text.trim(),
          'adresse': _adresse.text.trim(),
          'secteurActivite': _secteur.text.trim(),
          'role': 'company',
        }),
      );
      setState(() => _loading = false);
      if (res.statusCode == 200 || res.statusCode == 201) {
        AdminTheme.snack(context, '✅ Entreprise ajoutée avec succès');
        Navigator.pop(context);
      } else {
        final data = jsonDecode(res.body);
        AdminTheme.snack(context, data['message'] ?? 'Erreur serveur', error: true);
      }
    } catch (e) {
      setState(() => _loading = false);
      AdminTheme.snack(context, 'Erreur réseau', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Ajouter une entreprise',
        subtitle: 'Créer un nouveau compte entreprise',
        showBack: true,
        context: context,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AdminTheme.headerGradient,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                  boxShadow: AdminTheme.elevatedShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                      ),
                      child: const Icon(Icons.business_outlined, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nouvelle entreprise', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Remplissez les informations ci-dessous', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTheme.cardBg,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                  boxShadow: AdminTheme.cardShadow,
                  border: Border.all(color: AdminTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminTheme.sectionLabel('Informations générales'),
                    const SizedBox(height: 12),
                    AdminTheme.formField(_name, 'Nom de l\'entreprise *', Icons.business_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
                    const SizedBox(height: 14),
                    AdminTheme.formField(_secteur, 'Secteur d\'activité *', Icons.category_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
                    const SizedBox(height: 24),
                    AdminTheme.sectionLabel('Contact'),
                    const SizedBox(height: 12),
                    AdminTheme.formField(_email, 'Email *', Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        }),
                    const SizedBox(height: 14),
                    AdminTheme.formField(_phone, 'Téléphone', Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    AdminTheme.formField(_adresse, 'Adresse', Icons.location_on_outlined),
                    const SizedBox(height: 28),
                    AdminTheme.primaryButton(
                      label: 'Créer le compte entreprise',
                      icon: Icons.add_business_outlined,
                      onPressed: _submit,
                      loading: _loading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
