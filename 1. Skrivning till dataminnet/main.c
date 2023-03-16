/********************************************************************************
* main.c: Tänder lysdioder LED[9:0] via skrivning till lysdiodernas basadress
*         LEDS_BASE.
*
*         Simulera programmet på följande länk:
*         https://cpulator.01xz.net/?sys=nios-de10-lite
*
*         Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW nedan.
********************************************************************************/
#include <stdint.h>

/********************************************************************************
* GPIO_CASE_GOLD_HW: Makro för att definiera basadresser för CASE GOLD hårdvara.
*                    Kommentera ut detta makro vid simulering.
********************************************************************************/
#define GPIO_CASE_GOLD_HW

/********************************************************************************
* Makrodefinitioner för basadresser:
********************************************************************************/
#ifdef GPIO_CASE_GOLD_HW
#define LEDS_BASE (volatile uint32_t*)(0x8091740)  /* Basadress för lysdioder (CASE GOLD). */
#else
#define LEDS_BASE (volatile uint32_t*)(0xFF200000) /* Basadress för lysdioder (simulering). */
#endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* Pekare till basadresser:
********************************************************************************/
static volatile uint32_t* const leds_base = LEDS_BASE; /* Pekar på LEDS_BASE. */

/********************************************************************************
* main: Tänder LED[9:0] via skrivning till lysdiodernas basadress LEDS_BASE.
*       Efter skrivning returneras heltalet 0 för att indikera lyckad
*       programexekvering.
********************************************************************************/
int main(void)
{
   *leds_base = 1023;
   return 0;
}

