/********************************************************************************
* gpio.h: Innehåller drivrutiner för GPIO-enheter i form av lysdioder,
*         slide-switchar samt tryckknappar via strukten gpio samt associerade
*         funktioner.
*
*         Simulera programmet på följande länk:
*         https://cpulator.01xz.net/?sys=nios-de10-lite
*
*         Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW nedan.
********************************************************************************/
#ifndef GPIO_H_
#define GPIO_H_

/********************************************************************************
* Inkluderingsdirektiv:
********************************************************************************/
#include <stdint.h>
#include <stdbool.h>

/********************************************************************************
* GPIO_CASE_GOLD_HW: Makro för att definiera basadresser för CASE GOLD hårdvara.
*                    Kommentera ut detta makro vid simulering.
********************************************************************************/
#define GPIO_CASE_GOLD_HW

/********************************************************************************
* Basadresser för olika valbara in- och utenheter:
********************************************************************************/
#ifdef GPIO_CASE_GOLD_HW
#define GPIO_LEDS_BASE     (volatile uint32_t*)(0x8091740)  /* Basadress för lysdioder. */
#define GPIO_SWITCHES_BASE (volatile uint32_t*)(0x8091750)  /* Basadress för slide-switchar. */
#define GPIO_BUTTONS_BASE  (volatile uint32_t*)(0x8091760)  /* Basadress för tryckknappar. */
#else
#define GPIO_LEDS_BASE     (volatile uint32_t*)(0xFF200000) /* Basadress för lysdioder. */
#define GPIO_SWITCHES_BASE (volatile uint32_t*)(0xFF200040) /* Basadress för slide-switchar. */
#define GPIO_BUTTONS_BASE  (volatile uint32_t*)(0xFF200050) /* Basadress för tryckknappar. */
#endif /* GPIO_CASE_GOLD_HW_ */

/********************************************************************************
* gpio_selection: Enumeration för val av GPIO-enhet för strukten gpio:
********************************************************************************/
enum gpio_selection
{
   GPIO_SELECTION_LED,    /* Lysdiod. */
   GPIO_SELECTION_SWITCH, /* Slide-switch. */
   GPIO_SELECTION_BUTTON  /* Tryckknapp. */
};

/********************************************************************************
* gpio: Strukt för GPIO-enheter i form av lysdioder, slide-switchar och
*       tryckknappar. Basadressen för vald enhet sparas för enkel
*       skrivning/läsning.
********************************************************************************/
struct gpio
{
   volatile uint32_t* base_ptr;  /* Pekare till enhetens basadress. */
   enum gpio_selection unit_sel; /* Val av GPIO-enhet. */
   uint8_t pin;                  /* Enhetens pin-nummer. */
};

/********************************************************************************
* gpio_init: Initierar godtycklig GPIO-enhet ansluten till angiven pin.
*            Vid fel sker ingen initiering och felkod 1 returneras.
*            Annars returneras 0 efter slutförd initiering.
*
*            - self    : Referens till GPIO-enheten.
*            - pin     : GPIO-enhetens pin-nummer.
*            - unit_sel: Val av enhet (lysdiod, slide-switch eller tryckknapp).
********************************************************************************/
static int gpio_init(struct gpio* self,
                     const uint8_t pin,
                     const enum gpio_selection unit_sel)
{
   self->pin = pin;
   self->unit_sel = unit_sel;

   if (unit_sel == GPIO_SELECTION_LED)
   {
      self->base_ptr = GPIO_LEDS_BASE;
   }
   else if (unit_sel == GPIO_SELECTION_SWITCH)
   {
      self->base_ptr = GPIO_SWITCHES_BASE;
   }
   else if (unit_sel == GPIO_SELECTION_BUTTON)
   {
      self->base_ptr = GPIO_BUTTONS_BASE;
   }
   else
   {
      return 1;
   }
   return 0;
}

/********************************************************************************
* gpio_write: Skriver utsignal till refererad GPIO-enhet.
*
*               - self: Referens till GPIO-enheten.
*               - val : Värdet som ska skrivas (0 eller 1).
********************************************************************************/
static inline void gpio_write(struct gpio* self,
                              const uint8_t val)
{
   if (val)
   {
      *(self->base_ptr) |= (1 << self->pin);
   }
   else
   {
      *(self->base_ptr) &= ~(1 << self->pin);
   }
   return;
}

/********************************************************************************
* gpio_read: Returnerar insignalen från refererad GPIO-enhet.
*            Vid hög insignal returneras true, annars false.
*
*            - self Referens till GPIO-enheten.
********************************************************************************/
static inline bool gpio_read(const struct gpio* self)
{
   return (*(self->base_ptr) & (1 << self->pin));
}

#endif /* GPIO_H_ */
