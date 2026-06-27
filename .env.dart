# Dart VM Options for ELSFM Flutter App
#
# Workaround for Dart 3.12.x JIT compiler crash on macOS (Dart Issue #57719)
# The --use-slow-path flag disables aggressive JIT optimizations that cause
# bus errors in the VM's optimization pass.
#
# Set this before running flutter commands:
#   export DART_VM_OPTIONS="--use-slow-path"
#   flutter run
#
# Or add to your shell rc file:
#   export DART_VM_OPTIONS="--use-slow-path"

DART_VM_OPTIONS="--use-slow-path"
