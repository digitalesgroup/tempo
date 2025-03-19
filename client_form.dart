// lib/widgets/specialized/client_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import '../../models/client_model.dart';

// Clase para representar un campo check normal
class CustomCheckItem extends StatelessWidget {
  final String name;
  final String label;
  final bool initialValue;

  const CustomCheckItem({
    super.key,
    required this.name,
    required this.label,
    this.initialValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderCheckbox(
      name: name,
      initialValue: initialValue,
      title: Text(label),
      decoration: const InputDecoration(
        border: InputBorder.none,
      ),
    );
  }
}

// Widget personalizado para input de chips
class CustomChipsInput extends StatefulWidget {
  final String name;
  final InputDecoration decoration;
  final List<String> initialValue;
  final List<String> suggestions;

  const CustomChipsInput({
    Key? key,
    required this.name,
    required this.decoration,
    this.initialValue = const [],
    this.suggestions = const [],
  }) : super(key: key);

  @override
  State<CustomChipsInput> createState() => _CustomChipsInputState();
}

class _CustomChipsInputState extends State<CustomChipsInput> {
  late List<String> _selectedItems;
  final TextEditingController _controller = TextEditingController();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<List<String>>(
      name: widget.name,
      initialValue: _selectedItems,
      builder: (FormFieldState<List<String>> field) {
        return InputDecorator(
          decoration: widget.decoration.copyWith(
            errorText: field.errorText,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.0,
                children: _selectedItems
                    .map((item) => Chip(
                          label: Text(item),
                          onDeleted: () {
                            setState(() {
                              _selectedItems.remove(item);
                              field.didChange(_selectedItems);
                            });
                          },
                        ))
                    .toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Agregar nuevo',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _showSuggestions = value.isNotEmpty;
                        });
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty &&
                            !_selectedItems.contains(value)) {
                          setState(() {
                            _selectedItems.add(value);
                            _controller.clear();
                            _showSuggestions = false;
                            field.didChange(_selectedItems);
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_controller.text.isNotEmpty &&
                          !_selectedItems.contains(_controller.text)) {
                        setState(() {
                          _selectedItems.add(_controller.text);
                          _controller.clear();
                          _showSuggestions = false;
                          field.didChange(_selectedItems);
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_showSuggestions) ...[
                const Divider(),
                Wrap(
                  spacing: 8.0,
                  children: widget.suggestions
                      .where((suggestion) =>
                          suggestion
                              .toLowerCase()
                              .contains(_controller.text.toLowerCase()) &&
                          !_selectedItems.contains(suggestion))
                      .map((suggestion) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedItems.add(suggestion);
                                _controller.clear();
                                _showSuggestions = false;
                                field.didChange(_selectedItems);
                              });
                            },
                            child: Chip(
                              label: Text(suggestion),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ClientForm extends ConsumerStatefulWidget {
  final ClientModel? initialData;
  final Function(ClientModel) onSave;

  const ClientForm({
    super.key,
    this.initialData,
    required this.onSave,
  });

  @override
  ConsumerState<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<ClientForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _tabController = PageController();
  int _currentTab = 0;

  // Controladores para el cálculo de IMC
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();

  // Variables para los tratamientos
  bool _showFacialTreatment = false;
  bool _showBodyTreatment = false;
  bool _showTanningTreatment = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores si hay datos previos
    if (widget.initialData != null) {
      _weightController.text =
          widget.initialData!.bodyTreatment.weight.toString();
      _heightController.text =
          widget.initialData!.bodyTreatment.height.toString();
      _bmiController.text =
          widget.initialData!.bodyTreatment.bmi.toStringAsFixed(2);

      _showFacialTreatment =
          widget.initialData!.facialTreatment.skinType.isNotEmpty;
      _showBodyTreatment = widget.initialData!.bodyTreatment.height > 0;
      _showTanningTreatment =
          widget.initialData!.tanningTreatment.glasgowScale > 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bmiController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (weight != null && height != null && height > 0) {
      final bmi = weight / ((height / 100) * (height / 100));
      _bmiController.text = bmi.toStringAsFixed(2);
    } else {
      _bmiController.text = '';
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final data = _formKey.currentState!.value;

      // Construir objeto de información personal
      final personalInfo = PersonalInfo(
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        idNumber: data['idNumber'] ?? '',
        occupation: data['occupation'] ?? '',
        gender: data['gender'] ?? '',
        birthDate: data['birthDate'] ?? DateTime.now(),
      );

      // Construir objeto de información de contacto
      final contactInfo = ContactInfo(
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        address: data['address'] ?? '',
      );

      // Construir objeto de información médica
      final medicalInfo = MedicalInfo(
        allergies: data['allergies'] ?? false,
        respiratory: data['respiratory'] ?? false,
        nervousSystem: data['nervousSystem'] ?? false,
        diabetes: data['diabetes'] ?? false,
        kidney: data['kidney'] ?? false,
        digestive: data['digestive'] ?? false,
        cardiac: data['cardiac'] ?? false,
        thyroid: data['thyroid'] ?? false,
        previousSurgeries: data['previousSurgeries'] ?? false,
        otherConditions: data['otherConditions'] ?? '',
      );

      // Construir objeto de información estética
      final aestheticInfo = AestheticInfo(
        productsUsed: List<String>.from(data['productsUsed'] ?? []),
        currentTreatments: List<String>.from(data['currentTreatments'] ?? []),
        other: data['aestheticOther'] ?? '',
      );

      // Construir objeto de hábitos de vida
      final lifestyleInfo = LifestyleInfo(
        smoker: data['smoker'] ?? false,
        alcohol: data['alcohol'] ?? false,
        regularPhysicalActivity: data['regularPhysicalActivity'] ?? false,
        sleepProblems: data['sleepProblems'] ?? false,
      );

      // Construir objeto de tratamiento facial
      final facialTreatment = _showFacialTreatment
          ? FacialTreatment(
              skinType: data['skinType'] ?? '',
              skinCondition: data['skinCondition'] ?? '',
              flaccidityDegree: data['flaccidityDegree'] ?? 0,
              facialMarks: [], // Aquí irían las marcas faciales del diagrama
            )
          : FacialTreatment();

      // Construir objeto de tratamiento corporal
      final bodyTreatment = _showBodyTreatment
          ? BodyTreatment(
              highAbdomen:
                  double.tryParse(data['highAbdomen']?.toString() ?? '0') ?? 0,
              lowAbdomen:
                  double.tryParse(data['lowAbdomen']?.toString() ?? '0') ?? 0,
              waist: double.tryParse(data['waist']?.toString() ?? '0') ?? 0,
              back: double.tryParse(data['back']?.toString() ?? '0') ?? 0,
              leftArm: double.tryParse(data['leftArm']?.toString() ?? '0') ?? 0,
              rightArm:
                  double.tryParse(data['rightArm']?.toString() ?? '0') ?? 0,
              weight: double.tryParse(_weightController.text) ?? 0,
              height: double.tryParse(_heightController.text) ?? 0,
              bmi: double.tryParse(_bmiController.text) ?? 0,
              cellulite: Cellulite(
                grade: data['celluliteGrade'] ?? 1,
                location: data['celluliteLocation'] ?? '',
              ),
              stretches: [], // Aquí irían las estrías
            )
          : BodyTreatment();

      // Construir objeto de tratamiento de bronceado
      final tanningTreatment = _showTanningTreatment
          ? TanningTreatment(
              glasgowScale: data['glasgowScale'] ?? 0,
              fitzpatrickScale: data['fitzpatrickScale'] ?? 0,
            )
          : TanningTreatment();

      // Crear ClientModel completo
      final client = ClientModel(
        id: widget.initialData?.id ??
            'temp-id', // Será reemplazado por Firebase
        userId: widget.initialData?.userId ?? 'pending',
        personalInfo: personalInfo,
        contactInfo: contactInfo,
        medicalInfo: medicalInfo,
        aestheticInfo: aestheticInfo,
        lifestyleInfo: lifestyleInfo,
        consultationReason: data['consultationReason'] ?? '',
        facialTreatment: facialTreatment,
        bodyTreatment: bodyTreatment,
        tanningTreatment: tanningTreatment,
        preferredTreatments:
            List<String>.from(data['preferredTreatments'] ?? []),
        lastVisit: widget.initialData?.lastVisit ?? DateTime.now(),
        visitCount: widget.initialData?.visitCount ?? 0,
        referredBy: data['referredBy'],
        treatmentNotes: widget.initialData?.treatmentNotes ?? [],
      );

      // Llamar al callback para guardar el cliente
      widget.onSave(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      initialValue: widget.initialData != null
          ? {
              // Información personal
              'firstName': widget.initialData!.personalInfo.firstName,
              'lastName': widget.initialData!.personalInfo.lastName,
              'idNumber': widget.initialData!.personalInfo.idNumber,
              'occupation': widget.initialData!.personalInfo.occupation,
              'gender': widget.initialData!.personalInfo.gender,
              'birthDate': widget.initialData!.personalInfo.birthDate,

              // Información de contacto
              'email': widget.initialData!.contactInfo.email,
              'phone': widget.initialData!.contactInfo.phone,
              'address': widget.initialData!.contactInfo.address,

              // Información médica
              'allergies': widget.initialData!.medicalInfo.allergies,
              'respiratory': widget.initialData!.medicalInfo.respiratory,
              'nervousSystem': widget.initialData!.medicalInfo.nervousSystem,
              'diabetes': widget.initialData!.medicalInfo.diabetes,
              'kidney': widget.initialData!.medicalInfo.kidney,
              'digestive': widget.initialData!.medicalInfo.digestive,
              'cardiac': widget.initialData!.medicalInfo.cardiac,
              'thyroid': widget.initialData!.medicalInfo.thyroid,
              'previousSurgeries':
                  widget.initialData!.medicalInfo.previousSurgeries,
              'otherConditions':
                  widget.initialData!.medicalInfo.otherConditions,

              // Información estética
              'productsUsed': widget.initialData!.aestheticInfo.productsUsed,
              'currentTreatments':
                  widget.initialData!.aestheticInfo.currentTreatments,
              'aestheticOther': widget.initialData!.aestheticInfo.other,

              // Hábitos de vida
              'smoker': widget.initialData!.lifestyleInfo.smoker,
              'alcohol': widget.initialData!.lifestyleInfo.alcohol,
              'regularPhysicalActivity':
                  widget.initialData!.lifestyleInfo.regularPhysicalActivity,
              'sleepProblems': widget.initialData!.lifestyleInfo.sleepProblems,

              // Motivo de consulta
              'consultationReason': widget.initialData!.consultationReason,

              // Tratamiento facial
              'skinType': widget.initialData!.facialTreatment.skinType,
              'skinCondition':
                  widget.initialData!.facialTreatment.skinCondition,
              'flaccidityDegree':
                  widget.initialData!.facialTreatment.flaccidityDegree,

              // Tratamiento corporal (los campos numéricos se manejan con controladores)
              'celluliteGrade':
                  widget.initialData!.bodyTreatment.cellulite.grade,
              'celluliteLocation':
                  widget.initialData!.bodyTreatment.cellulite.location,

              // Tratamiento de bronceado
              'glasgowScale': widget.initialData!.tanningTreatment.glasgowScale,
              'fitzpatrickScale':
                  widget.initialData!.tanningTreatment.fitzpatrickScale,

              // Tratamientos preferidos
              'preferredTreatments': widget.initialData!.preferredTreatments,

              // Referencia
              'referredBy': widget.initialData!.referredBy,
            }
          : {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navegación por pestañas
          Row(
            children: [
              _buildTabButton('Información Personal', 0),
              _buildTabButton('Historial', 1),
              _buildTabButton('Tratamientos', 2),
              _buildTabButton('Fichas', 3),
            ],
          ),
          const SizedBox(height: 16),

          // Páginas del formulario
          SizedBox(
            height: 500, // Altura fija para las páginas
            child: PageView(
              controller: _tabController,
              onPageChanged: (index) {
                setState(() {
                  _currentTab = index;
                });
              },
              children: [
                _buildPersonalInfoForm(),
                _buildHistoryForm(),
                _buildTreatmentsForm(),
                _buildTreatmentSheetsForm(),
              ],
            ),
          ),

          // Botones de navegación
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentTab > 0)
                  TextButton(
                    onPressed: () {
                      _tabController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Anterior'),
                  )
                else
                  const SizedBox(),
                if (_currentTab < 3)
                  ElevatedButton(
                    onPressed: () {
                      _tabController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Siguiente'),
                  )
                else
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Guardar Cliente'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _currentTab == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _currentTab == index
                  ? Theme.of(context).colorScheme.primary
                  : null,
              fontWeight: _currentTab == index ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información personal básica
          const Text(
            'Información Personal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'firstName',
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Campo requerido'),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'lastName',
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Campo requerido'),
                  ]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'idNumber',
                  decoration: const InputDecoration(
                    labelText: 'Cédula *',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Campo requerido'),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'occupation',
                  decoration: const InputDecoration(
                    labelText: 'Ocupación',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FormBuilderDropdown<String>(
                  name: 'gender',
                  decoration: const InputDecoration(
                    labelText: 'Género',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Masculino', child: Text('Masculino')),
                    DropdownMenuItem(
                        value: 'Femenino', child: Text('Femenino')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderDateTimePicker(
                  name: 'birthDate',
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento *',
                    border: OutlineInputBorder(),
                  ),
                  inputType: InputType.date,
                  format: DateFormat('dd/MM/yyyy'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Campo requerido'),
                  ]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Información de contacto
          const Text(
            'Información de Contacto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          FormBuilderTextField(
            name: 'email',
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Campo requerido'),
              FormBuilderValidators.email(
                  errorText: 'Ingrese un correo válido'),
            ]),
          ),

          const SizedBox(height: 16),

          FormBuilderTextField(
            name: 'phone',
            decoration: const InputDecoration(
              labelText: 'Teléfono *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Campo requerido'),
            ]),
          ),

          const SizedBox(height: 16),

          FormBuilderTextField(
            name: 'address',
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          FormBuilderTextField(
            name: 'referredBy',
            decoration: const InputDecoration(
              labelText: 'Referido por',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Historial médico
          const Text(
            'Historial Médico',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              CustomCheckItem(
                name: 'allergies',
                label: 'Alergias',
                initialValue:
                    widget.initialData?.medicalInfo.allergies ?? false,
              ),
              CustomCheckItem(
                name: 'respiratory',
                label: 'Respiratorias',
                initialValue:
                    widget.initialData?.medicalInfo.respiratory ?? false,
              ),
              CustomCheckItem(
                name: 'nervousSystem',
                label: 'Alteraciones Nerviosas',
                initialValue:
                    widget.initialData?.medicalInfo.nervousSystem ?? false,
              ),
              CustomCheckItem(
                name: 'diabetes',
                label: 'Diabetes',
                initialValue: widget.initialData?.medicalInfo.diabetes ?? false,
              ),
              CustomCheckItem(
                name: 'kidney',
                label: 'Renales',
                initialValue: widget.initialData?.medicalInfo.kidney ?? false,
              ),
              CustomCheckItem(
                name: 'digestive',
                label: 'Digestivos',
                initialValue:
                    widget.initialData?.medicalInfo.digestive ?? false,
              ),
              CustomCheckItem(
                name: 'cardiac',
                label: 'Cardíacos',
                initialValue: widget.initialData?.medicalInfo.cardiac ?? false,
              ),
              CustomCheckItem(
                name: 'thyroid',
                label: 'Tiroides',
                initialValue: widget.initialData?.medicalInfo.thyroid ?? false,
              ),
              CustomCheckItem(
                name: 'previousSurgeries',
                label: 'Cirugías Previas',
                initialValue:
                    widget.initialData?.medicalInfo.previousSurgeries ?? false,
              ),
            ],
          ),

          const SizedBox(height: 16),

          FormBuilderTextField(
            name: 'otherConditions',
            decoration: const InputDecoration(
              labelText: 'Otras Condiciones',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 32),

          // Historial estético
          const Text(
            'Historial Estético',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          CustomChipsInput(
            name: 'productsUsed',
            decoration: const InputDecoration(
              labelText: 'Productos Usados',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_bag),
            ),
            initialValue: widget.initialData?.aestheticInfo.productsUsed ?? [],
          ),

          const SizedBox(height: 16),

          CustomChipsInput(
            name: 'currentTreatments',
            decoration: const InputDecoration(
              labelText: 'Tratamientos Actuales',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.spa),
            ),
            initialValue:
                widget.initialData?.aestheticInfo.currentTreatments ?? [],
          ),

          const SizedBox(height: 16),

          FormBuilderTextField(
            name: 'aestheticOther',
            decoration: const InputDecoration(
              labelText: 'Otros',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 32),

          // Hábitos de vida
          const Text(
            'Hábitos de Vida',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              CustomCheckItem(
                name: 'smoker',
                label: 'Fumador',
                initialValue: widget.initialData?.lifestyleInfo.smoker ?? false,
              ),
              CustomCheckItem(
                name: 'alcohol',
                label: 'Consume Alcohol',
                initialValue:
                    widget.initialData?.lifestyleInfo.alcohol ?? false,
              ),
              CustomCheckItem(
                name: 'regularPhysicalActivity',
                label: 'Actividad Física Regular',
                initialValue:
                    widget.initialData?.lifestyleInfo.regularPhysicalActivity ??
                        false,
              ),
              CustomCheckItem(
                name: 'sleepProblems',
                label: 'Problemas de Sueño',
                initialValue:
                    widget.initialData?.lifestyleInfo.sleepProblems ?? false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motivo de consulta
          const Text(
            'Motivo de Consulta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          FormBuilderTextField(
            name: 'consultationReason',
            decoration: const InputDecoration(
              labelText: 'Motivo de Consulta',
              border: OutlineInputBorder(),
              hintText: 'Describa el motivo de la consulta del cliente',
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 32),

          // Tratamientos preferidos
          const Text(
            'Tratamientos Preferidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          FormBuilderCheckboxGroup<String>(
            name: 'preferredTreatments',
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            orientation: OptionsOrientation.vertical,
            options: const [
              FormBuilderFieldOption(value: 'Facial', child: Text('Facial')),
              FormBuilderFieldOption(
                  value: 'Corporal', child: Text('Corporal')),
              FormBuilderFieldOption(
                  value: 'Bronceado', child: Text('Bronceado')),
              FormBuilderFieldOption(value: 'Masaje', child: Text('Masaje')),
              FormBuilderFieldOption(
                  value: 'Manicura/Pedicura', child: Text('Manicura/Pedicura')),
              FormBuilderFieldOption(
                  value: 'Depilación', child: Text('Depilación')),
            ],
          ),

          const SizedBox(height: 16),

          // Selección de fichas a mostrar
          const Text(
            'Fichas de Tratamiento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Ficha Facial'),
            value: _showFacialTreatment,
            onChanged: (value) {
              setState(() {
                _showFacialTreatment = value ?? false;
              });
            },
          ),

          CheckboxListTile(
            title: const Text('Ficha Corporal'),
            value: _showBodyTreatment,
            onChanged: (value) {
              setState(() {
                _showBodyTreatment = value ?? false;
              });
            },
          ),

          CheckboxListTile(
            title: const Text('Ficha de Bronceado'),
            value: _showTanningTreatment,
            onChanged: (value) {
              setState(() {
                _showTanningTreatment = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSheetsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ficha facial
          if (_showFacialTreatment) ...[
            const Text(
              'Ficha Facial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            FormBuilderDropdown<String>(
              name: 'skinType',
              decoration: const InputDecoration(
                labelText: 'Tipo de Piel',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'Seca', child: Text('Seca')),
                DropdownMenuItem(value: 'Grasa', child: Text('Grasa')),
                DropdownMenuItem(value: 'Mixta', child: Text('Mixta')),
                DropdownMenuItem(value: 'Sensible', child: Text('Sensible')),
              ],
            ),

            const SizedBox(height: 16),

            FormBuilderTextField(
              name: 'skinCondition',
              decoration: const InputDecoration(
                labelText: 'Estado de la Piel',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            FormBuilderSlider(
              name: 'flaccidityDegree',
              min: 0,
              max: 5,
              initialValue: widget.initialData?.facialTreatment.flaccidityDegree
                      ?.toDouble() ??
                  0,
              divisions: 5,
              label: 'Grado de Flacidez: {value}',
              decoration: const InputDecoration(
                labelText: 'Grado de Flacidez',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Diagrama facial - Aquí iría un widget personalizado para el diagrama facial
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Diagrama Facial'),
              ),
            ),

            const SizedBox(height: 32),
          ],

          // Ficha corporal
          if (_showBodyTreatment) ...[
            const Text(
              'Ficha Corporal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sección de medidas corporales
            const Text(
              'Medidas (cm)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'highAbdomen',
                    decoration: const InputDecoration(
                      labelText: 'Abdomen Alto',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'lowAbdomen',
                    decoration: const InputDecoration(
                      labelText: 'Abdomen Bajo',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'waist',
                    decoration: const InputDecoration(
                      labelText: 'Cintura',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'back',
                    decoration: const InputDecoration(
                      labelText: 'Espalda',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'leftArm',
                    decoration: const InputDecoration(
                      labelText: 'Brazo Izquierdo',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'rightArm',
                    decoration: const InputDecoration(
                      labelText: 'Brazo Derecho',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de antropometría
            const Text(
              'Antropometría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateBMI(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateBMI(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bmiController,
                    decoration: const InputDecoration(
                      labelText: 'IMC',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _calculateBMI,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calcular IMC'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de patologías
            const Text(
              'Patologías',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            FormBuilderDropdown<int>(
              name: 'celluliteGrade',
              decoration: const InputDecoration(
                labelText: 'Grado de Celulitis',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Grado 1')),
                DropdownMenuItem(value: 2, child: Text('Grado 2')),
                DropdownMenuItem(value: 3, child: Text('Grado 3')),
                DropdownMenuItem(value: 4, child: Text('Grado 4')),
              ],
            ),

            const SizedBox(height: 16),

            FormBuilderTextField(
              name: 'celluliteLocation',
              decoration: const InputDecoration(
                labelText: 'Ubicación de la Celulitis',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Sección de estrías - Aquí iría un widget personalizado para gestionar estrías
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Gestión de Estrías'),
              ),
            ),

            const SizedBox(height: 32),
          ],

          // Ficha de bronceado
          if (_showTanningTreatment) ...[
            const Text(
              'Ficha de Bronceado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FormBuilderSlider(
              name: 'glasgowScale',
              min: 0,
              max: 10,
              initialValue: widget.initialData?.tanningTreatment.glasgowScale
                      ?.toDouble() ??
                  0,
              divisions: 10,
              label: 'Escala de Glasgow: {value}',
              decoration: const InputDecoration(
                labelText: 'Escala de Glasgow',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FormBuilderSlider(
              name: 'fitzpatrickScale',
              min: 1,
              max: 6,
              initialValue: widget
                      .initialData?.tanningTreatment.fitzpatrickScale
                      ?.toDouble() ??
                  1,
              divisions: 5,
              label: 'Escala de Fitzpatrick: {value}',
              decoration: const InputDecoration(
                labelText: 'Escala de Fitzpatrick',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
