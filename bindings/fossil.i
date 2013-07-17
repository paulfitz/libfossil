%module fossil

%include <argcargv.i>

 // We wrap very little yet

%{
#ifdef NORETURN
#undef NORETURN
#endif
#include "src/config.h"
#include "src/th.h"
#include "_accum_.h"
%}

%define NORETURN
%enddef

%ignore blob_vappendf;
%ignore vxprintf;
%ignore vmprintf;
%ignore db_vprepare;

// static
%ignore db_sql_trace;
%ignore file_is_selected;
%ignore db_sql_cgi;
%ignore db_sql_print;
%ignore db_sql_user;
%ignore db_open;
%ignore cgi_vprintf;

%include <_accum_.h>

 // Translation may have string leaks, not worried about that yet,
 // just need to add swig decorators to let it know what it should
 // "own"
%extend Blob {
  Blob() {
    Blob *b;
    b = (Blob *) malloc(sizeof(Blob));
    b->nUsed = 0;
    b->nAlloc = 0;
    b->iCursor = 0;
    b->aData = 0;
    b->xRealloc = blobReallocMalloc;
    return b;
  }

  ~Blob() {
    blob_reset($self);
    free($self);
  }

  void fromString(const char *str) {
    blob_set($self,str);
  }

  const char *__str__() {
    return blob_str($self);
  }
}

%apply (int ARGC, char **ARGV) { (int argc, char **argv) } 
%inline {
  int main(int argc, char **argv) {
    return fossil_main(argc,argv);;
  }

  int args(int argc, char **argv) {
    memset(&g, 0, sizeof(g));
    g.now = time(0);
    // doesn't do utf8 stuff
    g.argc = argc;
    g.argv = argv;
    sqlite3_initialize();
    return 0;
  }
}
