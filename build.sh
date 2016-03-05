STACKER="./stacker"
# Check if rr is installed, and run stacker under rr if it is
if type rr >/dev/null 2>&1; then
    echo '-- rr enabled --'
    STACKER="rr $STACKER"
fi

set -e
set -x
nasm -f elf64 -o stacker.o stacker.asm
ld -o stacker stacker.o
$STACKER < prog.stk > prog
chmod +x prog
objdump -D prog -mi386:x86-64 -b binary --start-address=0x78 -M intel
./prog
