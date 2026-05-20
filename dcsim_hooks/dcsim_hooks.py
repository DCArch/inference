"""
DCSim Simulation Hooks for Python

This module provides Python bindings for DCSim simulation hooks.
These hooks insert special NOP instructions that DCSim uses to mark
regions of interest (ROI) for simulation.

Usage:
    import dcsim_hooks

    # For per-thread ROI (FEED C0DE / C0001 0FF)
    dcsim_hooks.start_roi()
    # ... your code ...
    dcsim_hooks.end_roi()

    # For global ROI (FEED BEEF / DEAD BEEF)
    dcsim_hooks.start_global_roi()
    # ... your code ...
    dcsim_hooks.end_global_roi()

Assembly Instructions:
- start_roi():        Inserts NOP with operand FEED C0DE (per-thread)
- end_roi():          Inserts NOP with operand C0001 0FF (per-thread)
- start_global_roi(): Inserts NOP with operand FEED BEEF (global)
- end_global_roi():   Inserts NOP with operand DEAD BEEF (global)
"""

import ctypes
import os
from pathlib import Path

# Find the shared library
_lib_path = Path(__file__).parent / "libdcsim_hooks.so"

if not _lib_path.exists():
    raise FileNotFoundError(
        f"DCSim hooks library not found at {_lib_path}. "
        f"Please build it first by running 'make' in {Path(__file__).parent}"
    )

# Load the shared library
_lib = ctypes.CDLL(str(_lib_path))

# Define function signatures
_lib.dcsim_start_roi.argtypes = []
_lib.dcsim_start_roi.restype = None

_lib.dcsim_end_roi.argtypes = []
_lib.dcsim_end_roi.restype = None

_lib.dcsim_start_global_roi.argtypes = []
_lib.dcsim_start_global_roi.restype = None

_lib.dcsim_end_global_roi.argtypes = []
_lib.dcsim_end_global_roi.restype = None


def start_roi():
    """
    Start per-thread region of interest.
    Inserts NOP instruction with operand FEED C0DE.
    """
    _lib.dcsim_start_roi()


def end_roi():
    """
    End per-thread region of interest.
    Inserts NOP instruction with operand C0001 0FF.
    """
    _lib.dcsim_end_roi()


def start_global_roi():
    """
    Start global region of interest.
    Inserts NOP instruction with operand FEED BEEF.

    Use this for benchmarks where you want to capture simulation
    across all threads/processes.
    """
    _lib.dcsim_start_global_roi()


def end_global_roi():
    """
    End global region of interest.
    Inserts NOP instruction with operand DEAD BEEF.
    """
    _lib.dcsim_end_global_roi()


# Context managers for cleaner code
class ROI:
    """
    Context manager for per-thread region of interest.

    Usage:
        with dcsim_hooks.ROI():
            # Your code here
            pass
    """
    def __enter__(self):
        start_roi()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        end_roi()
        return False


class GlobalROI:
    """
    Context manager for global region of interest.

    Usage:
        with dcsim_hooks.GlobalROI():
            # Your code here
            pass
    """
    def __enter__(self):
        start_global_roi()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        end_global_roi()
        return False


# Convenience exports
__all__ = [
    'start_roi',
    'end_roi',
    'start_global_roi',
    'end_global_roi',
    'ROI',
    'GlobalROI',
]

