import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/planning_remote_datasource.dart';
import '../../data/models/availability_rule_model.dart';

final planningRemoteProvider = Provider<PlanningRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlanningRemoteDatasource(apiClient);
});

final myRulesProvider = FutureProvider<List<AvailabilityRuleModel>>((ref) async {
  final datasource = ref.watch(planningRemoteProvider);
  return datasource.getMyRules();
});
