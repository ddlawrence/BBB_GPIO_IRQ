//
// irq.s  Interrupt Routines
//
.syntax unified
.data
SOC_AINTC_REGS          = 0x48200000  // BBB ARM Interrupt Controller base address
INTC_SYSCONFIG          = 0x10
INTC_SYSSTATUS          = 0x14
INTC_SIR_IRQ            = 0x40
INTC_CONTROL            = 0x48
INTC_MIR_CLEAR1         = 0xA8
INTC_MIR_CLEAR2         = 0xC8

.text
//
// ARM interrupt controller init
//
.global irq_init
irq_init:
    r_base .req r0
    ldr r_base, =SOC_AINTC_REGS
    mov r1, 0x2
    str r1, [r_base, INTC_SYSCONFIG]   // soft reset AINT controller spruh73l 6.5.1.2
1:  ldr	r1, [r_base, INTC_SYSSTATUS]   // (not really necessary)
    and r1, r1, 0x1
    cmp	r1, 0x1                        // test for reset complete spruh73l 6.5.1.3
    bne	1b

    mov r1, 0x1                     // unmask/clear interrupt masks spruh73l 6.2.1 & 6.3
    str r1, [r_base, INTC_MIR_CLEAR1]    // INTC_MIR_CLEAR1 #32 GPIOINT2A (for GPIOIRQ0)
    mov r1, 0x1 << 11
    str r1, [r_base, INTC_MIR_CLEAR2]    // INTC_MIR_CLEAR2 #75 RTCINT

// spruh73l 26.1.3.2 default boot procedure uses address 0x4030CE00
// for base of RAM exception vectors.  see table 26.3 for vector addresses
    ldr r_base, =0x4030CE24   // register UND in interrupt vector
    ldr r1, =und_isr
    str r1, [r_base]
    ldr r_base, =0x4030CE38   // register IRQ in interrupt vector
    ldr r1, =irq_isr
    str r1, [r_base]

    mrs r1, cpsr
    bic r1, r1, #0x80  // enable IQR, ie unmask IRQ bit of cpsr
    msr cpsr_c, r1     // 9.2.3.1 & fig 2.3 ARM System Developer’s Guide, Sloss et al

    bx lr
    .unreq r_base

//
// UNDefined interrupt service routine
//
.global und_isr
und_isr:
    SRSFD sp!, #0x1B
    RFEFD sp!

//
// IRQ interrupt service routine
//
// hacked from Al Selen at github/auselen
//
.global irq_isr
irq_isr:
    stmfd sp!, {r0-r3, r11, lr}
    mrs r11, spsr

    ldr r0, =SOC_AINTC_REGS
    ldr r1, [r0, INTC_SIR_IRQ]  // fetch the SIR_IRQ register spruh73l 6.2.2 & 6.5.1.4
    mvn r2, #0x7f
    tst r1, r2                  // test for reset/IRQ 0 == do nothing
    beq 1f
    b irq_isr_exit
1:
    AND r1, r1, #0x7f           // strip out active IRQ number
    tst r1, #32                 // test for IRQ 32 == GPIOINT2A
    beq 1f
    bl gpio_isr
    b irq_isr_exit
1:
    tst r1, #75                 // test for IRQ 75 == RTCINT
    beq 1f
    bl rtc_isr
1:
irq_isr_exit:
    ldr r0, =SOC_AINTC_REGS
    ldr r1, =0x1                // NewIRQAgr bit, reset IRQ output and enable new IRQ
    str r1, [r0, INTC_CONTROL]  // spruh73l 6.2.2 & 6.5.1.6
    msr spsr, r11
    ldmfd sp!, {r0-r3, r11, lr}
    subs pc, lr, #4
// finito
