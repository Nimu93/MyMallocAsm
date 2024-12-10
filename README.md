# MyMallocASM

## Overview
This project implements a custom memory allocator in assembly. It allows allocation and deallocation of memory blocks, managing a memory pool in the form of pages. The allocator supports basic memory operations such as `malloc` (allocation) and `free` (deallocation). The maximum block size that can be allocated is limited to 4096 bytes, and each memory page has a size of 4096 bytes.

## How It Works

### Memory Page
The memory is divided into pages. Each page has a size of 4096 bytes, which includes:

Metadata: The metadata for each page contains the address of the next page (or NULL if there is no next page) and the memory blocks available within the page.
Free Blocks: Each block of memory within a page has its size and a flag indicating whether the block is free or allocated.

### Allocation (mymalloc)

The allocator first checks the first_page pointer to see if there is an existing page.
If no pages are allocated yet, a new page is created.
The allocator searches for a free block within the current page. If no free block is found, it allocates a new page and repeats the process.
If a suitable block is found, it is marked as allocated, and the block's metadata is updated.

### Deallocation (myfree)

The myfree function checks if the pointer is valid and corresponds to an allocated block.
If valid, the block is marked as free, and adjacent free blocks are merged to avoid fragmentation.
If the entire page becomes free, the page is released, and the memory is returned to the system.

### Page Management

Pages are dynamically allocated using the `allocate_new_page` function, which requests memory from the system (via a system call).
When all blocks in a page are freed, the page is released, and memory is reclaimed.

### Limitations

The allocator only supports allocations up to 4096 bytes (the size of one page).
The allocator uses a simple free list mechanism to manage memory, which may lead to fragmentation if memory is not properly reused.
Only 16-byte aligned memory allocations are supported.

### Layouts

```
+-----------------------+
| Page Metadata         |
+-----------------------+
| Block 1               |
+-----------------------+
| Block 2               |
+-----------------------+
| ...                   |
+-----------------------+
| Block N               |
+-----------------------+
| Next Page Pointer     |
+-----------------------+
```

## How to Use

For compiling tests:
`make`

For compiling the lib:
`make lib`

You can for use the lib with:
`LD_PRELOAD=./mylibmalloc.so ls`

## Author

Nimu93 (Valentin)