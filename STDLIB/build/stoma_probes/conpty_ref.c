/* conpty_ref.c -- known-good CONTROL for the STOMA M0 ConPTY probe (measurement instrument,
 * not product code).  Canonical Microsoft recipe, value-form UpdateProcThreadAttribute.
 * Prints: hpc value, CreateProcess result, child exit code, bytes received, marker verdict.
 * Exit 99 = marker seen through the pty; 7 = zero bytes; 8+n = bytes but no marker. */
#include <windows.h>
#include <stdio.h>

int memmem_like(const char *b, DWORD n);

int main(void)
{
    HANDLE inR = NULL, inW = NULL, outR = NULL, outW = NULL;
    if (!CreatePipe(&inR, &inW, NULL, 0))  return 2;
    if (!CreatePipe(&outR, &outW, NULL, 0)) return 2;

    COORD size = { 80, 25 };
    HPCON hpc = NULL;
    HRESULT hr = CreatePseudoConsole(size, inR, outW, 0, &hpc);
    printf("hr=%08lx hpc=%p\n", (unsigned long)hr, (void*)hpc);
    if (hr != S_OK) return 3;

    SIZE_T need = 0;
    InitializeProcThreadAttributeList(NULL, 1, 0, &need);
    LPPROC_THREAD_ATTRIBUTE_LIST attrs =
        (LPPROC_THREAD_ATTRIBUTE_LIST)HeapAlloc(GetProcessHeap(), 0, need);
    if (!attrs || !InitializeProcThreadAttributeList(attrs, 1, 0, &need)) return 4;
    if (!UpdateProcThreadAttribute(attrs, 0, PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE,
                                   hpc, sizeof(HPCON), NULL, NULL)) return 5;

    STARTUPINFOEXA si;
    ZeroMemory(&si, sizeof(si));
    si.StartupInfo.cb = sizeof(STARTUPINFOEXA);
    si.lpAttributeList = attrs;
    /* Windows Terminal's defense: a parent with REDIRECTED stdio has those handles propagated
     * into console children even with bInheritHandles=FALSE; USESTDHANDLES + NULL handles
     * blocks the propagation, and the child's console init then binds stdio to the pty. */
    si.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
    printf("cb=%lu attr_off=%u need=%llu\n",
           (unsigned long)si.StartupInfo.cb,
           (unsigned)((char*)&si.lpAttributeList - (char*)&si),
           (unsigned long long)need);

    PROCESS_INFORMATION pi;
    ZeroMemory(&pi, sizeof(pi));
    char cmd[] = "cmd.exe /c echo HELLOPTY";
    if (!CreateProcessA(NULL, cmd, NULL, NULL, FALSE, EXTENDED_STARTUPINFO_PRESENT,
                        NULL, NULL, &si.StartupInfo, &pi)) {
        printf("CreateProcess FAILED gle=%lu\n", GetLastError());
        return 6;
    }
    CloseHandle(inR);
    CloseHandle(outW);

    static char accbuf[65536];
    DWORD acc = 0;
    int found = 0;

    /* pump: peek-drain up to 3s while child runs, then close pty and drain the tail */
    for (int spin = 0; spin < 120; ++spin) {
        DWORD avail = 0;
        PeekNamedPipe(outR, NULL, 0, NULL, &avail, NULL);
        if (avail > 0) {
            DWORD got = 0;
            if (ReadFile(outR, accbuf + acc, (DWORD)sizeof(accbuf) - acc, &got, NULL) && got)
                acc += got;
        } else {
            DWORD code = 0;
            GetExitCodeProcess(pi.hProcess, &code);
            if (code != STILL_ACTIVE && spin > 40) break;
            Sleep(25);
        }
        if (acc >= 8 && memmem_like(accbuf, acc)) { found = 1; break; }
    }

    WaitForSingleObject(pi.hProcess, 5000);
    DWORD code = 0;
    GetExitCodeProcess(pi.hProcess, &code);
    ClosePseudoConsole(hpc);
    for (int spin = 0; spin < 64; ++spin) {
        DWORD avail = 0, got = 0;
        PeekNamedPipe(outR, NULL, 0, NULL, &avail, NULL);
        if (avail > 0) {
            if (!ReadFile(outR, accbuf + acc, (DWORD)sizeof(accbuf) - acc, &got, NULL) || !got) break;
            acc += got;
        } else Sleep(15);
    }
    if (!found) found = memmem_like(accbuf, acc);

    printf("child=%lu acc=%lu found=%d\n", code, acc, found);
    if (acc && acc < 400) { fwrite("RAW[", 1, 4, stdout); fwrite(accbuf, 1, acc, stdout); fwrite("]\n", 1, 2, stdout); }
    CloseHandle(inW);
    CloseHandle(outR);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return found ? 99 : (acc ? 8 + (int)(acc > 240 ? 240 : acc) : 7);
}

int memmem_like(const char *b, DWORD n)
{
    static const char m[8] = { 'H','E','L','L','O','P','T','Y' };
    if (n < 8) return 0;
    for (DWORD i = 0; i + 8 <= n; ++i) {
        int ok = 1;
        for (int j = 0; j < 8; ++j) if (b[i + j] != m[j]) { ok = 0; break; }
        if (ok) return 1;
    }
    return 0;
}
