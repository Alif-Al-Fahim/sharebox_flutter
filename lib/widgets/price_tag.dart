import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final String suffix;
  final double fontSize;
  final bool useGradient;

  const PriceTag({
    super.key,
    required this.price,
    this.suffix = '/day',
    this.fontSize = 16,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = '৳${price.toStringAsFixed(0)}$suffix';

    if (useGradient) {
      return ShaderMask(
        shaderCallback: (bounds) =>
            AppTheme.primaryGradient.createShader(bounds),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: AppTheme.primaryColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class PriceRangeSelector extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final double currentMin;
  final double currentMax;
  final ValueChanged<RangeValues> onChanged;

  const PriceRangeSelector({
    super.key,
    this.minPrice = 0,
    this.maxPrice = 5000,
    required this.currentMin,
    required this.currentMax,
    required this.onChanged,
  });

  @override
  State<PriceRangeSelector> createState() => _PriceRangeSelectorState();
}

class _PriceRangeSelectorState extends State<PriceRangeSelector> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(widget.currentMin, widget.currentMax);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '৳${_values.start.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '৳${_values.end.toStringAsFixed(0)}/day',
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.1),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 8,
            ),
          ),
          child: RangeSlider(
            values: _values,
            min: widget.minPrice,
            max: widget.maxPrice,
            divisions: 100,
            onChanged: (values) {
              setState(() => _values = values);
              widget.onChanged(values);
            },
          ),
        ),
      ],
    );
  }
}
