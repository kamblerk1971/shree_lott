// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hive_flutter/adapters.dart';
// import 'package:printing/printing.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:shreelott/screens/splash_screen.dart';
// import 'package:shreelott/widgets/show_logout_dialog.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Shree Lott',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arial'),
//       home: const LotteryScreen(),
//     );
//   }
// }
//
// class LotteryScreen extends StatefulWidget {
//   const LotteryScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LotteryScreen> createState() => _LotteryScreenState();
// }
//
// class _LotteryScreenState extends State<LotteryScreen> {
//   String selectedRange = '0900-0999';
//   Map<String, int> selectedNumbers = {};
//   Map<String, TextEditingController> controllers = {};
//   bool showHigh = true;
//   bool showEven = true;
//   bool fpEnabled = false;
//   Map<String, bool> seriesFilters = {
//     'All': false,
//     '0000-0099': true,
//     '1000-1099': false,
//     '2000-2099': false,
//     '3000-3099': false,
//     '4000-4099': false,
//     '5000-5099': false,
//     '6000-6099': false,
//     '7000-7099': false,
//     '8000-8099': false,
//     '9000-9099': false,
//   };
//
//   int get totalQuantity =>
//       selectedNumbers.values.fold(0, (sum, qty) => sum + qty);
//
//   int get totalAmount => totalQuantity * 2;
//
//   @override
//   void dispose() {
//     controllers.values.forEach((c) => c.dispose());
//     super.dispose();
//   }
//
//   TextEditingController _getController(String number) {
//     if (!controllers.containsKey(number)) {
//       controllers[number] = TextEditingController();
//     }
//     return controllers[number]!;
//   }
//
//   void _updateQuantity(String number, String value) {
//     setState(() {
//       final qty = int.tryParse(value) ?? 0;
//       if (qty > 0) {
//         selectedNumbers[number] = qty;
//       } else {
//         selectedNumbers.remove(number);
//         controllers[number]?.clear();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return Column(
//             children: [
//               _buildHeader(constraints),
//               _buildMenuBar(constraints),
//               _buildInfoBar(constraints),
//               _buildFilterBar(constraints),
//               _buildTabBar(constraints),
//               Expanded(child: _buildNumberGrid(constraints)),
//               _buildFooter(constraints),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildHeader(BoxConstraints constraints) {
//     return Container(
//       width: constraints.maxWidth,
//       color: const Color(0xFF1A4D7C),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       child: Row(
//         children: [
//           const Text(
//             'Shree ',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const Text(
//             'Lott',
//             style: TextStyle(
//               color: Colors.red,
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(width: 20),
//           Expanded(
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   _buildHeaderNumber('10:30 AM', const Color(0xFFCC9999)),
//                   _buildHeaderNumber('0093', const Color(0xFF4CAF50)),
//                   _buildHeaderNumber('0139', const Color(0xFF64B5F6)),
//                   _buildHeaderNumber('0256', const Color(0xFF7A9E7E)),
//                   _buildHeaderNumber('0329', const Color(0xFFCC99CC)),
//                   _buildHeaderNumber('0487', const Color(0xFF999999)),
//                   _buildHeaderNumber('0514', const Color(0xFFAA8866)),
//                   _buildHeaderNumber('0627', const Color(0xFF66BB66)),
//                   _buildHeaderNumber('0798', const Color(0xFFAA8866)),
//                   _buildHeaderNumber('0818', const Color(0xFF5DADE2)),
//                   _buildHeaderNumber('0936', const Color(0xFFEE9999)),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeaderNumber(String text, Color color) {
//     return Container(
//       margin: const EdgeInsets.only(left: 3),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//           fontSize: 14,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMenuBar(BoxConstraints constraints) {
//     return SizedBox(
//       width: constraints.maxWidth,
//       child: Row(
//         children: [
//           _buildMenuItem('Refresh'),
//           _buildMenuItem('Accounts'),
//           _buildMenuItem('Passwords'),
//           _buildMenuItem('Report'),
//           _buildMenuItem('Support'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMenuItem(String title) {
//     return Expanded(
//       child: InkWell(
//         onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('$title clicked'),
//             duration: const Duration(seconds: 1),
//           ),
//         ),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: Colors.grey.shade400, width: 0.5),
//           ),
//           child: Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//               color: Colors.black,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoBar(BoxConstraints constraints) {
//     return Container(
//       width: constraints.maxWidth,
//       color: const Color(0xFFFFF59D),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _buildInfoItem('TIME TO DRAW', '8:04'),
//           _buildInfoItem('DRAW TIME', '10:45 am'),
//           _buildInfoItem('DRAW DATE', '30/12/2025'),
//           _buildInfoItem('LIMIT UPDATE', '5094'),
//           _buildInfoItem('TERMINAL ID', 'SL71940467'),
//           _buildInfoItem('LAST TRANSACTION AMOUNT', '2'),
//           GestureDetector(
//             onTap: () async {
//               final bool shouldLogout = await showLogoutDialog(context);
//               if (!shouldLogout) return;
//
//               // 1️⃣ Clear Hive data
//               final box = Hive.box('app');
//               await box.clear();
//
//               if (!context.mounted) return;
//
//               // 2️⃣ Navigate using ROOT navigator
//               Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//                 MaterialPageRoute(builder: (_) => const SplashScreen()),
//                 (route) => false,
//               );
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: const Text(
//                 'CLOSE',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoItem(String label, String value) {
//     return Flexible(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterBar(BoxConstraints constraints) {
//     return Container(
//       width: constraints.maxWidth,
//       color: const Color(0xFF81C784),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             const Text(
//               'Series',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//             ),
//             const SizedBox(width: 12),
//             ...seriesFilters.entries.map(
//               (e) => _buildCheckbox(
//                 e.key,
//                 e.value,
//                 e.key == '0000-0099'
//                     ? Colors.blue
//                     : (e.key == '3000-3099' ? Colors.orange : Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCheckbox(String label, bool checked, Color bgColor) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: InkWell(
//         onTap: () {
//           setState(() {
//             if (label == 'All') {
//               seriesFilters.updateAll(
//                 (key, value) => key == 'All' ? !checked : false,
//               );
//             } else {
//               seriesFilters[label] = !checked;
//               seriesFilters['All'] = false;
//             }
//           });
//         },
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 16,
//               height: 16,
//               decoration: BoxDecoration(
//                 color: bgColor,
//                 border: Border.all(color: Colors.black, width: 1),
//               ),
//               child: checked
//                   ? const Icon(Icons.check, size: 12, color: Colors.white)
//                   : null,
//             ),
//             const SizedBox(width: 4),
//             Text(
//               label,
//               style: const TextStyle(fontSize: 12, color: Colors.black),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTabBar(BoxConstraints constraints) {
//     return Container(
//       width: constraints.maxWidth,
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             const SizedBox(width: 8),
//             _buildTab('High', showHigh, () => setState(() => showHigh = true)),
//             _buildTab('Low', !showHigh, () => setState(() => showHigh = false)),
//             const SizedBox(width: 24),
//             _buildTextButton(
//               'Even',
//               showEven,
//               () => setState(() => showEven = true),
//             ),
//             const SizedBox(width: 16),
//             _buildTextButton(
//               'Odd',
//               !showEven,
//               () => setState(() => showEven = false),
//             ),
//             const SizedBox(width: 24),
//             Checkbox(
//               value: fpEnabled,
//               onChanged: (v) => setState(() => fpEnabled = v ?? false),
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             const Text('FP', style: TextStyle(fontSize: 12)),
//             const SizedBox(width: 16),
//             // TextButton(
//             //   onPressed: _showResults,
//             //   style: TextButton.styleFrom(backgroundColor: Colors.blue,
//             //       padding: const EdgeInsets.symmetric(
//             //           horizontal: 12, vertical: 8)),
//             //   child: const Text('Show Result',
//             //       style: TextStyle(color: Colors.white, fontSize: 12)),
//             // ),
//             const SizedBox(width: 8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: 80,
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           color: isActive ? Colors.blue : const Color(0xFFADD8E6),
//           border: Border.all(color: Colors.black, width: 1),
//         ),
//         child: Text(
//           label,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//             color: isActive ? Colors.white : Colors.black,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextButton(String label, bool isActive, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.black, width: 1.5),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 13,
//             color: isActive ? Colors.black : Colors.grey,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNumberGrid(BoxConstraints constraints) {
//     final sidebarWidth = constraints.maxWidth * 0.25;
//     final amountWidth = constraints.maxWidth * 0.18;
//     final gridWidth = constraints.maxWidth - sidebarWidth - amountWidth;
//
//     return Row(
//       children: [
//         _buildSidebar(sidebarWidth),
//         _buildMainGrid(gridWidth),
//         _buildAmountColumn(amountWidth),
//       ],
//     );
//   }
//
//   Widget _buildSidebar(double width) {
//     final ranges = [
//       {'range': '0000-0099', 'color': const Color(0xFFEE9999), 'points': ''},
//       {
//         'range': '0100-0199',
//         'color': const Color(0xFF81C784),
//         'points': 'Points',
//       },
//       {
//         'range': '0200-0299',
//         'color': const Color(0xFF64B5F6),
//         'points': '2.00',
//       },
//       {'range': '0300-0399', 'color': const Color(0xFF81C784), 'points': ''},
//       {
//         'range': '0400-0499',
//         'color': const Color(0xFFEE9999),
//         'points': '10.00',
//       },
//       {
//         'range': '0500-0599',
//         'color': const Color(0xFFCE93D8),
//         'points': '20.00',
//       },
//       {
//         'range': '0600-0699',
//         'color': const Color(0xFFFFAB91),
//         'points': '40.00',
//       },
//       {'range': '0700-0799', 'color': const Color(0xFFDCE775), 'points': ''},
//       {'range': '0800-0899', 'color': const Color(0xFFE1BEE7), 'points': ''},
//       {'range': '0900-0999', 'color': const Color(0xFF80DEEA), 'points': ''},
//     ];
//
//     return SizedBox(
//       width: width,
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade300, width: 0.5),
//             ),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildSideButton('Page Up'),
//                   const SizedBox(width: 4),
//                   _buildSideButton('Page Down'),
//                   const SizedBox(width: 8),
//                   Checkbox(
//                     value: false,
//                     onChanged: (v) {},
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   ),
//                   const Text('All', style: TextStyle(fontSize: 11)),
//                   const SizedBox(width: 4),
//                   _buildBlockButton(),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               children: ranges
//                   .map(
//                     (r) => _buildRangeRow(
//                       r['range'] as String,
//                       r['color'] as Color,
//                       r['points'] as String,
//                       r['range'] == selectedRange,
//                       width,
//                     ),
//                   )
//                   .toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSideButton(String text) {
//     return InkWell(
//       onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('$text clicked'),
//           duration: const Duration(seconds: 1),
//         ),
//       ),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(3),
//           border: Border.all(color: Colors.grey.shade400, width: 0.5),
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBlockButton() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: const Color(0xFF37474F),
//         borderRadius: BorderRadius.circular(3),
//       ),
//       child: const Text(
//         'Block',
//         style: TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRangeRow(
//     String range,
//     Color color,
//     String points,
//     bool isSelected,
//     double width,
//   ) {
//     return InkWell(
//       onTap: () => setState(() => selectedRange = range),
//       child: Container(
//         height: 45,
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade400, width: 0.5),
//         ),
//         child: Row(
//           children: [
//             SizedBox(
//               width: width * 0.35,
//               child: Center(
//                 child: Text(
//                   range,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 11,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: width * 0.12,
//               child: Checkbox(
//                 value: isSelected,
//                 onChanged: (v) => setState(() => selectedRange = range),
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               ),
//             ),
//             Container(
//               width: width * 0.28,
//               color: color,
//               child: const Center(
//                 child: Text(
//                   '(Rs.2)',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 color: points == '2.00' && isSelected
//                     ? const Color(0xFFADD8E6)
//                     : (points.isEmpty ? const Color(0xFFE0E0E0) : Colors.white),
//                 child: Center(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       if (points == '2.00' ||
//                           points == '10.00' ||
//                           points == '20.00' ||
//                           points == '40.00')
//                         Container(
//                           width: 10,
//                           height: 10,
//                           margin: const EdgeInsets.only(right: 3),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: points == '2.00' && isSelected
//                                 ? Colors.blue
//                                 : Colors.white,
//                             border: Border.all(color: Colors.black, width: 1),
//                           ),
//                         ),
//                       Text(
//                         points,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 11,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMainGrid(double width) {
//     return SizedBox(
//       width: width,
//       child: Column(
//         children: [
//           Container(
//             height: 35,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade400, width: 0.5),
//             ),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   _buildGridHeaderCell('Block', width / 11),
//                   ...List.generate(
//                     10,
//                     (i) => _buildGridHeaderCell('', width / 11),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Column(
//                   children: List.generate(
//                     10,
//                     (row) => _buildNumberRow(row, width / 11),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGridHeaderCell(String text, double width) {
//     return Container(
//       width: width,
//       height: 35,
//       decoration: BoxDecoration(
//         color: const Color(0xFF37474F),
//         border: Border.all(color: Colors.black, width: 0.5),
//       ),
//       child: Center(
//         child: Text(
//           text,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNumberRow(int row, double cellWidth) {
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300, width: 0.5),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: cellWidth,
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFF37474F),
//               border: Border.all(color: Colors.black, width: 0.5),
//             ),
//           ),
//           ...List.generate(10, (col) {
//             final number = '09${row}${col}';
//             return _buildNumberCell(number, cellWidth);
//           }),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNumberCell(String number, double width) {
//     final isSelected = selectedNumbers.containsKey(number);
//     return InkWell(
//       onTap: () => _showQuantityDialog(number),
//       onLongPress: () {
//         setState(() {
//           selectedNumbers.remove(number);
//           controllers[number]?.clear();
//         });
//       },
//       child: Container(
//         width: width,
//         height: 40,
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.yellow.shade200 : Colors.white,
//           border: Border.all(color: Colors.grey.shade400, width: 0.5),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 number,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 11,
//                   color: Colors.black,
//                 ),
//               ),
//               if (isSelected)
//                 Text(
//                   'Q:${selectedNumbers[number]}',
//                   style: const TextStyle(
//                     fontSize: 9,
//                     color: Colors.red,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showQuantityDialog(String number) {
//     final controller = _getController(number);
//     controller.text = selectedNumbers[number]?.toString() ?? '';
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Enter Quantity for $number',
//           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//         ),
//         content: SizedBox(
//           width: 250,
//           child: TextField(
//             controller: controller,
//             keyboardType: TextInputType.number,
//             inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//             decoration: const InputDecoration(
//               labelText: 'Quantity',
//               border: OutlineInputBorder(),
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 12,
//               ),
//               labelStyle: TextStyle(fontSize: 13),
//             ),
//             style: const TextStyle(fontSize: 14),
//             autofocus: true,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel', style: TextStyle(fontSize: 12)),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _updateQuantity(number, controller.text);
//               Navigator.pop(context);
//             },
//             child: const Text('OK', style: TextStyle(fontSize: 12)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAmountColumn(double width) {
//     return SizedBox(
//       width: width,
//       child: Column(
//         children: [
//           Container(
//             height: 35,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade400, width: 0.5),
//             ),
//             child: Row(
//               children: [
//                 _buildAmountHeader('Qty', width / 2),
//                 _buildAmountHeader('Amount', width / 2),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               children: List.generate(10, (i) {
//                 final rowNumbers = List.generate(10, (col) => '09${i}${col}');
//                 final rowQty = rowNumbers.fold<int>(
//                   0,
//                   (sum, num) => sum + (selectedNumbers[num] ?? 0),
//                 );
//                 final rowAmount = rowQty * 2;
//                 return _buildAmountRow(
//                   rowQty.toString(),
//                   rowAmount.toString(),
//                   width / 2,
//                 );
//               }),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade200,
//               border: Border.all(color: Colors.grey.shade400, width: 0.5),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: const [
//                     Text(
//                       'Qty',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 11,
//                       ),
//                     ),
//                     Text(
//                       'Amount',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       totalQuantity.toString(),
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                     Text(
//                       'Rs.$totalAmount',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                         color: Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAmountHeader(String text, double width) {
//     return Container(
//       width: width,
//       height: 35,
//       decoration: BoxDecoration(
//         color: const Color(0xFF37474F),
//         border: Border.all(color: Colors.black, width: 0.5),
//       ),
//       child: Center(
//         child: Text(
//           text,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAmountRow(String qty, String amount, double cellWidth) {
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300, width: 0.5),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: .horizontal,
//         child: Row(
//           children: [
//             Container(
//               width: cellWidth,
//               color: const Color(0xFF37474F),
//               child: Center(
//                 child: Text(
//                   qty,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 11,
//                   ),
//                 ),
//               ),
//             ),
//             Container(
//               width: cellWidth,
//               color: const Color(0xFFFFB74D),
//               child: Center(
//                 child: Text(
//                   amount,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 11,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFooter(BoxConstraints constraints) {
//     return Container(
//       width: constraints.maxWidth,
//       color: Colors.grey.shade200,
//       padding: const EdgeInsets.all(8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             _buildFooterButton(
//               'F6 Print',
//               const Color(0xFFFFF59D),
//               _handlePrint,
//             ),
//             const SizedBox(width: 8),
//             _buildFooterButton(
//               'F7 Clear',
//               const Color(0xFFEF9A9A),
//               _handleClear,
//             ),
//             const SizedBox(width: 16),
//             _buildFooterButton('Claim', const Color(0xFFFFD54F), _handleClaim),
//             const SizedBox(width: 8),
//             _buildFooterButton(
//               'Cancle',
//               const Color(0xFFFFD54F),
//               _handleCancel,
//             ),
//             const SizedBox(width: 8),
//             _buildFooterButton(
//               'Transaction',
//               const Color(0xFFCE93D8),
//               _handleTransaction,
//             ),
//             const SizedBox(width: 8),
//             _buildFooterButton(
//               'Advanced Draw',
//               const Color(0xFFFFF59D),
//               _handleAdvancedDraw,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFooterButton(String text, Color color, VoidCallback onPressed) {
//     return InkWell(
//       onTap: onPressed,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: color,
//           border: Border.all(color: Colors.black, width: 1),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//             color: Colors.black,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _handlePrint() async {
//     if (selectedNumbers.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No numbers selected to print'),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return;
//     }
//
//     // ✅ GRACEFUL HIVE HANDLING
//     final box = Hive.isBoxOpen('printerBox')
//         ? Hive.box('printerBox')
//         : await Hive.openBox('printerBox');
//
//     Printer? targetPrinter;
//
//     final savedPrinterName = box.get('printer_name');
//
//     if (savedPrinterName != null) {
//       final printers = await Printing.listPrinters();
//       for (final p in printers) {
//         if (p.name == savedPrinterName) {
//           targetPrinter = p;
//           break;
//         }
//       }
//     }
//
//     if (targetPrinter == null) {
//       final picked = await Printing.pickPrinter(context: context);
//       if (picked == null) return;
//
//       await box.put('printer_name', picked.name);
//       targetPrinter = picked;
//     }
//
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(24),
//         build: (_) => [
//           pw.Text('''
// The Cat
//
// The cat is a small carnivorous mammal kept as a pet.
// Cats are independent, agile, and intelligent animals.
// They sleep for long hours and hunt with precision.
// Cats bring calm and companionship to humans.
// ''', style: pw.TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//
//     await Printing.directPrintPdf(
//       printer: targetPrinter,
//       onLayout: (_) async => pdf.save(),
//     );
//   }
//
//   void _handleClear() {
//     setState(() {
//       selectedNumbers.clear();
//       controllers.values.forEach((c) => c.clear());
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('All selections cleared'),
//         duration: Duration(seconds: 1),
//       ),
//     );
//   }
//
//   void _handleClaim() => ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text('Claim function activated'),
//       duration: Duration(seconds: 1),
//     ),
//   );
//
//   void _handleCancel() => ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text('Transaction cancelled'),
//       duration: Duration(seconds: 1),
//     ),
//   );
//
//   void _handleTransaction() => ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text('Transaction history opened'),
//       duration: Duration(seconds: 1),
//     ),
//   );
//
//   void _handleAdvancedDraw() => ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text('Advanced draw options opened'),
//       duration: Duration(seconds: 1),
//     ),
//   );
// }
//
//

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shreelott/controller/index_controller.dart';
import 'package:shreelott/models/shop_report_model.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';
import 'package:shreelott/screens/login_screen.dart';
import 'package:shreelott/screens/splash_screen.dart';
import 'package:shreelott/widgets/show_loading_overlay.dart';
import '../consts/app_colors.dart';
import '../controller/home_controller.dart';
import '../controller/refresh_controller.dart';
import '../controller/wallet_controller.dart';
import '../widgets/btn_press_effect.dart';
import '../widgets/info_bar_widget.dart';
import '../widgets/shop_report_dialog.dart';
import '../widgets/showUserSummaryDialog.dart';
import '../widgets/show_change_password_dialog.dart';
import '../widgets/show_logout_dialog.dart';
import '../widgets/show_menu_options.dart';
import '../widgets/show_refresh_dialog.dart';
import '../widgets/show_support_dialog.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  final Box _box = Hive.box('app');

  final Set<String> selectedSeries = {"All"};
  String activeFilter = "ALL";

  final headerColors = [
    0xFF3FA16B,
    0xFF7EC0FF,
    0xFF6E7F6A,
    0xFFC17D8D,
    0xFFA9A3B8,
    0xFFB8876F,
    0xFF8FAE7E,
    0xFFB28787,
    0xFF56A0A0,
    0xFFE6A29B,
  ];

  TimerModel? timer;
  DrawTimeModel? drawTime;
  TerminalModel? terminal;
  LastTransactionModel1? lastTransaction;
  WalletBalance? walletBalance;
  List<ResultModel>? initResults;

  bool isLoading = true;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  final Map<String, TextEditingController> _amountControllers = {};
  double totalAmount = 0;

  final FocusNode _keyboardFocus = FocusNode();
  final WalletController walletController = Get.find<WalletController>();

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
    _loadHomeData();

    /// Listen using ever
    ever(refreshController.isRefreshing, (value) {
      if (value == true) {
        _loadHomeData();
      }
    });
  }

  BettingGridController bettingGridController = BettingGridController();
  HomeController homeController = HomeController();
  final RefreshController refreshController = Get.put(RefreshController());

  bool _handleKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;

    if (e.logicalKey == LogicalKeyboardKey.f5) {
      debugPrint("F5 Pressed → Refresh In Home Screen");
      _loadHomeData();
    }

    return false;
  }

  Timer? _autoRefreshTimer;

  // ================= LOAD HOME DATA =================
  bool _isWithinWorkingHours() {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, now.day, 9, 0);
    final end = DateTime(now.year, now.month, now.day, 23, 0);

    return !now.isBefore(start) && !now.isAfter(end);
  }

  Future<void> _loadHomeData() async {
    refreshController.refreshScreen();
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        _controller.getTimer().catchError((_) => null),
        _controller.getDrawTime().catchError((_) => null),
        _controller.getTerminalId().catchError((_) => null),
        _controller.getLastTransaction().catchError((_) => null),
        _controller.getWalletBalance().catchError((_) => null),
        _controller.getInitResults().catchError((_) => null),
      ]);

      if (!mounted) return;

      timer = results[0] as TimerModel?;
      drawTime = results[1] as DrawTimeModel?;
      terminal = results[2] as TerminalModel?;
      lastTransaction = results[3] as LastTransactionModel1?;
      walletBalance = results[4] as WalletBalance?;
      initResults = results[5] as List<ResultModel>?;

      _remainingSeconds = timer?.remainingTime.totalSeconds ?? 0;

      if (_remainingSeconds > 0 && _isWithinWorkingHours()) {
        _startCountdown();
      }

      final double balance =
          double.tryParse(walletBalance?.amount ?? "0") ?? 0.0;

      walletController.setBalance(balance);

      // Auto refresh only during working hours
      if (_isWithinWorkingHours() && _isAnyDataMissing()) {
        _startAutoRefresh();
      } else {
        _autoRefreshTimer?.cancel();
      }
    } catch (e) {
      debugPrint("_loadHomeData error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _isAnyDataMissing() {
    return timer == null ||
        drawTime == null ||
        terminal == null ||
        lastTransaction == null ||
        walletBalance == null ||
        initResults == null ||
        initResults!.isEmpty;
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();

    if (!_isWithinWorkingHours()) return;

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (
      refreshTimer,
    ) async {
      if (!mounted) return;

      if (!_isWithinWorkingHours()) {
        refreshTimer.cancel();
        return;
      }

      try {
        timer ??= await _controller.getTimer().catchError((_) => null);
        drawTime ??= await _controller.getDrawTime().catchError((_) => null);
        terminal ??= await _controller.getTerminalId().catchError((_) => null);
        lastTransaction ??= await _controller.getLastTransaction().catchError(
          (_) => null,
        );

        if (walletBalance == null) {
          walletBalance = await _controller.getWalletBalance().catchError(
            (_) => null,
          );

          final double balance =
              double.tryParse(walletBalance?.amount ?? "0") ?? 0.0;

          walletController.setBalance(balance);
        }

        if (initResults == null || initResults!.isEmpty) {
          initResults = await _controller.getInitResults().catchError(
            (_) => null,
          );
        }

        if (!mounted) return;

        setState(() {});

        if (!_isAnyDataMissing()) {
          refreshTimer.cancel();
        }
      } catch (e) {
        debugPrint("Auto refresh error: $e");
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    if (_remainingSeconds <= 0) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isWithinWorkingHours()) {
        t.cancel();
        return;
      }

      if (_remainingSeconds <= 0) {
        t.cancel();
        _loadHomeData();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _countdownTimer?.cancel();
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    _keyboardFocus.dispose();
    super.dispose();
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    final printerBox = Hive.isBoxOpen('printerBox')
        ? Hive.box('printerBox')
        : await Hive.openBox('printerBox');

    await printerBox.clear();
    await _box.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginView()),
      (_) => false,
    );
  }

  final IndexController indexController = Get.put(IndexController());

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF032B60),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topHeader(indexController),
            YellowInfoBar(
              time: _isGameTimeNow() ? _formatTime(_remainingSeconds) : "  ",
              draw:
                  (drawTime?.nextTimeSlot != null &&
                      _isValidSlot(drawTime!.nextTimeSlot))
                  ? TimeOfDay(
                      hour: int.parse(drawTime!.nextTimeSlot.split(":")[0]),
                      minute: int.parse(drawTime!.nextTimeSlot.split(":")[1]),
                    ).format(context)
                  : "  ",
              date: drawTime?.date ?? "--",
              terminal: terminal?.terminalUser ?? "--",
              lastAmount: lastTransaction?.amount ?? "0",
              walletBalance: walletBalance?.amount ?? "0",
            ),
            Expanded(
              flex: 9,
              child: BettingGridScreen(
                limitUpdate: int.tryParse(walletBalance?.amount ?? '') ?? 0,
                slot:
                    _formatAmPmMinus(drawTime?.nextTimeSlot ?? "00:00") ??
                    "00:00",
                id: terminal?.terminalUser ?? "--",
              ),
            ), // Wrap in Expanded
          ],
        ),
      ),
    );
  }

  bool _isGameTimeNow() {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    const start = 9 * 60 + 45; // 09:45
    const end = 21 * 60 + 30; // 21:30

    if (!(nowMinutes >= start && nowMinutes <= end)) {
      _countdownTimer?.cancel();
      print("cancel");
    }
    return nowMinutes >= start && nowMinutes <= end;
  }

  bool _isValidSlot(String time) {
    final parts = time.split(":");
    final slotMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);

    const start = 9 * 60 + 45; // 09:45
    const end = 21 * 60 + 30; // 21:30

    return slotMinutes >= start && slotMinutes <= end;
  }

  // ================= UI =================
  Widget _topHeader(IndexController indexController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          decoration: const BoxDecoration(color: Color(0xFF0A2A4A)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 8),

              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Shree ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Lott',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF0000),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Container(
                height: 40,
                width: 120,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFE7A59A)),
                child: Text(
                  _formatAmPmMinus15(drawTime?.nextTimeSlot ?? "00:00"),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A33),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Obx(() {
                  final int pageIndex = indexController.selectedIndex.value;
                  final int start = pageIndex * 10;
                  final int end = start + 10;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(10, (localIndex) {
                      final int actualIndex = start + localIndex;

                      final hasData =
                          initResults != null &&
                          actualIndex < initResults!.length;

                      final e = hasData ? initResults![actualIndex] : null;

                      return SizedBox(
                        width: 100,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(
                              headerColors[localIndex % headerColors.length],
                            ),
                          ),
                          child: Text(
                            hasData
                                ? "${e!.type}${e.subType}${e.winningNumber}"
                                : "",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2A33),
                              height: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ─────────────────────────────────────────────────────────────
        // Reusable press-effect wrapper
        // ─────────────────────────────────────────────────────────────

        // ─────────────────────────────────────────────────────────────
        // Updated header bar
        // ─────────────────────────────────────────────────────────────
        Container(
          height: 30,
          color: Colors.white,
          child: Row(
            children: [
              // 1. Refresh
              Expanded(
                child: Pressable(
                  onTap: () async {
                    await _loadHomeData();
                  },
                  child: _headerIcon(
                    icon: Icons.refresh,
                    value: 'Refresh',
                    onTap: null,
                  ),
                ),
              ),

              _headerDivider(),

              // 2. Accounts
              Expanded(
                child: Pressable(
                  onTap: () async {
                    try {
                      showAccountDetailsDialog(context, {
                        "userId": terminal?.terminalUser?.toString() ?? "0",
                        "walletBalance": walletController.walletBalance,
                      });
                    } catch (e, s) {
                      debugPrint("Accounts Error: $e");
                      debugPrintStack(stackTrace: s);
                    }
                  },
                  child: _headerIcon(
                    icon: Icons.lock_open,
                    value: 'Accounts',
                    onTap: null,
                  ),
                ),
              ),

              _headerDivider(),

              // 3. Passwords
              Expanded(
                child: Pressable(
                  onTap: () async {
                    await showChangePasswordDialog(
                      context,
                      baseUrl: ApiConstants.baseUrl,
                      token: await ApiClient.getToken(),
                    );
                  },
                  child: _headerIcon(
                    icon: Icons.lock_open,
                    value: 'Passwords',
                    onTap: null,
                  ),
                ),
              ),

              _headerDivider(),

              // 4. Report
              Expanded(
                child: Pressable(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: Colors.black.withOpacity(.45),
                      builder: (_) => const ShopReportDialog(),
                    );
                  },
                  child: _headerIcon(
                    icon: Icons.receipt_long,
                    value: 'Report',
                    onTap: null,
                  ),
                ),
              ),

              _headerDivider(),

              // 5. Support
              Expanded(
                child: Pressable(
                  onTap: () => showSupportDialog(context),
                  child: _headerIcon(
                    icon: Icons.support_agent,
                    value: 'Support',
                    onTap: null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.purple.withOpacity(0.12),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 16, //
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.black,
    );
  }

  String _formatAmPmMinus15(String time) {
    final parts = time.split(':');

    int hour = int.parse(parts[0]);
    int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

    var totalMinutes = hour * 60 + minute;

    // Before 09:45 → return empty
    if (totalMinutes < (9 * 60 + 45)) {
      return "";
    }

    // After 21:30 → cap to 21:30
    if (totalMinutes > (21 * 60 + 30)) {
      hour = 21;
      minute = 30;
    } else {
      // Subtract 15 minutes
      totalMinutes -= 15;

      hour = totalMinutes ~/ 60;
      minute = totalMinutes % 60;
    }

    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String period = hour >= 12 ? 'PM' : 'AM';

    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatAmPmMinus(String time) {
    print(time);
    final parts = time.split(':');

    int hour = int.parse(parts[0]);
    int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

    var totalMinutes = hour * 60 + minute;


    // Subtract 15 minutes
    totalMinutes -= 15;

    hour = totalMinutes ~/ 60;
    minute = totalMinutes % 60;

    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String period = hour >= 12 ? 'PM' : 'AM';

    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
