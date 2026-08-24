#pragma once

#include <stdint.h>

typedef struct {
    char name[32];
    uint64_t bytes_in;
    uint64_t bytes_out;
} IFCounter;

/// Copies 64-bit interface counters via NET_RT_IFLIST2.
/// Returns the number of interfaces written, or -1 on error.
int copy_interface_counters(IFCounter *out, int max_count);
