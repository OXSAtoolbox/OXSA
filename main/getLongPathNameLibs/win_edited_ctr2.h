#include <limits.h>
#include <stdarg.h>

typedef unsigned long DWORD;
#define STDCALL	__stdcall
typedef const unsigned short *LPCWSTR;
typedef unsigned short *LPWSTR;
typedef const char *LPCSTR;
typedef char *LPSTR;

DWORD STDCALL GetFullPathNameW(LPCWSTR,DWORD,LPWSTR,LPWSTR *);
DWORD STDCALL GetFullPathNameA(LPCSTR,DWORD,LPSTR,LPSTR *);

/*
WINBASEAPI
DWORD
WINAPI
GetLongPathNameW(
    __in LPCWSTR lpszShortPath,
    __out_ecount_part_opt(cchBuffer, return + 1) LPWSTR  lpszLongPath,
    __in DWORD cchBuffer
    );
*/

DWORD STDCALL GetLongPathNameW(LPCWSTR,LPWSTR,DWORD);
