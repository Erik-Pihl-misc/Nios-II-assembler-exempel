/********************************************************************************
* main.c: Demonstration av pekare till lokala variabler, som lagras på stacken
*         tillsammans med returadresser samt rampekarens adress.
*         Två heltal 3 och 4 tilldelas till två variabler via pekare. Summan
*         av dessa tal skrivs till lysdiodernas basadress LEDS_BASE.
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
#define LEDS_BASE    (volatile uint32_t*)(0x8091740)  /* Basadress för lysdioder (CASE GOLD). */
#else
#define LEDS_BASE (volatile uint32_t*)(0xFF200000)    /* Basadress för lysdioder (simulering). */
#endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* Pekare till basadresser:
********************************************************************************/
static volatile uint32_t* const leds_base = LEDS_BASE; /* Pekar på LEDS_BASE. */

/********************************************************************************
* assign: Tilldelar heltal 3 och 4 till refererade heltalsvariabler.
*
*         - x: Referens till den första variabeln.
*         - y: Referens till den andra variabeln.
********************************************************************************/
static void assign(uint32_t* x,
                   uint32_t* y)
{
   *x = 3;
   *y = 4;
   return;
}

/********************************************************************************
* add: Returnerar summan av angivna heltal.
*
*      - x: Värdet av den första variabeln.
*      - y: Värdet av den andra variabeln.
********************************************************************************/
static uint32_t add(const uint32_t x,
                    const uint32_t y)
{
   return x + y;
}

/********************************************************************************
* main: Deklarerar tre lokala variabler x, y och z med startvärde 0 på stacken.
*       Minnesadresserna för x och y passeras till subrutinen assign för
*       tilldelning av heltal 3 respektive 4. Summan av de två talen beräknas
*       via anrop av subrutinen add. Det returnerade värdet tilldelas till
*       lysdiodernas badadress LEDS_BASE, vilket tänder LED[2:0].
********************************************************************************/
int main(void)
{
   uint32_t x = 0;
   uint32_t y = 0;

   assign(&x, &y);
   *leds_base = add(x, y);
   return 0;
}
