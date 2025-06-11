// Interface for ViewModels that need state cleanup
abstract class StateClearable {
  /// Clear all state, cancel subscriptions, and reset to initial state
  Future<void> clearState();
}
