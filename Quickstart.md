# 1. Basics

Parfast as a stack-oriented and also a reverse polish notated language is a bit complex initially, but with a bit of pratice, it can be more readable.

## Push and drop

These two operations are basically opposite, so take a look

### Push

a value can be pushed to the stack by simple typing it.
```c
    10
    "hello world"
```

and a value can also be drop from the stack

```c
    10 drop // now the stack is "empty"
```

## Add and sub (+, -)

### add(+)

It simply performs an addition to the last two values of the stack.

### sub(-)

Performs a subtraction to the last two values of the stack.

```c
    34 14 + // 48
    23 - // 25
```

## Dup and Puts

### Dup

Duplicates the last value from the stack.

### Puts

Prints the last value from the stack (mostly a debug function)

```c
    10 dup // [10 10]
    puts puts // output: 10 10 stack: [ ]
```

## Greater and Less

### Greater

Performs x > y on the last two elements of the stack.

### Less

performs x < y on the last two elements of the stack.

```c
    10 19 < // stack: [1 ]
    19 10 < // stack: [1 0 ]
    
    32 12 > // stack: [1 ]
    12 32 > // stack: [1 0]
```

## Equal and Not Equal

### Equal

Performs x == y on the last two elements of the stack.

### Not Equal

Performs x != y on the last two elements of the stack.


```c
    10 10 == // stack: [1 ]
    10 10 != // stack: [1 0 ]
    
    32 31 != // stack: [1 ]
    31 32 == // stack: [1 0 ]
```

# 2. Blocks

## if-else


```pascal

if 10 10 + 20 == then
    1 puts
else
    0 puts
end

// if (10 + 10) == 20 then print(1) else print(0)

```

## while do


```pascal
1 // counter
while dup 11 < do
    dup puts // duplicate the counter and print
    
    1 + // increment the counter
end

// counting from 1 to 10
```

## macros

You can define a macro by just doing this:

**macros are part of the language as it don't have any preprocessor**

```pascal
    //macro <name>
    //    <body>
    //endm
    
    macro print
        1 1 syswrite // prints last string of the stack.
    endm
```

## functions

Functions are basically macros, but they expand once and then can only be called.

```pascal
  // declaring the function
  fn <name> <args> with
    <body>
  end

  // calling the function
  <arguments> <fn-name>
```

## bindings

bindings are temporary aliases you put at **n** elements on the stack.

```pascal
  fn chop-str2 int str int str with // count1 str1 count2 str2
    bind c1 s1 c2 s2 in
    // now "abc" has a name and is s1
    // and "def" has a name and is s2
      c1 1 -
      s1 1 +
      c2 1 -
      s2 1 +
    end
  end

  "abc" "def" chop-str2
  // now the stack is: c1 - 1, s1 + 1, c2 - 1, s2 + 1
```

# 3. stack operations, memory management, modularity and system calls

## swap

Swap two elements from the stack

```c
    32
    12
    // stack: [32 12]
    
    swap // stack: [12 32]
```

## ld

Dereference a pointer on the top of the stack
but in 8 bits.

```

ptr ld

```

## st

Stores a byte in a memory buffer or any other pointer.

```

ptr <index> + <value> st

```

## rst

Same as [st](#st) but 64 bits.

## rld

Same as [ld](#ld) but 64 in bits.

## mem

mem blocks create memory regions based on a global memory buffer called `mbuf` that grows as the program requires memory.

```pascal
  mem u64-buffer
    sizeof-u64 800 *
  end
```

## casts

`castptr`, `caststr`, `castbool` and `castint` are keywords to help the typechecker for example,
in case you use a syscall that returns a pointer instead of an integer, you could use castptr
if it returns a string, caststr and so one so far.

Here's a use case of a cast:
```c
include "std.parfast"

macro mmap_prot 3 endm
macro mmap_flags 34 endm
macro map_failed -1 endm

// simple functions to allocate and free memory

fn my_alloc int with
  bind size in
    // use the mmap syscall
    0 -1 mmap_flags mmap_prot size 0 9 syscall6 castptr
  end
end

fn my_free int ptr with
  bind size ptr in
    // use the munmap syscall
    size ptr 11 syscall2 drop
  end
end

fn main with
  12 my_alloc // allocate 12 bytes

  bind ptr in
    // check if mmap returned an error
    if ptr rld -1 != then
      "Returned a pointer!\n" print
      12 ptr my_free // free the pointer
      0 exit
    else
      "Returned null.\n" print
      1 exit
    end
  end
end
```

## syscalls

Calls the kernel, the syscalls are labeled with a number in them, that shows the number of arguments they need for work, E.g. ```syscall4``` accepts four arguments, ```syscall0```, zero arguments. (but all of them need atleast one thing in the stack that will be pushed to the rax register)


```c
    "hello world\n" 1 1 syscall3 // msg len will be pushed automatically, msg, stream, arg
```

## include

Includes an external .parfast file.

```c
include "std.parfast"

"hello world\n" print
```

## rot

Rotate three elements in the stack, for example, 1 2 3 will become 3 2 1.

# 4. unsafe

## extern, call

```c
extern mycfunction // declare as extern

call mycfunction 0 // call mycfunction plus it number of arguments
```

```c
extern printf

"Hello, parfast\n"
call printf 1
```

## inline assembly

the ```asm``` keyword will copy and paste the string at its front and pass to the final .asm file.

```asm
asm
|  mov rax, 60
   xor rdi, rdi
   syscall|
```