/* III LEGACY-INGESTION — syscall translation table (closure-pinned at compile-time).
 * Translates Linux x86-64 / Windows / macOS syscalls into substrate cycle kinds. */
#include "iii/legacy.h"
#include <string.h>

typedef struct entry {
    uint32_t                no;
    iii_legacy_cycle_kind_t cycle;
    uint32_t                argc;
    iii_legacy_compromise_t compromise;
    const char             *name;
} entry_t;

/* Linux x86-64 numbers, per Linux kernel arch/x86/entry/syscalls/syscall_64.tbl */
static const entry_t LINUX_X86_64[] = {
    {  0, III_CYC_FS_READ,    3, III_LCT_NONE, "read"    },
    {  1, III_CYC_FS_WRITE,   3, III_LCT_NONE, "write"   },
    {  2, III_CYC_FS_OPEN,    3, III_LCT_NONE, "open"    },
    {  3, III_CYC_FS_CLOSE,   1, III_LCT_NONE, "close"   },
    {  4, III_CYC_FS_STAT,    2, III_LCT_NONE, "stat"    },
    {  8, III_CYC_FS_LSEEK,   3, III_LCT_NONE, "lseek"   },
    {  9, III_CYC_MEM_ALLOC,  6, III_LCT_LOW,  "mmap"    },
    { 10, III_CYC_MEM_PROTECT,3, III_LCT_LOW,  "mprotect"},
    { 11, III_CYC_MEM_FREE,   2, III_LCT_NONE, "munmap"  },
    { 39, III_CYC_PROC_GETPID,0, III_LCT_NONE, "getpid"  },
    { 41, III_CYC_NET_SOCKET, 3, III_LCT_LOW,  "socket"  },
    { 42, III_CYC_NET_CONNECT,3, III_LCT_LOW,  "connect" },
    { 43, III_CYC_NET_BIND,   3, III_LCT_LOW,  "accept"  },
    { 44, III_CYC_NET_SEND,   6, III_LCT_LOW,  "sendto"  },
    { 45, III_CYC_NET_RECV,   6, III_LCT_LOW,  "recvfrom"},
    { 49, III_CYC_NET_BIND,   3, III_LCT_LOW,  "bind"    },
    { 57, III_CYC_PROC_FORK,  0, III_LCT_MEDIUM,"fork"   },
    { 59, III_CYC_PROC_EXEC,  3, III_LCT_MEDIUM,"execve" },
    { 60, III_CYC_PROC_EXIT,  1, III_LCT_NONE, "exit"    },
    { 61, III_CYC_PROC_WAIT,  4, III_LCT_NONE, "wait4"   },
    { 83, III_CYC_FS_MKDIR,   2, III_LCT_NONE, "mkdir"   },
    { 87, III_CYC_FS_UNLINK,  1, III_LCT_NONE, "unlink"  },
    { 96, III_CYC_TIME_NOW,   2, III_LCT_NONE, "gettimeofday" },
    {201, III_CYC_TIME_NOW,   1, III_LCT_NONE, "time"    },
    {231, III_CYC_PROC_EXIT,  1, III_LCT_NONE, "exit_group" },
};

/* Windows NT syscalls (syscall numbers vary across builds; we identify by stable codes
 * specified in this closure-pinned table). Numbers used here are illustrative-stable. */
static const entry_t WINDOWS_X64[] = {
    { 0x0055, III_CYC_FS_OPEN,   3, III_LCT_NONE, "NtCreateFile"  },
    { 0x0006, III_CYC_FS_READ,   9, III_LCT_NONE, "NtReadFile"    },
    { 0x0008, III_CYC_FS_WRITE,  9, III_LCT_NONE, "NtWriteFile"   },
    { 0x000F, III_CYC_FS_CLOSE,  1, III_LCT_NONE, "NtClose"       },
    { 0x0018, III_CYC_MEM_ALLOC, 6, III_LCT_LOW,  "NtAllocateVirtualMemory" },
    { 0x001E, III_CYC_MEM_FREE,  4, III_LCT_NONE, "NtFreeVirtualMemory"     },
    { 0x0050, III_CYC_MEM_PROTECT,5,III_LCT_LOW,  "NtProtectVirtualMemory"  },
    { 0x002C, III_CYC_PROC_EXIT, 2, III_LCT_NONE, "NtTerminateProcess"      },
    { 0x00B2, III_CYC_NET_SOCKET,3, III_LCT_LOW,  "NtCreateSocket"          },
    { 0x004F, III_CYC_TIME_NOW,  1, III_LCT_NONE, "NtQuerySystemTime"       },
};

/* macOS / Darwin BSD syscalls (subset). Numbers per <sys/syscall.h>. */
static const entry_t MACOS[] = {
    {   1, III_CYC_PROC_EXIT,  1, III_LCT_NONE, "exit"   },
    {   2, III_CYC_PROC_FORK,  0, III_LCT_MEDIUM,"fork"  },
    {   3, III_CYC_FS_READ,    3, III_LCT_NONE, "read"   },
    {   4, III_CYC_FS_WRITE,   3, III_LCT_NONE, "write"  },
    {   5, III_CYC_FS_OPEN,    3, III_LCT_NONE, "open"   },
    {   6, III_CYC_FS_CLOSE,   1, III_LCT_NONE, "close"  },
    {  10, III_CYC_FS_UNLINK,  1, III_LCT_NONE, "unlink" },
    {  20, III_CYC_PROC_GETPID,0, III_LCT_NONE, "getpid" },
    {  59, III_CYC_PROC_EXEC,  3, III_LCT_MEDIUM,"execve"},
    {  73, III_CYC_MEM_FREE,   2, III_LCT_NONE, "munmap" },
    {  74, III_CYC_MEM_PROTECT,3, III_LCT_LOW,  "mprotect"},
    {  97, III_CYC_NET_SOCKET, 3, III_LCT_LOW,  "socket" },
    {  98, III_CYC_NET_CONNECT,3, III_LCT_LOW,  "connect"},
    { 104, III_CYC_NET_BIND,   3, III_LCT_LOW,  "bind"   },
    { 133, III_CYC_NET_SEND,   6, III_LCT_LOW,  "sendto" },
    { 197, III_CYC_MEM_ALLOC,  6, III_LCT_LOW,  "mmap"   },
    { 199, III_CYC_FS_LSEEK,   3, III_LCT_NONE, "lseek"  },
    /* Mach traps are negative in Darwin; we represent with high bit. */
    { 0x80000001u, III_CYC_IPC_MSG, 7, III_LCT_LOW, "mach_msg" },
};

static const entry_t *table_for(iii_legacy_os_t os, size_t *out_n) {
    switch (os) {
        case III_LOS_LINUX:   *out_n = sizeof(LINUX_X86_64)/sizeof(LINUX_X86_64[0]); return LINUX_X86_64;
        case III_LOS_WINDOWS: *out_n = sizeof(WINDOWS_X64)/sizeof(WINDOWS_X64[0]);  return WINDOWS_X64;
        case III_LOS_MACOS:   *out_n = sizeof(MACOS)/sizeof(MACOS[0]);              return MACOS;
        default: *out_n = 0; return NULL;
    }
}

size_t iii_legacy_syscall_table_size(iii_legacy_os_t os, iii_legacy_arch_t arch) {
    (void)arch;
    size_t n; (void)table_for(os, &n); return n;
}

iii_legacy_status_t iii_legacy_syscall_translate(
    iii_legacy_os_t os, iii_legacy_arch_t arch,
    uint32_t syscall_no, const uint64_t args[6],
    iii_legacy_syscall_translated_t *out)
{
    (void)arch;
    memset(out, 0, sizeof(*out));
    size_t n;
    const entry_t *t = table_for(os, &n);
    if (!t) {
        out->cycle = III_CYC_UNSUPPORTED;
        out->compromise = III_LCT_LOW;
        strncpy(out->name, "unknown_os", sizeof(out->name) - 1);
        return III_LS_UNSUPPORTED;
    }
    for (size_t i = 0; i < n; i++) {
        if (t[i].no == syscall_no) {
            out->cycle      = t[i].cycle;
            out->arg_count  = t[i].argc;
            out->compromise = t[i].compromise;
            out->supported  = 1;
            strncpy(out->name, t[i].name, sizeof(out->name) - 1);
            for (uint32_t k = 0; k < t[i].argc && k < 6; k++) out->args[k] = args ? args[k] : 0;
            return III_LS_OK;
        }
    }
    /* §9.4 — unsupported syscall: emit ENOSYS-class result. */
    out->cycle = III_CYC_UNSUPPORTED;
    out->compromise = III_LCT_LOW;
    out->supported = 0;
    strncpy(out->name, "unsupported", sizeof(out->name) - 1);
    return III_LS_UNSUPPORTED;
}
