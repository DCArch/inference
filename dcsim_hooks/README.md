# DCSim Simulation Hooks

This directory contains DCSim simulation hooks for marking regions of interest (ROI) in simulations.

## Files

- **DCSim.h** - C/C++ header with inline assembly hooks
- **dcsim_hooks.c** - C wrapper for Python binding
- **dcsim_hooks.py** - Python module for using hooks
- **libdcsim_hooks.so** - Compiled shared library (generated)
- **Makefile** - Build system

## Hook Types

### Per-Thread ROI
- `DCSimStartROI()` / `start_roi()` - Inserts FEED C0DE
- `DCSimEndROI()` / `end_roi()` - Inserts C0001 0FF

### Global ROI
- `DCSimStartGlobalROI()` / `start_global_roi()` - Inserts FEED BEEF
- `DCSimEndGlobalROI()` / `end_global_roi()` - Inserts DEAD BEEF

## Usage

### C/C++

```c
#include "DCSim.h"

int main() {
    // Load model weights...

    DCSimStartGlobalROI();  // Start simulation

    // Run inference...

    DCSimEndGlobalROI();    // End simulation

    // Cleanup...
    return 0;
}
```

### Python

First, build the shared library:
```bash
cd /work/mewais/DCArch/DCSim/Utils/SimHooks
make
```

Then use in Python:
```python
import sys
sys.path.insert(0, '/work/mewais/DCArch/DCSim/Utils/SimHooks')
import dcsim_hooks

# Method 1: Function calls
dcsim_hooks.start_global_roi()
# ... your code ...
dcsim_hooks.end_global_roi()

# Method 2: Context manager
with dcsim_hooks.GlobalROI():
    # ... your code ...
    pass
```
