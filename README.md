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

- [ ] stability

- [ ] better error handling

- [ ] self hosting (probably never XD)