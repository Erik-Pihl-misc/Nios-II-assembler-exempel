/********************************************************************************
* main.s: Demonstration av strukt för skrivning samt läsning av GPIO-enheter
*         i form av lysdioder, slide-switchar samt tryckknappar.
*         CASE GOLD hårdvara används.
*
*         Två lysdioder led1 - led2 ansluts till LED[0:1], en slide-switch
*         switch1 ansluts till SWITCH[0] och en tryckknapp button1 ansluts
*         till KEY[0]. Polling (avläsning) sker kontinuerligt av switch1
*         samt button1. Insignalen från switch1 matas direkt till led1.
*         Vid nedtryckning av button1 tänds led2, annars hålls led2 släckt.
*
*         Simulera programmet på följande länk:
*         https://cpulator.01xz.net/?sys=nios-de10-lite
*
*         Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW i
*         filen gpio.h.
********************************************************************************/
#include "gpio.h"

/********************************************************************************
* main: Initierar GPIO-enheterna vid start. Sedan genomförs kontinuerligt
*       polling (avläsning) av tryckknapp button1 samt slide-switch switch1.
*       Lysdiod led1 tilldelas kontinuerligt insignalen från switch1.
*       Vid nedtryckning av button1 tänds lysdiod led2, annars hålls led2 släckt.
********************************************************************************/
int main(void)
{
   struct gpio led1, led2, switch1, button1;

   gpio_init(&led1, 0, GPIO_SELECTION_LED);
   gpio_init(&led2, 1, GPIO_SELECTION_LED);
   gpio_init(&switch1, 0, GPIO_SELECTION_SWITCH);
   gpio_init(&button1, 0, GPIO_SELECTION_BUTTON);

   while (1)
   {
      gpio_write(&led1, gpio_read(&switch1));
      gpio_write(&led2, !gpio_read(&button1));
   }

   return 0;
}

