/********************************************************************************
* main.s: Demonstration av strukt för skrivning samt läsning av GPIO-enheter
*         i form av lysdioder, slide-switchar samt tryckknappar.
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
*         filen gpio.s.
********************************************************************************/

/********************************************************************************
* .text: Kodsegment, lagringsplats för programkoden.
********************************************************************************/
.text

/********************************************************************************
* Globala subrutiner:
********************************************************************************/
.global _start

/********************************************************************************
* Inkluderingsdirektiv:
********************************************************************************/
.include "gpio.s"

/********************************************************************************
* _start: Initierar stackpekaren samt rampekaren vid start (sätts till 1024).
*         Subrutinen main anropas sedan för att köra programmet. Efter återhopp
*         görs ingenting genom att programmet försätts i en tom loop.
********************************************************************************/
_start:
   movi sp, 1024 /* Initierar stackpekaren till adress 1024. */
   mov fp, sp    /* Initerar rampekaren till adress 1024. */
   call main     /* Anropar subrutinen main för att köra programmet. */
_end:
   br _end       /* Gör ingenting efter återhopp från subrutinen main. */

/********************************************************************************
* main: Lagrar minne för GPIO-enheterna på stacken, varav led1 börjar på fp - 12,
*       led2 börjar på fp - 24, switch1 börjar på fp - 36 och button1 på fp - 48.
*       Utrymme ges också åt lagrad återhoppsadress i ra (börjar på fp + 4)
*       samt rampekarens ordinarie adress (börjar på fp + 0).
********************************************************************************/
main:
   addi sp, sp, -56 /* Ger utrymme för nya element på stacken. */
   stw ra, 52(sp)   /* Lagrar först återhoppsadressen lagrad i ra. */
   stw fp, 48(sp)   /* Lagrar sedan rampekarens ordinarie adress. */
   addi fp, sp, 48  /* Sätter rampekaren till att peka där objekten lagras. */

/********************************************************************************
* main_init_led1: Initierar lysdiod led1 ansluten till LED[0].
********************************************************************************/
main_init_led1:
   addi r2, fp, -12            /* Laddar (start)adressen för led1 i r2. */
   movi r3, 0                  /* Laddar lysdiodens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_LED /* Laddar val av GPIO-enhet i r4. */
   call gpio_init              /* Anropar gpio_init för att initiera led1. */

/********************************************************************************
* main_init_led2: Initierar lysdiod led2 ansluten till LED[1].
********************************************************************************/
main_init_led2:
   addi r2, fp, -24            /* Laddar (start)adressen för led2 i r2. */
   movi r3, 1                  /* Laddar lysdiodens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_LED /* Laddar val av GPIO-enhet i r4. */
   call gpio_init              /* Anropar gpio_init för att initiera led2. */

/********************************************************************************
* main_init_switch1: Initierar slide-switch switch1 ansluten till SWITCH[0].
********************************************************************************/
main_init_switch1:
   addi r2, fp, -36               /* Laddar (start)adressen för switch1 i r2. */
   movi r3, 0                     /* Laddar slide-switchens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_SWITCH /* Laddar val av GPIO-enhet i r4. */
   call gpio_init                 /* Anropar gpio_init för att initiera switch1. */

/********************************************************************************
* main_init_button1: Initierar tryckknapp button1 ansluten till KEY[0].
********************************************************************************/
main_init_button1:
   addi r2, fp, -48               /* Laddar (start)adressen för button1 i r2. */
   movi r3, 0                     /* Laddar tryckknappens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_BUTTON /* Laddar val av GPIO-enhet i r4. */
   call gpio_init                 /* Anropar gpio_init för att initiera button1. */

/********************************************************************************
* main_loop: Genomför kontinuerlig polling (avläsning) av tryckknapp button1.
*            Vid nedtryckning tänds lysdiod led2, annars hålls led2 släckt.
********************************************************************************/
main_loop:
   addi r2, fp, -36 /* Laddar (start)adressen för switch1 i r2. */
   call gpio_read   /* Läser av slide-switchens insignal via anrop av gpio_read. */
   mov r3, r2       /* Kopierar slide-switchens insignal till r3 för skrivning till led2. */
   addi r2, fp, -12 /* Laddar (start)adressen för led1 i r2. */
   call gpio_write  /* Skriver ny utsignal till led1 via anrop av gpio_write. */

   addi r2, fp, -48 /* Laddar (start)adressen för button1 i r2. */
   call gpio_read   /* Läser av tryckknappens insignal via anrop av gpio_read. */
   movi r3, 1       /* Läser in 0x01 i r3 för invertering av insignalen via XOR. */
   xor r3, r3, r2   /* Inverterar insignalen för skrivning till lysdioden. */
   addi r2, fp, -24 /* Laddar (start)adressen för led2 i r2. */
   call gpio_write  /* Skriver ny utsignal till led2 via anrop av gpio_write. */
   br main_loop     /* Återstartar loopen.

/********************************************************************************
* main_end: Återställer stackpekaren och rampekaren samt genomför återhopp
*           innan subrutinen main avslutas.
********************************************************************************/
main_end:
   ldw fp, 48(sp)  /* Återställer rampekaren till startvärde 1024. */
   ldw ra, 52(sp)  /* Lägger tillbaka utsprunglig återhoppsadress i ra. */
   addi sp, sp, 56 /* Återställer stackpekaren till startvärde 1024. */
   movi r2, 0      /* Laddar returvärde 0 i r2. */
   ret             /* Genomför återhopp. */

