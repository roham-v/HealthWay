import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('patients');
  await Hive.openBox('records');
  await Hive.openBox('visits');
  runApp(const HealthWayApp());
}

class HealthWayApp extends StatelessWidget {
  const HealthWayApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthWay | راه سلامتی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'IranSans'),
      home: const Directionality(textDirection: TextDirection.rtl, child: PatientSelector()),
    );
  }
}

class PatientSelector extends StatefulWidget {
  const PatientSelector({super.key});
  @override
  State<PatientSelector> createState() => _PatientSelectorState();
}

class _PatientSelectorState extends State<PatientSelector> {
  final Box patients = Hive.box('patients');
  final _name = TextEditingController();
  final _age = TextEditingController();
  String gender = 'مرد';

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  void add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await patients.add({
      'name': name,
      'age': int.tryParse(_age.text.trim()) ?? 0,
      'gender': gender,
      'created': DateTime.now().toIso8601String()
    });
    _name.clear();
    _age.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = patients.values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('بیماران')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final it = Map<String, dynamic>.from(list[i]);
                  return Card(
                    child: ListTile(
                      title: Text(it['name'] ?? '—'),
                      subtitle: Text('سن: ${it['age']} — ${it['gender']}'),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Dashboard(patientIndex: i),
                          ),
                        ),
                        child: const Text('انتخاب'),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const Text('افزودن بیمار'),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام')),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _age,
                    decoration: const InputDecoration(labelText: 'سن'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: gender,
                  items: ['مرد', 'زن']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => gender = v!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: add, child: const Text('ذخیره')),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final int patientIndex;
  const Dashboard({super.key, required this.patientIndex});

  @override
  Widget build(BuildContext context) {
    final Box patients = Hive.box('patients');
    final patient = Map<String, dynamic>.from(patients.getAt(patientIndex));
    return Scaffold(
      appBar: AppBar(title: Text('HealthWay — ${patient['name']}')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.dashboard),
                  SizedBox(width: 8),
                  Expanded(child: Text('گزارش امروز و میانگین‌ها')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                quickAction(context, Icons.bloodtype, 'قند',
                    () => RouteHelper.openForm(context, FormType.sugar, patientIndex)),
                quickAction(context, Icons.favorite, 'فشار',
                    () => RouteHelper.openForm(context, FormType.pressure, patientIndex)),
                quickAction(context, Icons.air, 'اکسیژن',
                    () => RouteHelper.openForm(context, FormType.oxygen, patientIndex)),
                quickAction(context, Icons.wc, 'ادرار',
                    () => RouteHelper.openForm(context, FormType.urine, patientIndex)),
                quickAction(context, Icons.medication, 'دارو',
                    () => RouteHelper.openForm(context, FormType.meds, patientIndex)),
                quickAction(context, Icons.local_hospital, 'ویزیت',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => VisitsPage(patientIndex: patientIndex)))),
                quickAction(context, Icons.fastfood, 'غذا',
                    () => RouteHelper.openForm(context, FormType.meal, patientIndex)),
                quickAction(context, Icons.vaccines, 'انسولین',
                    () => RouteHelper.openForm(context, FormType.insulin, patientIndex)),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecordsList(patientIndex: patientIndex)),
              ),
              icon: const Icon(Icons.archive),
              label: const Text('مشاهده رکوردها'),
            ),
          ],
        ),
      ),
    );
  }

  Widget quickAction(BuildContext c, IconData ic, String l, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
          ),
          child: Column(children: [Icon(ic, size: 28), const SizedBox(height: 6), Text(l)]),
        ),
      );
}

class RouteHelper {
  static void openForm(BuildContext c, FormType t, int patientIndex) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => EntryForm(type: t, patientIndex: patientIndex)));
  }
}

enum FormType { sugar, pressure, oxygen, insulin, meal, urine, meds }

class EntryForm extends StatefulWidget {
  final FormType type;
  final int patientIndex;
  const EntryForm({super.key, required this.type, required this.patientIndex});
  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final Box records = Hive.box('records');
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final _val = TextEditingController();
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _bpm = TextEditingController();
  final _spo2 = TextEditingController();
  final _medName = TextEditingController();
  final _medDose = TextEditingController();
  final _medTimes = TextEditingController();
  final _urineVol = TextEditingController();

  String insulinType = 'نوومیکس (قلمی)';
  String mealType = 'صبحانه';
  String urineColor = 'زرد کمرنگ';
  String catheterType = 'فولی';

  @override
  void dispose() {
    _val.dispose();
    _sys.dispose();
    _dia.dispose();
    _bpm.dispose();
    _spo2.dispose();
    _medName.dispose();
    _medDose.dispose();
    _medTimes.dispose();
    _urineVol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.type;
    return Scaffold(
      appBar: AppBar(title: Text(titleFor(t))),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            buildDatePicker(),
            if (t == FormType.sugar)
              TextField(controller: _val, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قند (mg/dL)')),
            if (t == FormType.pressure)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _sys, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سیستولیک'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _dia, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'دیاستولیک'))),
                    ],
                  ),
                  TextField(controller: _bpm, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ضربان قلب (bpm)')),
                ],
              ),
            if (t == FormType.oxygen)
              Column(
                children: [
                  TextField(controller: _spo2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SpO2 (%)')),
                  TextField(controller: _bpm, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ضربان قلب (bpm)')),
                ],
              ),
            if (t == FormType.insulin)
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: insulinType,
                    items: ['نوومیکس (قلمی)', 'لانتوس', 'رگولار'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => insulinType = v!),
                  ),
                  TextField(controller: _val, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'دوز (واحد)')),
                ],
              ),
            if (t == FormType.meal)
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: mealType,
                    items: ['صبحانه', 'نهار', 'شام', 'میان‌وعده'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => mealType = v!),
                  ),
                  TextField(controller: _val, decoration: const InputDecoration(labelText: 'نوع غذا')),
                ],
              ),
            if (t == FormType.urine)
              Column(
                children: [
                  TextField(controller: _urineVol, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'حجم ادرار (ml)')),
                  DropdownButtonFormField<String>(
                    value: urineColor,
                    items: ['خیلی روشن', 'زرد کمرنگ', 'زرد پررنگ', 'قهوه‌ای', 'قرمز'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => urineColor = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: catheterType,
                    items: ['فولی', 'سوپراپوبیک', 'نلاتون'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => catheterType = v!),
                  ),
                ],
              ),
            if (t == FormType.meds)
              Column(
                children: [
                  TextField(controller: _medName, decoration: const InputDecoration(labelText: 'نام دارو')),
                  TextField(controller: _medDose, decoration: const InputDecoration(labelText: 'دوز')),
                  TextField(controller: _medTimes, decoration: const InputDecoration(labelText: 'ساعات مصرف (مثلاً 08:00,20:00)')),
                ],
              ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: save, child: const Text('ذخیره')),
          ],
        ),
      ),
    );
  }

  Widget buildDatePicker() {
    final j = Jalali.fromDateTime(selectedDate);
    return Row(
      children: [
        Expanded(child: ListTile(title: Text('تاریخ: ${j.formatCompactDate()}'), onTap: pickDate)),
        Expanded(child: ListTile(title: Text('ساعت: ${selectedTime.format(context)}'), onTap: pickTime)),
      ],
    );
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(context: context, initialTime: selectedTime);
    if (t != null) setState(() => selectedTime = t);
  }

  String titleFor(FormType t) {
    switch (t) {
      case FormType.sugar: return 'ثبت قند خون';
      case FormType.pressure: return 'ثبت فشار';
      case FormType.oxygen: return 'ثبت اکسیژن';
      case FormType.insulin: return 'ثبت انسولین';
      case FormType.meal: return 'ثبت وعده غذایی';
      case FormType.urine: return 'ثبت ادرار';
      case FormType.meds: return 'ثبت دارو';
    }
  }

  void save() async {
    final now = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    final item = <String, dynamic>{
      'ts': now.toIso8601String(),
      'patient': widget.patientIndex,
      'type': widget.type.toString().split('.').last
    };
    switch (widget.type) {
      case FormType.sugar: item['value'] = int.tryParse(_val.text); break;
      case FormType.pressure:
        item['systolic'] = int.tryParse(_sys.text);
        item['diastolic'] = int.tryParse(_dia.text);
        item['bpm'] = int.tryParse(_bpm.text);
        break;
      case FormType.oxygen:
        item['spo2'] = int.tryParse(_spo2.text);
        item['bpm'] = int.tryParse(_bpm.text);
        break;
      case FormType.insulin:
        item['insulin_type'] = insulinType;
        item['dose'] = int.tryParse(_val.text);
        break;
      case FormType.meal:
        item['meal_type'] = mealType;
        item['meal_desc'] = _val.text;
        break;
      case FormType.urine:
        item['volume'] = int.tryParse(_urineVol.text);
        item['urine_color'] = urineColor;
        item['catheter_type'] = catheterType;
        break;
      case FormType.meds:
        item['med_name'] = _medName.text;
        item['med_dose'] = _medDose.text;
        item['med_times'] = _medTimes.text;
        break;
    }
    await records.add(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذخیره شد')));
      Navigator.of(context).pop();
    }
  }
}

class RecordsList extends StatelessWidget {
  final int patientIndex;
  final Box records = Hive.box('records');
  RecordsList({super.key, required this.patientIndex});

  @override
  Widget build(BuildContext context) {
    final items = records.values
        .where((e) => e is Map && e['patient'] == patientIndex)
        .cast<Map>()
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('رکوردها')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = Map<String, dynamic>.from(items[i]);
          final ts = DateTime.tryParse(it['ts'] ?? '') ?? DateTime.now();
          final j = Jalali.fromDateTime(ts);
          return Card(
            child: ListTile(
              title: Text('${it['type']} — ${j.formatCompactDate()} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'),
              subtitle: Text(it.entries.map((e) => '${e.key}: ${e.value}').join(' | ')),
            ),
          );
        },
      ),
    );
  }
}

class VisitsPage extends StatefulWidget {
  final int patientIndex;
  const VisitsPage({super.key, required this.patientIndex});
  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  final Box visits = Hive.box('visits');
  final _doc = TextEditingController();
  final _file = TextEditingController();
  DateTime vDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay vTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _doc.dispose();
    _file.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = visits.values.cast<Map>().toList().reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('ویزیت‌ها')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ElevatedButton.icon(onPressed: () => _showAdd(context), icon: const Icon(Icons.add), label: const Text('ویزیت جدید')),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = Map<String, dynamic>.from(items[i]);
                  final dt = DateTime.tryParse(it['ts'] ?? '') ?? DateTime.now();
                  final j = Jalali.fromDateTime(dt);
                  return Card(
                    child: ListTile(
                      title: Text('${it['doctor'] ?? ''} — ${j.formatCompactDate()} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'),
                      subtitle: Text('پرونده: ${it['file_no'] ?? ''}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdd(BuildContext c) {
    _doc.text = '';
    _file.text = '';
    vDate = DateTime.now().add(const Duration(days: 1));
    vTime = const TimeOfDay(hour: 10, minute: 0);
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('افزودن ویزیت'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _doc, decoration: const InputDecoration(labelText: 'نام پزشک')),
              TextField(controller: _file, decoration: const InputDecoration(labelText: 'شماره پرونده')),
              ListTile(title: Text('تاریخ: ${Jalali.fromDateTime(vDate).formatCompactDate()}'), trailing: const Icon(Icons.date_range), onTap: () => _pickDate(c)),
              ListTile(title: Text('ساعت: ${vTime.format(context)}'), trailing: const Icon(Icons.access_time), onTap: () => _pickTime(c)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('انصراف')),
          ElevatedButton(onPressed: _save, child: const Text('ذخیره')),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext c) async {
    final d = await showDatePicker(context: c, initialDate: vDate, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime(2100));
    if (d != null) setState(() => vDate = d);
  }

  Future<void> _pickTime(BuildContext c) async {
    final t = await showTimePicker(context: c, initialTime: vTime);
    if (t != null) setState(() => vTime = t);
  }

  void _save() {
    final dt = DateTime(vDate.year, vDate.month, vDate.day, vTime.hour, vTime.minute);
    visits.add({'ts': dt.toIso8601String(), 'doctor': _doc.text, 'file_no': _file.text});
    if (mounted) Navigator.of(context).pop();
  }
}
