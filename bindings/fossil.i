%module fossil

 // We wrap very little yet, just a fragment of Blobs.

%{
#ifdef NORETURN
#undef NORETURN
#endif
#include "src/config.h"
#include "blob.h"
%}

%define NORETURN
%enddef

%ignore blob_vappendf;
%ignore vxprintf;

%include <blob.h>

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
