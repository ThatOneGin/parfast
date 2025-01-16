```
  --->      @@@@@   @@@@  @@@@@  @@@@@@  @@@@   @@@@  @@@@@@ 
       -->  @@  @@ @@  @@ @@  @@ @@     @@  @@ @@       @@   
    -->     @@@@@  @@@@@@ @@@@@  @@@@   @@@@@@  @@@@    @@   
  -->       @@     @@  @@ @@  @@ @@     @@  @@     @@   @@   
      -->   @@     @@  @@ @@  @@ @@     @@  @@  @@@@    @@   
```
A stack-oriented, reverse polish notated, compiled and forth-like language that targets x86_64 assembly.

# Supported assemblers

- Nasm (default)

- Gas (not fully supported)

# Quickstart

for more detailed overview and demonstrations of the syntax, check [quickstart](Quickstart.md)

compile file:

```console
$ lua parfast.lua <input.parfast> -com
Commands:
  [nasm -felf64 <input.asm>]
  [ld -o <input> <input.o>]
```
Or alternatively
```console
$ ./parfast.lua <input.parfast> -com
Commands:
  [nasm -felf64 <input.asm>]
  [ld -o <input> <input.o>]
```

run file:

```console
$ ./parfast.lua <input.parfast> -run
```

# Todos

- [X] Modularity (include files)

- [ ] self hosting (probably never XD)

- [X] string escape sequence

- [X] vim and emacs support (probably vs code too)