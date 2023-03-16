/********************************************************************************
* gpio.h: Inneh�ller drivrutiner f�r GPIO-enheter i form av lysdioder,
*         slide-switchar samt tryckknappar via strukten gpio samt associerade
*         funktioner.
*
*         Simulera programmet p� f�ljande l�nk:
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
* GPIO_CASE_GOLD_HW: Makro f�r att definiera basadresser f�r CASE GOLD h�rdvara.
*                    Kommentera ut detta makro vid simulering.
********************************************************************************/
#define GPIO_CASE_GOLD_HW

/********************************************************************************
* Basadresser f�r olika valbara in- och utenheter:
********************************************************************************/
#ifdef GPIO_CASE_GOLD_HW
#define GPIO_LEDS_BASE     (volatile uint32_t*)(0x8091740)  /* Basadress f�r lysdioder. */
#define GPIO_SWITCHES_BASE (volatile uint32_t*)(0x8091750)  /* Basadress f�r slide-switchar. */
#define GPIO_BUTTONS_BASE  (volatile uint32_t*)(0x8091760)  /* Basadress f�r tryckknappar. */
#else
#define GPIO_LEDS_BASE     (volatile uint32_t*)(0xFF200000) /* Basadress f�r lysdioder. */
#define GPIO_SWITCHES_BASE (volatile uint32_t*)(0xFF200040) /* Basadress f�r slide-switchar. */
#define GPIO_BUTTONS_BASE  (volatile uint32_t*)(0xFF200050) /* Basadress f�r tryckknappar. */
#endif /* GPIO_CASE_GOLD_HW_ */

/********************************************************************************
* gpio_selection: Enumeration f�r val av GPIO-enhet f�r strukten gpio:
********************************************************************************/
enum gpio_selection
{
   GPIO_SELECTION_LED,    /* Lysdiod. */
   GPIO_SELECTION_SWITCH, /* Slide-switch. */
   GPIO_SELECTION_BUTTON  /* Tryckknapp. */
};

/********************************************************************************
* gpio: Strukt f�r GPIO-enheter i form av lysdioder, slide-switchar och
*       tryckknappar. Basadressen f�r vald enhet sparas f�r enkel
*       skrivning/l�sning.
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
*            Annars returneras 0 efter slutf�rd initiering.
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
*               - val : V�rdet som ska skrivas (0 eller 1).
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
* gpio_read: Returnerar insignalen fr�n refererad GPIO-enhet.
*            Vid h�g insignal returneras true, annars false.
*
*            - self Referens till GPIO-enheten.
********************************************************************************/
static inline bool gpio_read(const struct gpio* self)
{
   return (*(self->base_ptr) & (1 << self->pin));
}

#endif /* GPIO_H_ */
