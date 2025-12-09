import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/revenue_service.dart';
import '../../models/revenue_stats.dart';
import '../../theme/app_theme.dart';

class RevenueScreen extends StatefulWidget {
  final String shopId;

  const RevenueScreen({super.key, required this.shopId});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final RevenueService _revenueService = RevenueService();
  RevenueStats? _stats;
  Map<String, double>? _dailyRevenue;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _revenueService.calculateRevenueStats(widget.shopId);
      final dailyRevenue = await _revenueService.getDailyRevenue(widget.shopId, _startDate, _endDate);
      setState(() {
        _stats = stats;
        _dailyRevenue = dailyRevenue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading revenue data: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartData() {
    if (_dailyRevenue == null || _dailyRevenue!.isEmpty) {
      return [];
    }

    final sortedEntries = _dailyRevenue!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return const Center(child: Text('Failed to load revenue data'));
    }

    return RefreshIndicator(
      onRefresh: _loadRevenueData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today',
                  currencyFormat.format(_stats!.todayRevenue),
                  '${_stats!.todayOrders} orders',
                  Icons.today,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'This Week',
                  currencyFormat.format(_stats!.weekRevenue),
                  '${_stats!.weekOrders} orders',
                  Icons.date_range,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatCard(
            'This Month',
            currencyFormat.format(_stats!.monthRevenue),
            '${_stats!.monthOrders} orders',
            Icons.calendar_month,
            AppColors.tertiary,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Revenue Trend',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final DateTimeRange? picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                            });
                            _loadRevenueData();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Change Range'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  if (_dailyRevenue != null && _dailyRevenue!.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _stats!.monthRevenue / 5,
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < _dailyRevenue!.length) {
                                    final dateKey = _dailyRevenue!.keys.toList()[value.toInt()];
                                    final date = DateTime.parse(dateKey);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('M/d').format(date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '\$${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getChartData(),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No revenue data for selected period',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Average Order Value (Today)', 
                    _stats!.todayOrders > 0 
                      ? currencyFormat.format(_stats!.todayRevenue / _stats!.todayOrders)
                      : currencyFormat.format(0)
                  ),
                  _buildSummaryRow('Average Order Value (Week)', 
                    _stats!.weekOrders > 0 
                      ? currencyFormat.format(_stats!.weekRevenue / _stats!.weekOrders)
                      : currencyFormat.format(0)
                  ),
                  _buildSummaryRow('Average Order Value (Month)', 
                    _stats!.monthOrders > 0 
                      ? currencyFormat.format(_stats!.monthRevenue / _stats!.monthOrders)
                      : currencyFormat.format(0)
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy h:mm a').format(_stats!.lastUpdated)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
