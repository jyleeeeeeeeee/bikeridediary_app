import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/api_config.dart';
import '../data/model/bike_category.dart';
import '../data/model/bike_create_request.dart';
import '../data/model/manufacturer_model.dart';
import '../domain/bike_provider.dart';
import '../domain/manufacturer_provider.dart';

class BikeRegistrationScreen extends ConsumerStatefulWidget {
  const BikeRegistrationScreen({super.key});

  @override
  ConsumerState<BikeRegistrationScreen> createState() =>
      _BikeRegistrationScreenState();
}

class _BikeRegistrationScreenState
    extends ConsumerState<BikeRegistrationScreen> {
  int _currentStep = 0;
  static const _totalSteps = 3;

  // Step 1: 제조사
  String? _selectedManufacturer;
  final _customManufacturerController = TextEditingController();
  bool _isCustomManufacturer = false;

  // Step 2: 모델명
  final _modelController = TextEditingController();

  // Step 3: 상세 정보
  final _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final _mileageController = TextEditingController(text: '0');
  BikeCategory _selectedCategory = BikeCategory.NAKED;

  bool _isLoading = false;

  @override
  void dispose() {
    _customManufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildStepContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    context.pop();
                  }
                },
                icon: Icon(
                  _currentStep > 0 ? Icons.arrow_back : Icons.close,
                  color: const Color(0xFF1B2838),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_totalSteps, (index) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(
                      right: index < _totalSteps - 1 ? 6 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? const Color(0xFF1B9CFC)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildManufacturerStep();
      case 1:
        return _buildModelStep();
      case 2:
        return _buildDetailStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: 제조사 선택 (서버 API 연동) ──

  Widget _buildManufacturerStep() {
    final manufacturersAsync = ref.watch(manufacturerListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '어떤 바이크를 타고 계신가요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2838),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '모터사이클 제조사',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: manufacturersAsync.when(
            data: (manufacturers) => _buildManufacturerGrid(manufacturers),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  Text('제조사 목록을 불러올 수 없습니다',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.invalidate(manufacturerListProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManufacturerGrid(List<ManufacturerModel> manufacturers) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: manufacturers.length + 1,
      itemBuilder: (context, index) {
        if (index == manufacturers.length) {
          return _buildCustomInputTile();
        }
        final mfr = manufacturers[index];
        final isSelected =
            _selectedManufacturer == mfr.displayNameKo &&
            !_isCustomManufacturer;
        return _buildManufacturerTile(
          mfr: mfr,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedManufacturer = mfr.displayNameKo;
              _isCustomManufacturer = false;
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _currentStep = 1);
            });
          },
        );
      },
    );
  }

  Widget _buildManufacturerTile({
    required ManufacturerModel mfr,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final logoFullUrl = mfr.logoUrl != null
        ? '${ApiConfig.baseUrl}${mfr.logoUrl}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F4FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B9CFC)
                : const Color(0xFFF0F0F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지
            SizedBox(
              width: 44,
              height: 44,
              child: logoFullUrl != null
                  ? Image.network(
                      logoFullUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          _buildInitialAvatar(mfr.displayNameKo),
                    )
                  : _buildInitialAvatar(mfr.displayNameKo),
            ),
            const SizedBox(height: 6),
            // 제조사 한글명
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                mfr.displayNameKo,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1B9CFC)
                      : const Color(0xFF3A3A3A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.substring(0, 1),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomInputTile() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCustomManufacturer = true;
          _selectedManufacturer = null;
        });
        _showCustomManufacturerDialog();
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              _isCustomManufacturer ? const Color(0xFFE8F4FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCustomManufacturer
                ? const Color(0xFF1B9CFC)
                : const Color(0xFFF0F0F0),
            width: _isCustomManufacturer ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit, size: 22, color: Color(0xFF6B7280)),
            const SizedBox(height: 6),
            Text(
              '직접 입력',
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    _isCustomManufacturer ? FontWeight.w600 : FontWeight.w500,
                color: _isCustomManufacturer
                    ? const Color(0xFF1B9CFC)
                    : const Color(0xFF3A3A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomManufacturerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('제조사 직접 입력'),
        content: TextField(
          controller: _customManufacturerController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '제조사명을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isCustomManufacturer = false);
              Navigator.pop(ctx);
            },
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final value = _customManufacturerController.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  _selectedManufacturer = value;
                  _isCustomManufacturer = true;
                });
                Navigator.pop(ctx);
                setState(() => _currentStep = 1);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ── Step 2: 모델명 입력 ──

  Widget _buildModelStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '차종은 무엇인가요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2838),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedManufacturer ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _modelController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '모델명을 입력하세요 (예: CBR650R)',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onSubmitted: (_) => _goToDetailStep(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _modelController.text.trim().isEmpty
                  ? null
                  : _goToDetailStep,
              child: const Text('다음'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '추후 제조사별 모델 목록이 제공될 예정입니다',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _goToDetailStep() {
    if (_modelController.text.trim().isNotEmpty) {
      setState(() => _currentStep = 2);
    }
  }

  // ── Step 3: 상세 정보 ──

  Widget _buildDetailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '바이크 정보를 알려주세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2838),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedManufacturer ?? ''} ${_modelController.text}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 28),

          const _SectionLabel(text: '연식'),
          const SizedBox(height: 8),
          TextField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '2024',
              suffixText: '년',
            ),
          ),
          const SizedBox(height: 20),

          const _SectionLabel(text: '카테고리'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BikeCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat.displayName),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = cat),
                selectedColor:
                    const Color(0xFF1B9CFC).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1B9CFC)
                      : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1B9CFC)
                      : const Color(0xFFE5E7EB),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const _SectionLabel(text: '현재 주행거리'),
          const SizedBox(height: 8),
          TextField(
            controller: _mileageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: 'km',
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('등록 완료'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final year = int.tryParse(_yearController.text);
    final mileage = int.tryParse(_mileageController.text);

    if (year == null || year < 1900 || year > 2100) {
      _showError('올바른 연식을 입력하세요');
      return;
    }
    if (mileage == null || mileage < 0) {
      _showError('올바른 주행거리를 입력하세요');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(bikeListProvider.notifier).create(
            BikeCreateRequest(
              manufacturerName:
                  _selectedManufacturer ?? _customManufacturerController.text,
              modelName: _modelController.text.trim(),
              year: year,
              category: _selectedCategory.name,
              totalMileageKm: mileage,
            ),
          );
      if (mounted) context.pop();
    } catch (e) {
      _showError('오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}
