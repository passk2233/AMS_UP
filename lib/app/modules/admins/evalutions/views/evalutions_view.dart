import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../admin_widgets/evalutions/eval_questions_page.dart';
import '../../admin_widgets/evalutions/eval_results_page.dart';
import '../../admin_widgets/evalutions/eval_teacher_detail_page.dart';
import '../../admin_widgets/evalutions/eval_window_page.dart';
import '../controllers/evalutions_controller.dart';

/// Admin "Evaluations" tab.
///
/// Switches between question-bank management, the teacher-results list,
/// and a per-teacher detail page based on [EvalutionController.pageMode].
class EvalutionView extends GetView<EvalutionController> {
  const EvalutionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetImages.dashboardBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const AdminAppBar(),
            Expanded(child: _EvalutionBody(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Picks the correct sub-page based on [EvalutionController.pageMode].
class _EvalutionBody extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _EvalutionBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.pageMode.value) {
        case EvalutionPageMode.questions:
          return EvalQuestionsPage(controller: controller);
        case EvalutionPageMode.teacherDetail:
          return EvalTeacherDetailPage(controller: controller);
        case EvalutionPageMode.window:
          return EvalWindowPage(controller: controller);
        case EvalutionPageMode.results:
        default:
          return EvalResultsPage(controller: controller);
      }
    });
  }
}
