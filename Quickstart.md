# 1. Basics

Parfast as a stack-oriented, reverse polish notated and forth-like, is a bit complex initially, but with a bit of patience, it can be more readable.

## Push and drop

These two operations are basically opposite, so take a look

### Push

a value can be pushed to the stack by simple typing it.
```pascal
    10
    "hello world"
```

and a value can also be drop from the stack

```pascal
    10 drop // now the stack is empty
```

## Add and sub (+, -)

### add(+)

It simply performs an addition to the last two values of the stack.

### sub(-)

Performs a subtraction to the last two values of the stack.

```pascal
    34 14 + // 48
    23 - // 25
```

## Dup and Puts

### Dup

Duplicates the last value from the stack.

### Puts

Prints the last value from the stack (mostly a debug function)

```pascal
    10 dup // [10 10]
    puts puts // output: 10 10 stack: [ ]
```

## Greater and Less

### Greater

Performs x > y on the last two elements of the stack.

### Less

performs x < y on the last two elements of the stack.

```pascal
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


```pascal
    10 10 == // stack: [1 ]
    10 10 != // stack: [1 0 ]
    
    32 31 != // stack: [1 ]
    31 32 == // stack: [1 0 ]
```

# 2. Blocks

## if-else


```pascal
10 10 + 20 ==
if
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


```pascal
    //macro <name>
    //    <body>
    //end
    
    macro print
        dup 1 1 syswrite // prints last string of the stack.
    end
```

# 3. misc operands

## swap

Swap two elements from the stack

```pascal
    32
    12
    // stack: [32 12]
    
    swap // stack: [12 32]
```

## mbuf

While not a operand itself, but a way to access the memory buffer. (currently experimental)

## ld

Load a byte at mbuf.

```

mbuf <index> + ld

```

## st

Stores a byte in mbuf

```

mbuf <index> + <value> st

```

## sys

Calls the kernel, currently only syswrite.


```pascal
    "hello world" 1 1 syswrite // msg len will be pushed automatically, msg, stream, arg
```

## include

Includes a file to your main file.

```pascal
include "std.parfast"

"hello world" print
```
