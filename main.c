#include <stdio.h>
#include <stdint.h>

void* mymalloc(size_t size); // Replace the default malloc
void* myfree(void* ptr); // Replace the default free

/*
__attribute__((visibility("default"))) void *malloc(size_t size) {
    return mymalloc(size);
}

__attribute__((visibility("default"))) void free(void *ptr) {
    myfree(ptr);
}*/
