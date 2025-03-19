// lib/widgets/specialized/treatment_diagrams.dart
import 'package:flutter/material.dart';
import '../../models/client_model.dart';

class FacialDiagram extends StatefulWidget {
  final List<FacialMark> initialMarks;
  final Function(List<FacialMark>) onChanged;

  const FacialDiagram({
    super.key,
    this.initialMarks = const [],
    required this.onChanged,
  });

  @override
  State<FacialDiagram> createState() => _FacialDiagramState();
}

class _FacialDiagramState extends State<FacialDiagram> {
  late List<FacialMark> _marks;
  String _selectedType = 'mark';

  @override
  void initState() {
    super.initState();
    _marks = List.from(widget.initialMarks);
  }

  void _addMark(Offset position) {
    setState(() {
      _marks.add(FacialMark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        position: position,
      ));
    });
    widget.onChanged(_marks);
  }

  void _removeMark(String id) {
    setState(() {
      _marks.removeWhere((mark) => mark.id == id);
    });
    widget.onChanged(_marks);
  }

  void _updateMarkComment(String id, String comment) {
    final index = _marks.indexWhere((mark) => mark.id == id);
    if (index != -1) {
      setState(() {
        _marks[index] = FacialMark(
          id: _marks[index].id,
          type: _marks[index].type,
          position: _marks[index].position,
          comment: comment,
        );
      });
      widget.onChanged(_marks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de tipo de marca
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTypeButton('Marca', 'mark'),
            _buildTypeButton('Eritema', 'erythema'),
            _buildTypeButton('Mancha', 'spot'),
            _buildTypeButton('Lesión', 'injury'),
            _buildTypeButton('Otro', 'other'),
          ],
        ),

        const SizedBox(height: 16),

        // Diagrama facial
        Container(
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Imagen de fondo del rostro
              Center(
                child: Image.asset(
                  'assets/face_diagram.png',
                  width: 250,
                  height: 350,
                  fit: BoxFit.contain,
                ),
              ),

              // Marcas existentes
              ..._marks.map((mark) => Positioned(
                    left: mark.position.dx,
                    top: mark.position.dy,
                    child: GestureDetector(
                      onTap: () => _showMarkDetails(mark),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getMarkColor(mark.type),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: mark.comment.isNotEmpty
                            ? const Icon(Icons.comment,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                  )),

              // Detector de gestos para añadir nuevas marcas
              GestureDetector(
                onTapDown: (details) => _addMark(details.localPosition),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Leyenda
        Wrap(
          spacing: 16,
          children: [
            _buildLegendItem('Marca', _getMarkColor('mark')),
            _buildLegendItem('Eritema', _getMarkColor('erythema')),
            _buildLegendItem('Mancha', _getMarkColor('spot')),
            _buildLegendItem('Lesión', _getMarkColor('injury')),
            _buildLegendItem('Otro', _getMarkColor('other')),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _selectedType == type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedType = type;
            });
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: _getMarkColor(type),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getMarkColor(String type) {
    switch (type) {
      case 'mark':
        return Colors.blue;
      case 'erythema':
        return Colors.red;
      case 'spot':
        return Colors.brown;
      case 'injury':
        return Colors.purple;
      case 'other':
      default:
        return Colors.orange;
    }
  }

  void _showMarkDetails(FacialMark mark) {
    final controller = TextEditingController(text: mark.comment);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detalles de ${_getMarkTypeName(mark.type)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _removeMark(mark.id),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateMarkComment(mark.id, controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String _getMarkTypeName(String type) {
    switch (type) {
      case 'mark':
        return 'Marca';
      case 'erythema':
        return 'Eritema';
      case 'spot':
        return 'Mancha';
      case 'injury':
        return 'Lesión';
      case 'other':
      default:
        return 'Otro';
    }
  }
}
