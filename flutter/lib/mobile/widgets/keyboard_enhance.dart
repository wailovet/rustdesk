import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';

/// A translucent text buffer shown on top of the remote screen while the soft
/// keyboard is open.
///
/// Unlike the plain soft keyboard entry, the text is edited locally first and
/// is only forwarded to the remote peer when the user confirms it. Confirmed
/// texts are remembered locally so that they can be reused.
class KeyboardEnhanceBar extends StatefulWidget {
  final FocusNode focusNode;
  final ValueChanged<String> onSendText;
  final VoidCallback onClose;

  const KeyboardEnhanceBar({
    Key? key,
    required this.focusNode,
    required this.onSendText,
    required this.onClose,
  }) : super(key: key);

  @override
  State<KeyboardEnhanceBar> createState() => _KeyboardEnhanceBarState();
}

class _KeyboardEnhanceBarState extends State<KeyboardEnhanceBar> {
  static const _maxHistory = 20;
  static const _backgroundColor = Color(0xCC1A1A1A);
  static const _borderColor = Color(0x33FFFFFF);
  static const _hintColor = Color(0x80FFFFFF);

  final _controller = TextEditingController();
  var _history = <String>[];
  var _showHistory = false;

  @override
  void initState() {
    super.initState();
    _history = _readHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _readHistory() {
    try {
      final raw = bind.getLocalFlutterOption(k: kOptionKeyboardEnhanceHistory);
      if (raw.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<String>()
          .where((e) => e.trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to read enhanced keyboard history: $e');
      return [];
    }
  }

  void _writeHistory() {
    try {
      bind.setLocalFlutterOption(
          k: kOptionKeyboardEnhanceHistory, v: jsonEncode(_history));
    } catch (e) {
      debugPrint('Failed to write enhanced keyboard history: $e');
    }
  }

  void _remember(String text) {
    _history.remove(text);
    _history.insert(0, text);
    if (_history.length > _maxHistory) {
      _history.removeRange(_maxHistory, _history.length);
    }
    _writeHistory();
  }

  void _confirm() {
    final text = _controller.text;
    if (text.isEmpty) {
      return;
    }
    widget.onSendText(text);
    _remember(text);
    _controller.clear();
    setState(() => _showHistory = false);
    // Keep the soft keyboard open for the next entry.
    widget.focusNode.requestFocus();
  }

  void _fillFromHistory(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _showHistory = false);
    widget.focusNode.requestFocus();
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
      _showHistory = false;
    });
    _writeHistory();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputBar(),
          if (_showHistory) _buildHistoryPanel(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: Colors.white,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: translate('Type here and send to remote'),
                    hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                iconSize: 20,
                color: _showHistory ? MyTheme.accent : Colors.white,
                visualDensity: VisualDensity.compact,
                tooltip: translate('History'),
                onPressed: () =>
                    setState(() => _showHistory = !_showHistory),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 20,
                color: Colors.white,
                visualDensity: VisualDensity.compact,
                tooltip: translate('Close'),
                onPressed: widget.onClose,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: Text(translate('Send'),
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: MyTheme.accent80,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      constraints: const BoxConstraints(maxHeight: 168),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: _history.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                translate('No history'),
                style: const TextStyle(color: _hintColor, fontSize: 12),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          translate('History'),
                          style:
                              const TextStyle(color: _hintColor, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearHistory,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(translate('Clear'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return InkWell(
                        onTap: () => _fillFromHistory(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Text(
                            item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
