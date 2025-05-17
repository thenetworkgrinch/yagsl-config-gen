import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInputField extends StatefulWidget {
  final String label;
  final double value;
  final Function(double) onChanged;
  final bool isInteger;
  final double min;
  final double max;
  final int decimalPlaces;

  const NumberInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isInteger = false,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
    this.decimalPlaces = 3,
  });

  @override
  State<NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<NumberInputField> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isInteger 
          ? widget.value.toInt().toString() 
          : widget.value.toStringAsFixed(widget.decimalPlaces),
    );
  }
  
  @override
  void didUpdateWidget(NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.isInteger 
          ? widget.value.toInt().toString() 
          : widget.value.toStringAsFixed(widget.decimalPlaces);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleValueChanged(String text) {
    if (text.isEmpty) {
      return;
    }
    
    try {
      double value = double.parse(text);
      
      // Clamp value to min/max
      value = value.clamp(widget.min, widget.max);
      
      // Convert to integer if needed
      if (widget.isInteger) {
        value = value.roundToDouble();
      }
      
      widget.onChanged(value);
    } catch (e) {
      // Invalid number, don't update
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                double step = widget.isInteger ? 1 : 0.1;
                double newValue = widget.value - step;
                if (newValue >= widget.min) {
                  widget.onChanged(newValue);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                double step = widget.isInteger ? 1 : 0.1;
                double newValue = widget.value + step;
                if (newValue <= widget.max) {
                  widget.onChanged(newValue);
                }
              },
            ),
          ],
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(
        decimal: !widget.isInteger,
        signed: true,
      ),
      inputFormatters: [
        // Allow only numbers and decimal point (if not integer)
        widget.isInteger
            ? FilteringTextInputFormatter.digitsOnly
            : FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
      ],
      onChanged: _handleValueChanged,
    );
  }
}
