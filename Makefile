#  Makefile
#
# CROSSCOMPILE = arm-linux-gnueabihf-
# arm-none-eabi  toolchain for Windows based compiling
CROSSCOMPILE = arm-none-eabi-

CFLAGS = -mcpu=cortex-a8 -marm -Wall -O2 -nostdlib -nostartfiles -ffreestanding -fstack-usage -Wstack-usage=256

all : rts.elf

startup.o : startup.s
	$(CROSSCOMPILE)as startup.s -o startup.o

main.o : main.c
	$(CROSSCOMPILE)gcc $(CFLAGS) -c main.c -o main.o

irq.o : irq.s
	$(CROSSCOMPILE)gcc $(CFLAGS) -c irq.s -o irq.o

timer.o : timer.s
	$(CROSSCOMPILE)gcc $(CFLAGS) -c timer.s -o timer.o

gpio.o : gpio.s
	$(CROSSCOMPILE)gcc $(CFLAGS) -c gpio.s -o gpio.o

rts.elf : memmap.lds startup.o main.o irq.o timer.o gpio.o
	$(CROSSCOMPILE)ld -o rts.elf -T memmap.lds startup.o main.o irq.o timer.o gpio.o
#	$(CROSSCOMPILE)objcopy rts.elf rts.bin -O srec
# srec format for jtag loading (ie binary format with a short header), above
# binary format for MMC booting, below
	$(CROSSCOMPILE)objcopy rts.elf rts.bin -O binary
	$(CROSSCOMPILE)objdump -M reg-names-raw -D rts.elf > rts.lst

clean :
	-@del *.o *.lst *.elf *.bin *.su
# finito
