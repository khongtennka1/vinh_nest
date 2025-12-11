// expense_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'dart:math' as math;

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> categories = [
    {
      "name": "Tất cả",
      "icon": Icons.list,
      "color": Colors.grey,
      "defaultType": "expense",
    },
    {
      "name": "Ăn uống",
      "icon": Icons.restaurant,
      "color": Colors.orange,
      "defaultType": "expense",
    },
    {
      "name": "Đi lại",
      "icon": Icons.directions_bike,
      "color": Colors.blue,
      "defaultType": "expense",
    },
    {
      "name": "Mua sắm",
      "icon": Icons.shopping_bag,
      "color": Colors.purple,
      "defaultType": "expense",
    },
    {
      "name": "Nhà trọ",
      "icon": Icons.home,
      "color": Colors.green,
      "defaultType": "expense",
    },
    {
      "name": "Giải trí",
      "icon": Icons.movie,
      "color": Colors.indigo,
      "defaultType": "expense",
    },
    {
      "name": "Khác",
      "icon": Icons.more_horiz,
      "color": Colors.grey,
      "defaultType": "expense",
    },
    {
      "name": "Lương",
      "icon": Icons.attach_money,
      "color": Colors.lightGreen,
      "defaultType": "income",
    },
  ];

  final List<Map<String, dynamic>> _transactions = [];

  int _filterCategoryIndex = 0;
  DateTimeRange? _filterDateRange;

  late TabController _mainTabController;

  int _chartTimeMode = 1;
  DateTime _chartMonth = DateTime.now();
  int _chartYear = DateTime.now().year;
  DateTimeRange? _chartCustomRange;

  final NumberFormat _fmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  void _sampleData() {
    _transactions.addAll([
      {
        'id': 1,
        'title': 'Ăn trưa',
        'amount': 600000.0,
        'time': DateTime.now().subtract(const Duration(days: 3)),
        'categoryIndex': 1,
        'type': 'expense',
      },
      {
        'id': 2,
        'title': 'Mua áo',
        'amount': 500000.0,
        'time': DateTime.now().subtract(const Duration(days: 7)),
        'categoryIndex': 3,
        'type': 'expense',
      },
      {
        'id': 3,
        'title': 'Lương tháng',
        'amount': 5000000.0,
        'time': DateTime.now().subtract(const Duration(days: 30)),
        'categoryIndex': categories.indexWhere((c) => c['name'] == 'Lương'),
        'type': 'income',
      },
    ]);
  }

  double get _totalIncome => _transactions
      .where((t) => t['type'] == 'income')
      .fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _totalExpense => _transactions
      .where((t) => t['type'] == 'expense')
      .fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _net => _totalIncome - _totalExpense;

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return "$day/$month/$year $hour:$minute";
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((t) {
      if (_filterCategoryIndex > 0 &&
          t['categoryIndex'] != _filterCategoryIndex)
        return false;
      if (_filterDateRange != null) {
        final time = (t['time'] as DateTime);
        if (time.isBefore(_filterDateRange!.start) ||
            time.isAfter(_filterDateRange!.end))
          return false;
      }
      return true;
    }).toList();
  }

  void _openCategoryManager() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> _editCategory({int? index}) async {
              final isEdit = index != null;
              final nameCtrl = TextEditingController(
                text: isEdit ? categories[index!]['name'] : '',
              );
              Color chosenColor = isEdit
                  ? categories[index!]['color'] as Color
                  : Colors.orange;
              IconData chosenIcon = isEdit
                  ? categories[index!]['icon'] as IconData
                  : Icons.category;
              String defaultType = isEdit
                  ? categories[index!]['defaultType'] as String
                  : 'expense';

              await showDialog(
                context: ctx,
                builder: (ctx2) {
                  return AlertDialog(
                    title: Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tên danh mục',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _colorChoice(
                                Colors.orange,
                                chosenColor,
                                (c) => chosenColor = c,
                                ctx2,
                              ),
                              _colorChoice(
                                Colors.blue,
                                chosenColor,
                                (c) => chosenColor = c,
                                ctx2,
                              ),
                              _colorChoice(
                                Colors.purple,
                                chosenColor,
                                (c) => chosenColor = c,
                                ctx2,
                              ),
                              _colorChoice(
                                Colors.green,
                                chosenColor,
                                (c) => chosenColor = c,
                                ctx2,
                              ),
                              _colorChoice(
                                Colors.indigo,
                                chosenColor,
                                (c) => chosenColor = c,
                                ctx2,
                              ),
                              _colorChoice(
                                Colors.grey,
                                chosenColor,
                                (c) => chosenColor = c,
                                ctx2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _iconChoice(
                                Icons.restaurant,
                                chosenIcon,
                                (ic) => chosenIcon = ic,
                                ctx2,
                              ),
                              _iconChoice(
                                Icons.directions_bike,
                                chosenIcon,
                                (ic) => chosenIcon = ic,
                                ctx2,
                              ),
                              _iconChoice(
                                Icons.shopping_bag,
                                chosenIcon,
                                (ic) => chosenIcon = ic,
                                ctx2,
                              ),
                              _iconChoice(
                                Icons.home,
                                chosenIcon,
                                (ic) => chosenIcon = ic,
                                ctx2,
                              ),
                              _iconChoice(
                                Icons.movie,
                                chosenIcon,
                                (ic) => chosenIcon = ic,
                                ctx2,
                              ),
                              _iconChoice(
                                Icons.attach_money,
                                chosenIcon,
                                (ic) => chosenIcon = ic,
                                ctx2,
                              ),
                              _iconChoice(
                                Icons.more_horiz,
                                chosenIcon,
                                (ic) => chosenIcon = ic,
                                ctx2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Mặc định:'),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Chi'),
                                selected: defaultType == 'expense',
                                onSelected: (v) {
                                  defaultType = 'expense';
                                },
                                selectedColor: Colors.red.shade100,
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Thu'),
                                selected: defaultType == 'income',
                                onSelected: (v) {
                                  defaultType = 'income';
                                },
                                selectedColor: Colors.green.shade100,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final nm = nameCtrl.text.trim();
                          if (nm.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tên danh mục không được để trống',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            if (isEdit) {
                              categories[index!] = {
                                'name': nm,
                                'icon': chosenIcon,
                                'color': chosenColor,
                                'defaultType': defaultType,
                              };
                            } else {
                              categories.add({
                                'name': nm,
                                'icon': chosenIcon,
                                'color': chosenColor,
                                'defaultType': defaultType,
                              });
                            }
                          });
                          Navigator.pop(ctx2);
                        },
                        child: const Text('Lưu'),
                      ),
                    ],
                  );
                },
              );
              setStateDialog(() {});
            }

            return AlertDialog(
              title: const Text('Quản lý danh mục'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, i) {
                          final c = categories[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (c['color'] as Color)
                                  .withOpacity(0.16),
                              child: Icon(
                                c['icon'] as IconData,
                                color: c['color'] as Color,
                              ),
                            ),
                            title: Text(c['name']),
                            subtitle: Text('Mặc định: ${c['defaultType']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editCategory(index: i),
                                  tooltip: 'Sửa',
                                ),
                                if (i != 0)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: ctx,
                                        builder: (cctx) {
                                          return AlertDialog(
                                            title: const Text('Xóa danh mục'),
                                            content: Text(
                                              'Bạn có chắc muốn xóa danh mục "${categories[i]['name']}"? Các giao dịch thuộc danh mục này sẽ được chuyển sang "Khác" nếu có, hoặc "Tất cả".',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(cctx),
                                                child: const Text('Hủy'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    final otherIdx = categories
                                                        .indexWhere(
                                                          (e) =>
                                                              e['name'] ==
                                                              'Khác',
                                                        );
                                                    final fallback =
                                                        otherIdx >= 0
                                                        ? otherIdx
                                                        : 0;
                                                    for (var t
                                                        in _transactions) {
                                                      if (t['categoryIndex'] ==
                                                          i) {
                                                        t['categoryIndex'] =
                                                            fallback;
                                                      } else if (t['categoryIndex'] >
                                                          i) {
                                                        t['categoryIndex'] =
                                                            (t['categoryIndex']
                                                                as int) -
                                                            1;
                                                      }
                                                    }
                                                    categories.removeAt(i);
                                                  });
                                                  Navigator.pop(cctx);
                                                  setStateDialog(() {});
                                                },
                                                child: const Text('Xóa'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _editCategory(index: null),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm danh mục mới'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _colorChoice(
    Color color,
    Color chosen,
    void Function(Color) onChoose,
    BuildContext ctx,
  ) {
    return GestureDetector(
      onTap: () {
        onChoose(color);
        Navigator.pop(ctx);
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: color,
        child: chosen == color
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _iconChoice(
    IconData icon,
    IconData chosen,
    void Function(IconData) onChoose,
    BuildContext ctx,
  ) {
    return GestureDetector(
      onTap: () {
        onChoose(icon);
        Navigator.pop(ctx);
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade200,
        child: Icon(
          icon,
          size: 16,
          color: chosen == icon ? Colors.black : Colors.grey.shade700,
        ),
      ),
    );
  }

  void _showTransactionDialog({
    Map<String, dynamic>? existing,
    int? existingIndex,
  }) {
    final isEdit = existing != null && existingIndex != null;
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final amountController = TextEditingController(
      text: existing != null ? _fmt.format(existing['amount']) : '',
    );

    int selectedCategory =
        existing?['categoryIndex'] ?? (categories.length > 1 ? 1 : 0);
    String selectedType =
        existing?['type'] ??
        (categories[selectedCategory]['defaultType'] as String? ?? 'expense');

    amountController.addListener(() {
      final text = amountController.text;
      final plain = _stripFormatting(text);
      if (plain.isEmpty) {
        if (text.isNotEmpty) {
          amountController.value = const TextEditingValue(
            text: '',
            selection: TextSelection.collapsed(offset: 0),
          );
        }
        return;
      }
      final formatted = _formatWithCommas(plain);
      if (formatted != text) {
        final selectionIndexFromRight =
            text.length - amountController.selection.end;
        amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: math.max(0, formatted.length - selectionIndexFromRight),
          ),
        );
      }
    });

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Chi'),
                          selected: selectedType == 'expense',
                          onSelected: (v) =>
                              setStateDialog(() => selectedType = 'expense'),
                          selectedColor: Colors.red.shade100,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Thu'),
                          selected: selectedType == 'income',
                          onSelected: (v) =>
                              setStateDialog(() => selectedType = 'income'),
                          selectedColor: Colors.green.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: "Danh mục"),
                      items: List.generate(categories.length, (i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Row(
                            children: [
                              Icon(
                                categories[i]['icon'] as IconData,
                                color: categories[i]['color'] as Color,
                              ),
                              const SizedBox(width: 8),
                              Text(categories[i]['name']),
                            ],
                          ),
                        );
                      }),
                      onChanged: (v) {
                        setStateDialog(() {
                          selectedCategory = v ?? 0;
                          selectedType =
                              categories[selectedCategory]['defaultType']
                                  as String? ??
                              selectedType;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Nội dung"),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: "Số tiền"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEdit)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _transactions.removeAt(existingIndex!);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa giao dịch')),
                      );
                    },
                    child: const Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final amountPlain = _stripFormatting(amountController.text);
                    final amount = double.tryParse(amountPlain) ?? 0.0;
                    if (title.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng nhập đầy đủ thông tin hợp lệ',
                          ),
                        ),
                      );
                      return;
                    }

                    final item = {
                      'id': isEdit
                          ? existing!['id']
                          : DateTime.now().millisecondsSinceEpoch,
                      'title': title,
                      'amount': amount,
                      'time': isEdit ? existing!['time'] : DateTime.now(),
                      'categoryIndex': selectedCategory,
                      'type': selectedType,
                    };

                    setState(() {
                      if (isEdit) {
                        _transactions[existingIndex!] = item;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã cập nhật giao dịch'),
                          ),
                        );
                      } else {
                        _transactions.insert(0, item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm giao dịch')),
                        );
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Lưu' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _stripFormatting(String s) => s.replaceAll(RegExp('[^0-9]'), '');

  String _formatWithCommas(String digits) {
    if (digits.isEmpty) return '';
    final n = int.tryParse(digits) ?? 0;
    return NumberFormat.decimalPattern('vi_VN').format(n);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      initialDateRange:
          _filterDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _filterDateRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
            0,
            0,
            0,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        );
      });
    }
  }

  List<Map<String, dynamic>> _transactionsForChart() {
    final base = _filteredTransactions;
    if (_chartTimeMode == 0) {
      return base;
    } else if (_chartTimeMode == 1) {
      return base.where((t) {
        final dt = t['time'] as DateTime;
        return dt.month == _chartMonth.month && dt.year == _chartMonth.year;
      }).toList();
    } else if (_chartTimeMode == 2) {
      return base.where((t) {
        final dt = t['time'] as DateTime;
        return dt.year == _chartYear;
      }).toList();
    } else {
      if (_chartCustomRange == null) return base;
      return base.where((t) {
        final dt = t['time'] as DateTime;
        return !dt.isBefore(_chartCustomRange!.start) &&
            !dt.isAfter(_chartCustomRange!.end);
      }).toList();
    }
  }

  Map<String, double> _categoryDistribution(
    List<Map<String, dynamic>> source, {
    String? type,
  }) {
    final Map<String, double> out = {};
    for (final t in source) {
      if (type != null && t['type'] != type) continue;
      final idx = t['categoryIndex'] as int;
      final name = categories[idx]['name'] as String;
      out[name] = (out[name] ?? 0.0) + (t['amount'] as double);
    }
    return out;
  }

  Widget _buildSinglePie(Map<String, double> dataMap, String title) {
    final entries = dataMap.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('Không có dữ liệu $title.')),
      );
    }
    final total = entries.fold<double>(0.0, (s, e) => s + e.value);
    int i = 0;
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: entries.map((e) {
                        final color =
                            categories[(i % (categories.length - 1)) +
                                    1]['color']
                                as Color;
                        final percent = (e.value / total) * 100;
                        final s = PieChartSectionData(
                          value: e.value,
                          title: '${percent.toStringAsFixed(0)}%',
                          color: color,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                        i++;
                        return s;
                      }).toList(),
                      sectionsSpace: 4,
                      centerSpaceRadius: 28,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    children: entries.map((e) {
                      final idx = categories.indexWhere(
                        (c) => c['name'] == e.key,
                      );
                      final color = idx >= 0
                          ? categories[idx]['color'] as Color
                          : Colors.grey;
                      final percent = total == 0
                          ? 0.0
                          : (e.value / total) * 100;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(
                            categories[idx >= 0 ? idx : 0]['icon'] as IconData,
                            size: 14,
                            color: color,
                          ),
                        ),
                        title: Text(e.key),
                        trailing: Text(
                          '${_fmt.format(e.value)} (${percent.toStringAsFixed(0)}%)',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickChartMonth() async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _chartMonth,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) {
      setState(() {
        _chartMonth = picked;
        _chartTimeMode = 1;
      });
    }
  }

  Future<void> _pickChartYear() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int temp = _chartYear;
        return AlertDialog(
          title: const Text('Chọn năm'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(DateTime.now().year - 50),
              lastDate: DateTime(DateTime.now().year + 50),
              selectedDate: DateTime(_chartYear),
              onChanged: (date) {
                temp = date.year;
                Navigator.of(ctx).pop(temp);
              },
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _chartYear = selected;
        _chartTimeMode = 2;
      });
    }
  }

  Future<void> _pickChartCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      initialDateRange:
          _chartCustomRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _chartCustomRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        );
        _chartTimeMode = 3;
      });
    }
  }

  String chartTimeLabel() {
    if (_chartTimeMode == 0) return 'Tất cả';
    if (_chartTimeMode == 1) return DateFormat('MM/yyyy').format(_chartMonth);
    if (_chartTimeMode == 2) return 'Năm $_chartYear';
    if (_chartTimeMode == 3 && _chartCustomRange != null) {
      final a = DateFormat('dd/MM/yyyy').format(_chartCustomRange!.start);
      final b = DateFormat('dd/MM/yyyy').format(_chartCustomRange!.end);
      return '$a → $b';
    }
    return 'Tùy chọn';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    final periodTransactions = _transactionsForChart();
    final incomePie = _categoryDistribution(
      periodTransactions.where((t) => t['type'] == 'income').toList(),
    );
    final expensePie = _categoryDistribution(
      periodTransactions.where((t) => t['type'] == 'expense').toList(),
    );

    final filteredIncome = filtered
        .where((t) => t['type'] == 'income')
        .toList();
    final filteredExpense = filtered
        .where((t) => t['type'] == 'expense')
        .toList();
    final incomeTotal = filteredIncome.fold<double>(
      0.0,
      (s, t) => s + (t['amount'] as double),
    );
    // ignore: unused_local_variable
    final expenseTotal = filteredExpense.fold<double>(
      0.0,
      (s, t) => s + (t['amount'] as double),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thu - chi'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _openCategoryManager,
            tooltip: 'Quản lý danh mục',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.filter_list),
                            SizedBox(width: 8),
                            Text('Bộ lọc'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(categories.length, (i) {
                            return ChoiceChip(
                              label: Text(categories[i]['name']),
                              selected: _filterCategoryIndex == i,
                              onSelected: (v) => setState(() {
                                _filterCategoryIndex = v ? i : 0;
                                Navigator.pop(context);
                              }),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _filterDateRange == null
                                  ? 'Tất cả thời gian'
                                  : '${_formatDateTime(_filterDateRange!.start)} → ${_formatDateTime(_filterDateRange!.end)}',
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _pickDateRange,
                              child: const Text('Chọn ngày'),
                            ),
                            TextButton(
                              onPressed: () {
                                _clearFilters();
                                Navigator.pop(context);
                              },
                              child: const Text('Xóa bộ lọc'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _openCategoryManager,
                          icon: const Icon(Icons.edit),
                          label: const Text('Quản lý danh mục'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Danh sách'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Biểu đồ'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showTransactionDialog(),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.shade50,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng thu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_fmt.format(_totalIncome)} VND',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng chi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_fmt.format(_totalExpense)} VND',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Còn lại',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_fmt.format(_net)} VND',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _net >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == 0) {
                      // ignore: unused_local_variable
                      final label = _filterDateRange == null
                          ? 'Tất cả ngày'
                          : '${_filterDateRange!.start.day}/${_filterDateRange!.start.month} → ${_filterDateRange!.end.day}/${_filterDateRange!.end.month}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.calendar_today, size: 16),
                              SizedBox(width: 6),
                              Text('Chọn ngày'),
                            ],
                          ),
                          onPressed: _pickDateRange,
                        ),
                      );
                    } else {
                      final i = idx - 1;
                      final cat = categories[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(cat['name']),
                          avatar: Icon(
                            cat['icon'] as IconData,
                            size: 18,
                            color: cat['color'] as Color,
                          ),
                          selected: _filterCategoryIndex == i,
                          onSelected: (v) =>
                              setState(() => _filterCategoryIndex = v ? i : 0),
                        ),
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Lịch sử giao dịch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_downward,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Thu nhập',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              '${_fmt.format(incomeTotal)} VND',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (filteredIncome.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Không có giao dịch thu nhập phù hợp.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredIncome.length,
                          itemBuilder: (context, idx) {
                            final t = filteredIncome[idx];
                            final cat = categories[t['categoryIndex'] as int];
                            final DateTime time = t['time'] as DateTime;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: (cat['color'] as Color)
                                      .withOpacity(0.12),
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: cat['color'] as Color,
                                  ),
                                ),
                                title: Text(
                                  t['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cat['name']} • ${_formatDateTime(time)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '+${_fmt.format(t['amount'])} VND',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                onTap: () {
                                  final origIndex = _transactions.indexWhere(
                                    (e) => e['id'] == t['id'],
                                  );
                                  if (origIndex != -1)
                                    _showTransactionDialog(
                                      existing: Map.from(
                                        _transactions[origIndex],
                                      ),
                                      existingIndex: origIndex,
                                    );
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: Colors.grey.shade50,
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_upward, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Chi tiêu',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                      if (filteredExpense.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Không có giao dịch chi tiêu phù hợp.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredExpense.length,
                          itemBuilder: (context, idx) {
                            final t = filteredExpense[idx];
                            final cat = categories[t['categoryIndex'] as int];
                            final DateTime time = t['time'] as DateTime;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: (cat['color'] as Color)
                                      .withOpacity(0.12),
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: cat['color'] as Color,
                                  ),
                                ),
                                title: Text(
                                  t['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cat['name']} • ${_formatDateTime(time)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '-${_fmt.format(t['amount'])} VND',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                onTap: () {
                                  final origIndex = _transactions.indexWhere(
                                    (e) => e['id'] == t['id'],
                                  );
                                  if (origIndex != -1)
                                    _showTransactionDialog(
                                      existing: Map.from(
                                        _transactions[origIndex],
                                      ),
                                      existingIndex: origIndex,
                                    );
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _chartTimeMode == 0,
                        onSelected: (v) => setState(() => _chartTimeMode = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Theo tháng'),
                        selected: _chartTimeMode == 1,
                        onSelected: (v) => v
                            ? _pickChartMonth()
                            : setState(() => _chartTimeMode = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Theo năm'),
                        selected: _chartTimeMode == 2,
                        onSelected: (v) => v
                            ? _pickChartYear()
                            : setState(() => _chartTimeMode = 2),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Tùy chọn'),
                        selected: _chartTimeMode == 3,
                        onSelected: (v) => v
                            ? _pickChartCustomRange()
                            : setState(() => _chartTimeMode = 3),
                      ),
                      const Spacer(),
                      Text(chartTimeLabel()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildSinglePie(incomePie, 'Phân bố Thu'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildSinglePie(expensePie, 'Phân bố Chi'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterCategoryIndex = 0;
      _filterDateRange = null;
    });
  }
}
