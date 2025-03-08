```
  --->      @@@@@   @@@@  @@@@@  @@@@@@  @@@@   @@@@  @@@@@@ 
       -->  @@  @@ @@  @@ @@  @@ @@     @@  @@ @@       @@   
    -->     @@@@@  @@@@@@ @@@@@  @@@@   @@@@@@  @@@@    @@   
  -->       @@     @@  @@ @@  @@ @@     @@  @@     @@   @@   
      -->   @@     @@  @@ @@  @@ @@     @@  @@  @@@@    @@   
```
A forth like language that targets x86_64 assembly.

# Supported assemblers

- Nasm (default)

- Fasm

- Gas (unstable)

# Quickstart

for more detailed overview and demonstrations of the syntax, check [quickstart](Quickstart.md)

compile file:

```console
$ lua parfast.lua <input.parfast> -com
  [1/2] nasm -f elf64 input.parfast
  [2/2] ld -o input input.o
```
Or alternatively
```console
$ ./parfast.lua <input.parfast> -com
Commands:
  [1/2] nasm -f elf64 input.parfast
  [2/2] ld -o input input.o
```

run file:

```console
$ ./parfast.lua <input.parfast> -run
```

# Todos

- [X] type-check

- [X] better error handling

- [ ] multi assembler support

- [ ] stability

- [ ] self hosting (probably never XD)