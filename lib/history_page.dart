import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class HistoryPage extends StatefulWidget {
  final String phone;
  final String username;
  final String email;
  final String password;

  const HistoryPage({
    super.key,
    required this.phone,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  bool isLoading = true;
  String error = '';
  String searchQuery = '';
  String selectedType = 'All';
  final List<String> typeFilters = ['All', 'UPI', 'Recharge', 'Bill', 'Other'];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final ref = FirebaseDatabase.instance.ref().child(
        'users/${widget.phone}/transactions',
      );
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map) {
        final txMap = Map<String, dynamic>.from(snapshot.value as Map);
        transactions =
            txMap.values
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
        transactions.sort(
          (a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''),
        );
      } else {
        transactions = [];
      }
      filterTransactions();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load transactions.';
        isLoading = false;
      });
    }
  }

  void filterTransactions() {
    filteredTransactions =
        transactions.where((tx) {
          final recipient = extractRecipient(tx).toLowerCase();
          final purpose = (tx['purpose'] ?? '').toLowerCase();
          final amount = (tx['amount'] ?? '').toString();
          final matchesSearch =
              searchQuery.isEmpty ||
              recipient.contains(searchQuery.toLowerCase()) ||
              purpose.contains(searchQuery.toLowerCase()) ||
              amount.contains(searchQuery);
          final type = getTransactionType(tx);
          final matchesType = selectedType == 'All' || type == selectedType;
          return matchesSearch && matchesType;
        }).toList();
  }

  String formatAmount(num amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return format.format(amount);
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.tryParse(timestamp);
      if (dt != null) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
    } catch (_) {}
    return timestamp;
  }

  String extractRecipient(Map<String, dynamic> tx) {
    final purpose = tx['purpose'] ?? '';
    if (purpose.startsWith('QR Payment - ')) {
      return purpose.replaceFirst('QR Payment - ', '');
    } else if (purpose.contains('(') && purpose.contains(')')) {
      final start = purpose.indexOf('(');
      final end = purpose.indexOf(')', start);
      if (start != -1 && end != -1 && end > start) {
        return purpose.substring(start + 1, end);
      }
    }
    return '';
  }

  String getTransactionType(Map<String, dynamic> tx) {
    final purpose = (tx['purpose'] ?? '').toLowerCase();
    if (purpose.contains('qr payment')) return 'UPI';
    if (purpose.contains('recharge')) return 'Recharge';
    if (purpose.contains('bill')) return 'Bill';
    return 'Other';
  }

  Map<String, List<Map<String, dynamic>>> groupByDate(
    List<Map<String, dynamic>> txs,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final tx in txs) {
      final timestamp = tx['timestamp']?.toString();
      String dateKey = '';
      if (timestamp != null) {
        final dt = DateTime.tryParse(timestamp);
        if (dt != null) {
          final now = DateTime.now();
          if (dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day) {
            dateKey = 'Today';
          } else if (dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day - 1) {
            dateKey = 'Yesterday';
          } else {
            dateKey = DateFormat('dd MMM yyyy').format(dt);
          }
        } else {
          dateKey = timestamp;
        }
      }
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }
    return grouped;
  }

  Widget buildAvatar(String recipient) {
    if (recipient.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.person));
    }
    final initials =
        recipient.trim().isNotEmpty
            ? recipient
                .trim()
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase()
            : '?';
    return CircleAvatar(child: Text(initials));
  }

  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      filterTransactions();
    });
  }

  void onTypeFilterChanged(String type) {
    setState(() {
      selectedType = type;
      filterTransactions();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    await fetchTransactions();
  }

  void copyToClipboard(String text, [String? label]) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(label ?? 'Copied!')));
  }

  void shareTransaction(Map<String, dynamic> tx) {
    // Placeholder: Implement share logic with share_plus or similar package
    copyToClipboard(tx.toString(), 'Transaction details copied!');
  }

  Future<void> _showTransactionDetails(Map<String, dynamic> tx) async {
    final recipient = extractRecipient(tx);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaction Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: ${formatAmount(tx['amount'] ?? 0)}'),
                Text('Purpose: ${tx['purpose'] ?? ''}'),
                if (recipient.isNotEmpty)
                  Row(
                    children: [
                      Text('To: $recipient'),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed:
                            () =>
                                copyToClipboard(recipient, 'Recipient copied!'),
                        tooltip: 'Copy UPI/Account',
                      ),
                    ],
                  ),
                Text(
                  'Date & Time: ${formatTimestamp(tx['timestamp']?.toString())}',
                ),
                if (tx['type'] != null) Text('Type: ${tx['type']}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy All'),
                      onPressed:
                          () => copyToClipboard(
                            tx.toString(),
                            'Transaction copied!',
                          ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () => shareTransaction(tx),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupByDate(filteredTransactions);
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(
                child: Text(error, style: const TextStyle(color: Colors.red)),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search by recipient, UPI, amount...',
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          typeFilters
                              .map(
                                (type) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: selectedType == type,
                                    onSelected:
                                        (_) => onTypeFilterChanged(type),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child:
                          filteredTransactions.isEmpty
                              ? const Center(
                                child: Text("No transactions found."),
                              )
                              : ListView(
                                children:
                                    grouped.entries.expand((entry) {
                                      final date = entry.key;
                                      final txs = entry.value;
                                      return [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            date,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        ...txs.map((tx) {
                                          final amount = tx['amount'] ?? 0;
                                          final purpose = tx['purpose'] ?? '';
                                          final timestamp = formatTimestamp(
                                            tx['timestamp']?.toString(),
                                          );
                                          final isCredit = amount > 0;
                                          final color =
                                              isCredit
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50;
                                          final icon =
                                              isCredit
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward;
                                          final iconColor =
                                              isCredit
                                                  ? Colors.green
                                                  : Colors.red;
                                          final recipient = extractRecipient(
                                            tx,
                                          );
                                          final type = getTransactionType(tx);
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 12,
                                            ),
                                            child: Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              color: color,
                                              child: ListTile(
                                                onTap:
                                                    () =>
                                                        _showTransactionDetails(
                                                          tx,
                                                        ),
                                                leading: buildAvatar(recipient),
                                                title: Row(
                                                  children: [
                                                    Text(
                                                      '${isCredit ? '+' : '-'}${formatAmount(amount)}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: iconColor,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Chip(
                                                      label: Text(type),
                                                      backgroundColor:
                                                          Colors.blue.shade50,
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (recipient.isNotEmpty)
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'To: $recipient',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 15,
                                                                ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.copy,
                                                              size: 16,
                                                            ),
                                                            onPressed:
                                                                () => copyToClipboard(
                                                                  recipient,
                                                                  'Recipient copied!',
                                                                ),
                                                            tooltip:
                                                                'Copy UPI/Account',
                                                          ),
                                                        ],
                                                      ),
                                                    Text(
                                                      purpose,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.access_time,
                                                          size: 16,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          timestamp,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ];
                                    }).toList(),
                              ),
                    ),
                  ),
                ],
              ),
    );
  }
}
