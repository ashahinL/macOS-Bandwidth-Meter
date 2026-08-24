#include "InterfaceCounters.h"

#include <net/if.h>
#include <net/route.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <sys/types.h>

int copy_interface_counters(IFCounter *out, int max_count) {
    if (out == NULL || max_count <= 0) {
        return -1;
    }

    int mib[6] = {CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0};
    size_t len = 0;
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        return -1;
    }

    char *buf = malloc(len);
    if (buf == NULL) {
        return -1;
    }
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        free(buf);
        return -1;
    }

    int count = 0;
    char *lim = buf + len;
    for (char *next = buf; next < lim && count < max_count; ) {
        struct if_msghdr *ifm = (struct if_msghdr *)(void *)next;
        if (ifm->ifm_msglen == 0) {
            break;
        }
        next += ifm->ifm_msglen;
        if (ifm->ifm_type != RTM_IFINFO2) {
            continue;
        }
        struct if_msghdr2 *if2m = (struct if_msghdr2 *)(void *)ifm;
        IFCounter *row = &out[count];
        memset(row, 0, sizeof(*row));
        if_indextoname(if2m->ifm_index, row->name);
        row->bytes_in = if2m->ifm_data.ifi_ibytes;
        row->bytes_out = if2m->ifm_data.ifi_obytes;
        count += 1;
    }

    free(buf);
    return count;
}
