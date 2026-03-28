import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/wardrobe_provider.dart';

class AddClothingSheet extends StatefulWidget {
  const AddClothingSheet({super.key});

  @override
  State<AddClothingSheet> createState() => _AddClothingSheetState();
}

class _AddClothingSheetState extends State<AddClothingSheet> {
  final ImagePicker _picker = ImagePicker();
  
  String? _imagePath;
  bool _isProcessing = false;
  
  // AI 识别结果
  String _category = ClothingCategory.tops;
  String _subCategory = 't_shirt';
  String _color = '';
  List<String> _styles = [];
  List<String> _seasons = [];
  String _locationStatus = LocationStatus.inWardrobe;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '添加衣服',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 拍照/选择区域
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: _imagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '点击拍照或选择照片',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          )
                        : const Icon(
                            Icons.checkroom,
                            size: 64,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (_isProcessing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('AI 正在识别...'),
                    ],
                  ),
                ),
              
              if (_imagePath != null && !_isProcessing) ...[
                // 快速选择类型
                const Text('类型', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClothingCategory.names.entries.map((e) {
                    final isSelected = _category == e.key;
                    return FilterChip(
                      label: Text('${ClothingCategory.icons[e.key]} ${e.value}'),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _category = e.key;
                        });
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // 颜色输入
                TextField(
                  decoration: const InputDecoration(
                    labelText: '颜色',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _color = value,
                  controller: TextEditingController(text: _color),
                ),
                
                const SizedBox(height: 16),
                
                // 位置选择
                const Text('位置', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: LocationStatus.names.entries.map((e) {
                    final isSelected = _locationStatus == e.key;
                    return FilterChip(
                      label: Text('${LocationStatus.icons[e.key]} ${e.value}'),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _locationStatus = e.key;
                        });
                      },
                    );
                  }).toList(),
                ),
                
                const Spacer(),
                
                // 保存按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveClothing,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _isProcessing = true;
      });
      
      // AI 识别
      final result = await context.read<WardrobeProvider>()
          .recognizeAndAddClothing(image.path);
      
      if (result != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('衣服已添加')),
        );
      }
      
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _saveClothing() {
    if (_imagePath == null || _color.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }
    
    final clothing = Clothing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: _imagePath!,
      category: _category,
      subCategory: _subCategory,
      color: _color,
      styles: _styles,
      seasons: _seasons,
      locationStatus: _locationStatus,
      createdAt: DateTime.now(),
    );
    
    context.read<WardrobeProvider>().addClothing(clothing);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('衣服已添加 +10 积分')),
    );
  }
}

class QuickAddButton extends StatelessWidget {
  const QuickAddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const AddClothingSheet(),
        );
      },
      icon: const Icon(Icons.add_a_photo),
      label: const Text('添加衣服'),
    );
  }
}
