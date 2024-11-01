```
  --->      @@@@@   @@@@  @@@@@  @@@@@@  @@@@   @@@@  @@@@@@ 
       -->  @@  @@ @@  @@ @@  @@ @@     @@  @@ @@       @@   
    -->     @@@@@  @@@@@@ @@@@@  @@@@   @@@@@@  @@@@    @@   
  -->       @@     @@  @@ @@  @@ @@     @@  @@     @@   @@   
      -->   @@     @@  @@ @@  @@ @@     @@  @@  @@@@    @@   
```
A stack-oriented, reverse polish notated, compiled and forth-like language that targets x86_64 assembly currently.

# Dependencies

- Nasm (dependency because its tested only with it)

# Quickstart

for more detailed overview, check [quickstart](Quickstart.md)

compile file:

```console
$ lua parfast.lua <input.parfast>
Commands:
  [nasm -felf64 <input.asm>]
  [ld -o <input> <input.o>]
```

run file:

```console
$ ./<input>
```

# Todos

- [X] Modularity (include files)

- [ ] self hosting

- [ ] string escape sequence

- [ ] vim and emacs support (probably vs code too)