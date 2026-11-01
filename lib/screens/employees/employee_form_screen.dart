import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/utils/choices.dart';
import '../../widgets/dynamic_form.dart';
import '../../widgets/rec_list.dart';

/// Add / edit employee. Get.arguments = employee id (edit) or null (add).
class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key});
  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  static const _repo = DocRepo('employees');
  final _formKey = GlobalKey<DynamicFormState>();
  final String? _id = Get.arguments as String?;
  Rec? _existing;
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    if (_id == null) {
      _loading = false;
    } else {
      _repo.getOne(_id!).then((r) => setState(() {
            _existing = r;
            _loading = false;
          }));
    }
  }

  List<FieldSpec> _fields() {
    final e = _existing?.d ?? {};
    dynamic v(String k) => e[k];
    return [
      const FieldSpec.section('Overview'),
      FieldSpec('code', 'Employee code', required: true, initial: v('code')),
      FieldSpec('name', 'Full name', required: true, initial: v('name')),
      FieldSpec('nationality', 'Nationality', initial: v('nationality')),
      FieldSpec('mobile', 'Mobile', type: FT.phone, initial: v('mobile')),
      FieldSpec('email', 'Email', type: FT.email, initial: v('email')),
      FieldSpec('jobTitle', 'Job title', initial: v('jobTitle')),
      FieldSpec('departmentId', 'Department', type: FT.dropdown, required: true, choices: Choices.departments(), initial: v('departmentId')),
      FieldSpec('regionId', 'Region', type: FT.dropdown, required: true, choices: Choices.regions(), initial: v('regionId')),
      FieldSpec('crId', 'Sponsor / Commercial Registration', type: FT.dropdown, choices: Choices.crs(), initial: v('crId')),
      FieldSpec('joiningDate', 'Joining date', type: FT.date, initial: v('joiningDate')),
      FieldSpec('status', 'Status', type: FT.dropdown, required: true,
          choices: Choices.opts(['Active', 'Temporary', 'Offboarded']), initial: v('status') ?? 'Active'),
      FieldSpec('workLocation', 'Work location', initial: v('workLocation')),
      FieldSpec('idNumber', 'Iqama / ID number', initial: v('idNumber')),
      const FieldSpec.section('Employment'),
      FieldSpec('contractType', 'Contract type', type: FT.dropdown,
          choices: Choices.opts(['Fixed Term', 'Unlimited', 'Temporary']), initial: v('contractType')),
      FieldSpec('contractStart', 'Contract start', type: FT.date, initial: v('contractStart')),
      FieldSpec('contractEnd', 'Contract end', type: FT.date, initial: v('contractEnd')),
      FieldSpec('contractStatus', 'Contract status', type: FT.dropdown,
          choices: Choices.opts(['Active', 'Transfer Pending', 'Pending Renewal', 'Cancelled']), initial: v('contractStatus') ?? 'Active'),
      FieldSpec('payrollType', 'Payroll type', type: FT.dropdown,
          choices: Choices.opts(['Monthly', 'Daily']), initial: v('payrollType') ?? 'Monthly'),
      FieldSpec('isMudad', 'Registered in Mudad', type: FT.toggle, initial: v('isMudad') ?? true),
      FieldSpec('isAjeer', 'Ajeer (outsourced)', type: FT.toggle, initial: v('isAjeer') ?? false),
      const FieldSpec.section('Monthly compensation & employer costs'),
      FieldSpec('baseSalary', 'Base salary', type: FT.money, initial: v('baseSalary')),
      FieldSpec('allowances', 'Allowances (housing, transport, food…)', type: FT.money, initial: v('allowances')),
      FieldSpec('gosi', 'GOSI (employer)', type: FT.money, initial: v('gosi')),
      FieldSpec('eosbAccrual', 'EOSB accrual', type: FT.money, initial: v('eosbAccrual')),
      FieldSpec('insurance', 'Insurance', type: FT.money, initial: v('insurance')),
      FieldSpec('otherCosts', 'Other recurring costs', type: FT.money, initial: v('otherCosts')),
    ];
  }

  Future<void> _save() async {
    final data = _formKey.currentState?.collect();
    if (data == null) return;
    setState(() => _saving = true);
    try {
      for (final k in ['baseSalary', 'allowances', 'gosi', 'eosbAccrual', 'insurance', 'otherCosts']) {
        data[k] = data[k] ?? 0;
      }
      if (_id == null) {
        await _repo.add(data);
      } else {
        await _repo.update(_id!, data, before: _existing!.d);
      }
      Get.back();
      toast('Saved', 'Employee saved');
    } catch (e) {
      setState(() => _saving = false);
      toast('Error', '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_id == null ? 'Add Employee' : 'Edit Employee')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(children: [
                    DynamicForm(key: _formKey, fields: _fields()),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}
