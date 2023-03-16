/********************************************************************************
* main.c: Demonstration av tändning och släckning av en lysdiod via nedtryckning
*         av en tryckknapp. Lysdiod LED1 ansluts till LED[0] och tryckknapp
*         BUTTON1 ansluts till KEY[0]. Vid nedtryckning av BUTTON1 tänds
*         LED1, annars hålls den släckt.
*
*         Simulera programmet på följande länk:
*         https://cpulator.01xz.net/?sys=nios-de10-lite
*
*         Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW nedan.
********************************************************************************/
#include <stdint.h>
#include <stdbool.h>

/********************************************************************************
* GPIO_CASE_GOLD_HW: Makro för att definiera basadresser för CASE GOLD hårdvara.
*                    Kommentera ut detta makro vid simulering.
********************************************************************************/
#define GPIO_CASE_GOLD_HW

/********************************************************************************
* Makrodefinitioner för basadresser:
********************************************************************************/
#ifdef GPIO_CASE_GOLD_HW
#define LEDS_BASE    (volatile uint32_t*)(0x8091740)  /* Basadress för lysdioder (CASE GOLD). */
#define BUTTONS_BASE (volatile uint32_t*)(0x8091760)  /* Basadress för tryckknappar (CASE GOLD). */
#else
#define LEDS_BASE (volatile uint32_t*)(0xFF200000)    /* Basadress för lysdioder (simulering). */
#define BUTTONS_BASE (volatile uint32_t*)(0xFF200050) /* Basadress för tryckknappar (simulering). */
#endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* Makrodefinitioner för pin-nummer:
********************************************************************************/
#define LED1    0 /* Lysdiod 1 ansluten till pin LED[0]. */
#define BUTTON1 0 /* Tryckknapp 1 ansluten till KEY[0]. */

/********************************************************************************
* Pekare till basadresser:
********************************************************************************/
static volatile uint32_t* const leds_base = LEDS_BASE;       /* Pekar på LEDS_BASE. */
static volatile uint32_t* const buttons_base = BUTTONS_BASE; /* Pekar på BUTTONS_BASE. */

/********************************************************************************
* button_pressed: Indikerar ifall specifik tryckknapp är nedtryckt genom att
*                 returnera 1 (sant) eller 0 (falskt).
*
*                 - pin: Tryckknappens pin-nummer.
********************************************************************************/
static inline bool button_pressed(const uint8_t pin)
{
   return !(bool)(*buttons_base & (1 << pin));
}

/********************************************************************************
* led_on: Tänder lysdiod ansluten till specifierad pin utan att påverka
*         övriga lysdioder.
*
*         - pin: Lysdiodens pin-nummer.
********************************************************************************/
static inline void led_on(const uint8_t pin)
{
   *leds_base |= (1 << pin);
   return;
}


/********************************************************************************
* led_off: Släcker lysdiod ansluten till specifierad pin utan att påverka
*          övriga lysdioder.
*
*          - pin: Lysdiodens pin-nummer.
********************************************************************************/
static inline void led_off(const uint8_t pin)
{
   *leds_base &= ~(1 << pin);
   return;
}

/********************************************************************************
* leds_reset: Släcker samtliga lysdioder.
********************************************************************************/
static inline void leds_reset(void)
{
   *leds_base = 0x00;
   return;
}

/********************************************************************************
* main: Ser till att samtliga lysdioder är släckta vid start. Programmet
*       hålls i gång så länge matningsspänning tillförs. Vid nedtryckning
*       av BUTTON1 tänds LED1, annars hålls den släckt.
********************************************************************************/
int main(void)
{
   leds_reset();

   while (1)
   {
      if (button_pressed(BUTTON1))
      {
         led_on(LED1);
      }
      else
      {
         led_off(LED1);
      }
   }

   return 0;
}



