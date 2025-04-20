```
  --->      @@@@@   @@@@  @@@@@  @@@@@@  @@@@   @@@@  @@@@@@ 
       -->  @@  @@ @@  @@ @@  @@ @@     @@  @@ @@       @@   
    -->     @@@@@  @@@@@@ @@@@@  @@@@   @@@@@@  @@@@    @@   
  -->       @@     @@  @@ @@  @@ @@     @@  @@     @@   @@   
      -->   @@     @@  @@ @@  @@ @@     @@  @@  @@@@    @@   
```
A stack oriented language that targets x86_64 assembly.

# Supported assemblers

- Nasm (default)

- Fasm

# Quickstart

for more detailed overview and demonstrations of the syntax, check [quickstart](Quickstart.md)

compile file:

```console
$ lua parfast <input.parfast> -com
  [1/2] nasm -f elf64 input.parfast
  [2/2] ld -o input input.o
```
Or alternatively
```console
$ ./parfast <input.parfast> -com
Commands:
  [1/2] nasm -f elf64 input.parfast
  [2/2] ld -o input input.o
```

# Compiling the compiler

Required tools:

  - luac

  - GNU make

In linux, just run `make` and it will procude a file named `parfast` which is the compiler. But unfortunately it won't work well on Windows.

# Todos

- [X] type-checking

- [X] better error handling

- [X] multi assembler support

- [ ] stability

- [ ] self hosting (probably never XD)