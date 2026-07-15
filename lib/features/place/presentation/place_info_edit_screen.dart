import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/place_category.dart';
import '../data/model/place_response.dart';
import '../data/repository/place_repository.dart';
import '../domain/place_provider.dart';

/// 장소 이름·카테고리 수정 화면. 좌표는 별도 화면(PlaceCoordinateEditScreen)에서.
class PlaceInfoEditScreen extends ConsumerStatefulWidget {
  final PlaceResponse place;
  const PlaceInfoEditScreen({super.key, required this.place});

  @override
  ConsumerState<PlaceInfoEditScreen> createState() =>
      _PlaceInfoEditScreenState();
}

class _PlaceInfoEditScreenState extends ConsumerState<PlaceInfoEditScreen> {
  static const _accentColor = Color(0xFF007AFF);
  static const _errorColor = Color(0xFFFF3B30);

  late TextEditingController _nameController;
  late PlaceCategory _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _category = widget.place.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return _nameController.text.trim() != widget.place.name ||
        _category != widget.place.category;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }
    if (_saving || !_isDirty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(placeRepositoryProvider)
          .updateInfo(widget.place.id, name, _category);
      ref.invalidate(allPlacesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: ${e.response?.statusCode ?? '네트워크 오류'}'),
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('정보 수정 — ${widget.place.name}'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '카테고리',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlaceCategory.values.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text('${cat.icon} ${cat.label}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: _accentColor.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: selected ? _accentColor : Colors.black26,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? _accentColor : const Color(0xFF1C1C1E),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                '이름',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '장소 이름',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _accentColor),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_saving || !_isDirty) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('저장',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
