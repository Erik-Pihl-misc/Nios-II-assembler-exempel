/********************************************************************************
* main.c: Skriver samtliga heltal 0 - 1023 ett i taget till lysdiodernas
*         basadress LEDS_BASE via en loop. En kort fördröjning genereras mellan
*         varje skrivning.
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
* Makrodefinitioner:
********************************************************************************/
#ifdef GPIO_CASE_GOLD_HW
#define LEDS_BASE (volatile uint32_t*)(0x8091740)  /* Basadress för lysdioder (CASE GOLD). */
#define DELAY_CONSTANT 100000UL                    /* Fördröjningskonstant (CASE GOLD). */
#else
#define LEDS_BASE (volatile uint32_t*)(0xFF200000) /* Basadress för lysdioder (simulering). */
#define DELAY_CONSTANT 1000000UL                   /* Fördröjningskonstant simulering. */
#endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* Pekare till basadresser:
********************************************************************************/
static volatile uint32_t* const leds_base = LEDS_BASE; /* Pekar på LEDS_BASE. */

/********************************************************************************
* delay: Genererar fördröjning genom att räkna upp från 0 till DELAY_CONSTANT
*        via en loop. För att säkerhetsställa att kompilatorn inte slopar
*        uppräkningen (för optimering av koden) används instruktionen
*        nop (no operation) varje varv i loopen.
********************************************************************************/
static inline void delay(void)
{
   for (uint32_t i = 0; i < DELAY_CONSTANT; ++i)
   {
      asm volatile("nop");
   }
   return;
}

/********************************************************************************
* main: Skriver samtliga heltal 0 - 1023 till lysdiodernas basadress LEDS_BASE
*       med en kort fördröjning mellan varje skrivning.
********************************************************************************/
int main(void)
{
   for (uint32_t i = 0; i < 1024; ++i)
   {
      *leds_base = i;
      delay();
   }
   return 0;
}


