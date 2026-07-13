import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final bool autoFocus;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Buscar...',
    required this.onSearch,
    this.onClear,
    this.autoFocus = false,
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // --- ESTADO ---
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  // --- LÓGICA ---

  void _onTextChanged() {
    setState(() => _hasText = _controller.text.isNotEmpty);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    if (widget.onClear != null) widget.onClear!();
    FocusScope.of(context).unfocus();
  }

  // --- INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchTextField(),
            const SizedBox(height: 12),
            _buildSubmitButton(),
            _buildActiveFilterIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.manage_search_rounded, color: Colors.orange, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          'BÚSQUEDA DE OBRAS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _controller,
      autofocus: widget.autoFocus,
      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: const Color(0xFF10121D), // Fondo más oscuro para el input
        prefixIcon: const Icon(Icons.search, color: Colors.orange, size: 22),
        suffixIcon: _hasText
            ? IconButton(
          icon: const Icon(Icons.cancel, color: Colors.white54, size: 22),
          onPressed: _clearSearch,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      onChanged: widget.onSearch,
      onSubmitted: (value) {
        widget.onSearch(value);
        FocusScope.of(context).unfocus();
      },
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onSearch(_controller.text);
          FocusScope.of(context).unfocus();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'APLICAR BÚSQUEDA',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildActiveFilterIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _hasText
          ? Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Filtrando por: "${_controller.text}"',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}