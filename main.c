//
// main.c  Beablebone Black Interrupt Demo Program
//
// simple, mixed C & assembly
// demonstrates RTC and GPIO usage under interupt control, UND & IRQ
//
// mostly hacked from Al Selen at github/auselen
// & Nick Kondrashov github/spbnick
// & Mattius van Duin, TI e2e forum
//
#include<stdint.h>
#define SOC_GPIO_1_REGS         0x4804c000

extern void und_isr();
extern void irq_isr();
extern void irq_init();
extern void rtc_init();
extern void rtc_irq();
extern uint32_t gpio_init(uint32_t gpio_base_addr, uint32_t gpio_pins);
extern void gpio_on(uint32_t gpio_base_addr, uint32_t gpio_pins);
extern void gpio_off(uint32_t gpio_base_addr, uint32_t gpio_pins);

volatile uint32_t irq_count;
volatile uint32_t hour, min, sec;

void main() {
  uint32_t i = 0, j = 0, old_count, pins;
  pins = 0xf << 21;  // enab USR LEDs, pins 21-24
  gpio_init(SOC_GPIO_1_REGS, pins);
  rtc_init();
  irq_init();
  pins = 0x1 << 21;  // LED USR1 is GPIO1_21, pulse it every interrupt
  old_count = 0;
  irq_count = 0;
  while (1) {
    if(old_count != irq_count) {  // trigger LED on changed irq_count
      old_count = irq_count;
      i++;
      j = 0;
      gpio_on(SOC_GPIO_1_REGS, pins);
      while (j < 200000) j++;
      gpio_off(SOC_GPIO_1_REGS, pins);
    }
  }
}
// finito
