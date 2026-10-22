import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../controllers/search_controller.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class CreateBubbleScreen extends ConsumerStatefulWidget {
  const CreateBubbleScreen({super.key});

  @override
  ConsumerState<CreateBubbleScreen> createState() => _CreateBubbleScreenState();
}

class _CreateBubbleScreenState extends ConsumerState<CreateBubbleScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'PUBLIC';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty || desc.isEmpty) {
      UiHelpers.showError(context, "Name and description are required.");
      return;
    }

    final formattedName = name.replaceAll(' ', '_').toLowerCase();
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(formattedName)) {
      UiHelpers.showError(context, "Bubble name can only contain lowercase letters, numbers, and underscores.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataSource = ref.read(searchDataSourceProvider);
      await dataSource.createBubble(
        name: formattedName,
        description: desc,
        type: _selectedType,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        UiHelpers.showSuccess(context, "Bubble created successfully!");
        ref.read(searchControllerProvider.notifier).executeSearch();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiHelpers.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const LiquidGlassAppBar(title: Text('Create a Bubble')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LiquidGlassTheme.primaryLiquidGradient(context: context),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIconsFill.circlesThree,
                  color: LiquidGlassTheme.primaryTextColor(context),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Form a New Community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LiquidGlassTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gather friends around shared passions and post updates within your own private or public orbit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: LiquidGlassTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 24),
            LiquidGlassContainer(
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bubble Name',
                      hintText: 'e.g. anime_lovers',
                      prefixIcon: Icon(PhosphorIconsRegular.circlesThree),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What is this bubble about?',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(PhosphorIconsRegular.textT),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 1),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Privacy Type',
                      prefixIcon: Icon(PhosphorIconsRegular.lockKey),
                      border: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PUBLIC',
                        child: Text('Public (Anyone can join)', style: TextStyle(fontSize: 14)),
                      ),
                      DropdownMenuItem(
                        value: 'PRIVATE',
                        child: Text('Private (Invitation only)', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            LiquidGlassButton(
              height: 50,
              label: 'Create Community',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handleCreate,
            ),
          ],
        ),
      ),
    );
  }
}

