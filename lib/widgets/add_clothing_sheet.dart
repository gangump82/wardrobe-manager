import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
  String? _base64Image;
  Uint8List? _imageBytes;
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
                  child: _imageBytes == null
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
                            if (kIsWeb)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Web 端将从相册选择',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
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
              
              if (_imageBytes != null && !_isProcessing) ...[
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
    // Web 端使用 gallery，原生平台可选择 camera 或 gallery
    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
    
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image != null) {
      // 读取图片数据
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      
      setState(() {
        _imagePath = image.path;
        _imageBytes = bytes;
        _base64Image = base64;
        _isProcessing = true;
      });
      
      // AI 识别
      Clothing? result;
      if (kIsWeb) {
        // Web 端使用 base64
        result = await context.read<WardrobeProvider>()
            .recognizeAndAddClothingFromBase64(base64);
      } else {
        // 原生平台使用文件路径
        result = await context.read<WardrobeProvider>()
            .recognizeAndAddClothing(image.path);
      }
      
      if (result != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('衣服已添加')),
        );
      }
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _saveClothing() {
    if (_imageBytes == null || _color.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }
    
    final clothing = Clothing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: _base64Image != null ? 'data:image/jpeg;base64,$_base64Image' : _imagePath!,
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
