/*
 * DCSim Hooks C Library
 *
 * This file provides a shared library interface for DCSim simulation hooks.
 * It can be compiled and loaded from Python using ctypes.
 */

#include "DCSim.h"

// Export these functions for Python to call
void dcsim_start_roi(void) {
    DCSimStartROI();
}

void dcsim_end_roi(void) {
    DCSimEndROI();
}

void dcsim_start_global_roi(void) {
    DCSimStartGlobalROI();
}

void dcsim_end_global_roi(void) {
    DCSimEndGlobalROI();
}
