import '../core/utils/logger.dart';

/// Undo/Redo manager
class UndoRedoService<T> {
  final List<T> _undoStack = [];
  final List<T> _redoStack = [];
  final int _maxHistorySize;

  UndoRedoService({int maxHistorySize = 20}) : _maxHistorySize = maxHistorySize;

  /// Push current state to undo stack
  void saveState(T state) {
    _undoStack.add(state);
    _redoStack.clear(); // Clear redo when new action is performed

    // Keep history size manageable
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }

    AppLogger.debug('State saved. Undo stack size: ${_undoStack.length}');
  }

  /// Check if undo is possible
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is possible
  bool get canRedo => _redoStack.isNotEmpty;

  /// Undo to previous state
  T? undo(T currentState) {
    if (!canUndo) {
      AppLogger.warning('Cannot undo: stack is empty');
      return null;
    }

    // Push current state to redo stack
    _redoStack.add(currentState);

    // Pop and return previous state
    final previousState = _undoStack.removeLast();
    AppLogger.info('Undo performed. Stack size: ${_undoStack.length}');
    return previousState;
  }

  /// Redo to next state
  T? redo(T currentState) {
    if (!canRedo) {
      AppLogger.warning('Cannot redo: stack is empty');
      return null;
    }

    // Push current state to undo stack
    _undoStack.add(currentState);

    // Pop and return next state
    final nextState = _redoStack.removeLast();
    AppLogger.info('Redo performed. Redo stack size: ${_redoStack.length}');
    return nextState;
  }

  /// Get current undo stack size
  int get undoStackSize => _undoStack.length;

  /// Get current redo stack size
  int get redoStackSize => _redoStack.length;

  /// Clear all history
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    AppLogger.info('Undo/Redo history cleared');
  }

  /// Get detailed history info
  Map<String, dynamic> getHistoryInfo() {
    return {
      'undoCount': _undoStack.length,
      'redoCount': _redoStack.length,
      'maxSize': _maxHistorySize,
      'canUndo': canUndo,
      'canRedo': canRedo,
    };
  }
}

/// Enhanced version for complex state management
class StateSnapshot<T> {
  final T data;
  final DateTime timestamp;
  final String description;
  final String? tags;

  StateSnapshot({
    required this.data,
    required this.timestamp,
    required this.description,
    this.tags,
  });

  @override
  String toString() => 'StateSnapshot(desc: $description, time: $timestamp)';
}

/// State history manager with snapshots
class HistoryManager<T> {
  final List<StateSnapshot<T>> _history = [];
  int _currentIndex = -1;
  final int _maxHistorySize;

  HistoryManager({int maxHistorySize = 50}) : _maxHistorySize = maxHistorySize;

  /// Save a snapshot
  void snapshot(
    T data, {
    required String description,
    String? tags,
  }) {
    final snap = StateSnapshot(
      data: data,
      timestamp: DateTime.now(),
      description: description,
      tags: tags,
    );

    // Remove redo history after current point
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    _history.add(snap);
    _currentIndex = _history.length - 1;

    // Trim history if needed
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _currentIndex--;
    }

    AppLogger.debug('Snapshot saved: $description');
  }

  /// Go to previous snapshot
  T? undo() {
    if (_currentIndex > 0) {
      _currentIndex--;
      return _history[_currentIndex].data;
    }
    return null;
  }

  /// Go to next snapshot
  T? redo() {
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
      return _history[_currentIndex].data;
    }
    return null;
  }

  /// Get current snapshot
  StateSnapshot<T>? getCurrent() {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      return _history[_currentIndex];
    }
    return null;
  }

  /// Check if can undo
  bool get canUndo => _currentIndex > 0;

  /// Check if can redo
  bool get canRedo => _currentIndex < _history.length - 1;

  /// Get history list
  List<StateSnapshot<T>> getHistory() => List.unmodifiable(_history);

  /// Get history info
  Map<String, dynamic> getInfo() {
    return {
      'totalSnapshots': _history.length,
      'currentIndex': _currentIndex,
      'canUndo': canUndo,
      'canRedo': canRedo,
      'snapshots': _history.map((s) => s.description).toList(),
    };
  }

  /// Clear history
  void clear() {
    _history.clear();
    _currentIndex = -1;
    AppLogger.info('History cleared');
  }

  /// Go to specific snapshot
  T? goToSnapshot(int index) {
    if (index >= 0 && index < _history.length) {
      _currentIndex = index;
      return _history[index].data;
    }
    return null;
  }

  /// Search snapshots by tag
  List<StateSnapshot<T>> searchByTag(String tag) {
    return _history.where((s) => s.tags?.contains(tag) ?? false).toList();
  }

  /// Search snapshots by description
  List<StateSnapshot<T>> searchByDescription(String desc) {
    return _history.where((s) => s.description.contains(desc)).toList();
  }
}

// Required imports
import '../core/utils/logger.dart';
