#include "AM.h"

interface ForceParentInsertion {
    command error_t forceParent(am_addr_t parent);
    command error_t unSetParent();
}
