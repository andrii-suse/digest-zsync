#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

MODULE = Digest::Zsync::XS  PACKAGE = Digest::Zsync::XS
PROTOTYPES: ENABLE

SV *
rsum06(data, len, x)
  char* data
  size_t len
  size_t x
  PPCODE:
    struct rsum {
        unsigned short a;
        unsigned short b;
    } __attribute__((packed));

    register unsigned short a = 0;
    register unsigned short b = 0;
    while (len) {
        unsigned char c = *data++;
        a += c;
        b += len * c;
        len--;
    }
    struct rsum r = { htons(a), htons(b) };
    char* buffer = (char*)&r;
    PUSHs(sv_2mortal(newSVpv(buffer + 4-x, x)));
    XSRETURN(1);

