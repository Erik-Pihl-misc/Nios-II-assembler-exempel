/********************************************************************************
* main.s: Demonstration av strukt f�r skrivning samt l�sning av GPIO-enheter
*         i form av lysdioder, slide-switchar samt tryckknappar.
*
*         Tv� lysdioder led1 - led2 ansluts till LED[0:1], en slide-switch
*         switch1 ansluts till SWITCH[0] och en tryckknapp button1 ansluts
*         till KEY[0]. Polling (avl�sning) sker kontinuerligt av switch1
*         samt button1. Insignalen fr�n switch1 matas direkt till led1.
*         Vid nedtryckning av button1 t�nds led2, annars h�lls led2 sl�ckt.
*
*         Simulera programmet p� f�ljande l�nk:
*         https://cpulator.01xz.net/?sys=nios-de10-lite
*
*         Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW i
*         filen gpio.s.
********************************************************************************/

/********************************************************************************
* .text: Kodsegment, lagringsplats f�r programkoden.
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
* _start: Initierar stackpekaren samt rampekaren vid start (s�tts till 1024).
*         Subrutinen main anropas sedan f�r att k�ra programmet. Efter �terhopp
*         g�rs ingenting genom att programmet f�rs�tts i en tom loop.
********************************************************************************/
_start:
   movi sp, 1024 /* Initierar stackpekaren till adress 1024. */
   mov fp, sp    /* Initerar rampekaren till adress 1024. */
   call main     /* Anropar subrutinen main f�r att k�ra programmet. */
_end:
   br _end       /* G�r ingenting efter �terhopp fr�n subrutinen main. */

/********************************************************************************
* main: Lagrar minne f�r GPIO-enheterna p� stacken, varav led1 b�rjar p� fp - 12,
*       led2 b�rjar p� fp - 24, switch1 b�rjar p� fp - 36 och button1 p� fp - 48.
*       Utrymme ges ocks� �t lagrad �terhoppsadress i ra (b�rjar p� fp + 4)
*       samt rampekarens ordinarie adress (b�rjar p� fp + 0).
********************************************************************************/
main:
   addi sp, sp, -56 /* Ger utrymme f�r nya element p� stacken. */
   stw ra, 52(sp)   /* Lagrar f�rst �terhoppsadressen lagrad i ra. */
   stw fp, 48(sp)   /* Lagrar sedan rampekarens ordinarie adress. */
   addi fp, sp, 48  /* S�tter rampekaren till att peka d�r objekten lagras. */

/********************************************************************************
* main_init_led1: Initierar lysdiod led1 ansluten till LED[0].
********************************************************************************/
main_init_led1:
   addi r2, fp, -12            /* Laddar (start)adressen f�r led1 i r2. */
   movi r3, 0                  /* Laddar lysdiodens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_LED /* Laddar val av GPIO-enhet i r4. */
   call gpio_init              /* Anropar gpio_init f�r att initiera led1. */

/********************************************************************************
* main_init_led2: Initierar lysdiod led2 ansluten till LED[1].
********************************************************************************/
main_init_led2:
   addi r2, fp, -24            /* Laddar (start)adressen f�r led2 i r2. */
   movi r3, 1                  /* Laddar lysdiodens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_LED /* Laddar val av GPIO-enhet i r4. */
   call gpio_init              /* Anropar gpio_init f�r att initiera led2. */

/********************************************************************************
* main_init_switch1: Initierar slide-switch switch1 ansluten till SWITCH[0].
********************************************************************************/
main_init_switch1:
   addi r2, fp, -36               /* Laddar (start)adressen f�r switch1 i r2. */
   movi r3, 0                     /* Laddar slide-switchens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_SWITCH /* Laddar val av GPIO-enhet i r4. */
   call gpio_init                 /* Anropar gpio_init f�r att initiera switch1. */

/********************************************************************************
* main_init_button1: Initierar tryckknapp button1 ansluten till KEY[0].
********************************************************************************/
main_init_button1:
   addi r2, fp, -48               /* Laddar (start)adressen f�r button1 i r2. */
   movi r3, 0                     /* Laddar tryckknappens pin-nummer i r3. */
   movi r4, GPIO_SELECTION_BUTTON /* Laddar val av GPIO-enhet i r4. */
   call gpio_init                 /* Anropar gpio_init f�r att initiera button1. */

/********************************************************************************
* main_loop: Genomf�r kontinuerlig polling (avl�sning) av tryckknapp button1.
*            Vid nedtryckning t�nds lysdiod led2, annars h�lls led2 sl�ckt.
********************************************************************************/
main_loop:
   addi r2, fp, -36 /* Laddar (start)adressen f�r switch1 i r2. */
   call gpio_read   /* L�ser av slide-switchens insignal via anrop av gpio_read. */
   mov r3, r2       /* Kopierar slide-switchens insignal till r3 f�r skrivning till led2. */
   addi r2, fp, -12 /* Laddar (start)adressen f�r led1 i r2. */
   call gpio_write  /* Skriver ny utsignal till led1 via anrop av gpio_write. */

   addi r2, fp, -48 /* Laddar (start)adressen f�r button1 i r2. */
   call gpio_read   /* L�ser av tryckknappens insignal via anrop av gpio_read. */
   movi r3, 1       /* L�ser in 0x01 i r3 f�r invertering av insignalen via XOR. */
   xor r3, r3, r2   /* Inverterar insignalen f�r skrivning till lysdioden. */
   addi r2, fp, -24 /* Laddar (start)adressen f�r led2 i r2. */
   call gpio_write  /* Skriver ny utsignal till led2 via anrop av gpio_write. */
   br main_loop     /* �terstartar loopen.

/********************************************************************************
* main_end: �terst�ller stackpekaren och rampekaren samt genomf�r �terhopp
*           innan subrutinen main avslutas.
********************************************************************************/
main_end:
   ldw fp, 48(sp)  /* �terst�ller rampekaren till startv�rde 1024. */
   ldw ra, 52(sp)  /* L�gger tillbaka utsprunglig �terhoppsadress i ra. */
   addi sp, sp, 56 /* �terst�ller stackpekaren till startv�rde 1024. */
   movi r2, 0      /* Laddar returv�rde 0 i r2. */
   ret             /* Genomf�r �terhopp. */

