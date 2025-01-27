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
  fn <name>
    <body>
  end

  // calling the function
  <arguments> <fn-name>
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

Load a byte at a memory buffer. It can also dereference a pointer.

```

ptr <index> + ld

```

## st

Stores a byte in a memory buffer or any other pointer.

```

ptr <index> + <value> st

```

## rst

Same as [st](#st) but 64 bits.

## rld

Same as [ld](#ld) but 64 bits.

## mem

mem blocks create memory regions based on a global memory buffer called `mbuf` that grows as the program requires memory.

```pascal
  mem u64-buffer
    sizeof-u64 800 *
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

rotate the stack in this order: c, b, a (stored as a, b, c in the stack), output is: c, a, b

# 4. Calling C from parfast (extremely unstable)

```c
extern mycfunction // declare as extern

call mycfunction 0 // call mycfunction plus it number of arguments
```

```c
extern printf

"Hello, parfast\n"
call printf 1
```