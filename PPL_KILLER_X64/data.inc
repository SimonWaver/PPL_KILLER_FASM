macro CODE {section '.text' code readable executable}

macro DATA {section '.data' readable writeable}

macro IMPORTS {section '.idata' import data readable writeable}
ACTIVE_PROCESS_LINKS_OFFSET = 0x448
UNIQUE_PROCESS_ID_OFFSET    = 0x440