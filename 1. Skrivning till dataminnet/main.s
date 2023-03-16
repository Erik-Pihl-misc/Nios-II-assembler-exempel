/********************************************************************************
* main.s: Tänder lysdioder LED[9:0] via skrivning till lysdiodernas basadress
*         LEDS_BASE.
*
*         Simulera programmet på följande länk:
*         https://cpulator.01xz.net/?sys=nios-de10-lite
*
*         Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW nedan.
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
* GPIO_CASE_GOLD_HW: Makro för att definiera basadresser för CASE GOLD hårdvara.
*                    Kommentera ut detta makro vid simulering.
********************************************************************************/
.equ GPIO_CASE_GOLD_HW, 0

/********************************************************************************
* Makrodefinitioner för basadresser:
********************************************************************************/
.ifdef GPIO_CASE_GOLD_HW
.equ LEDS_BASE, 0x8091740  /* Basadress för lysdioder (CASE GOLD). */
.else
.equ LEDS_BASE, 0xFF200000 /* Basadress för lysdioder (simulering). */
.endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* _start: Initierar stackpekaren samt rampekaren vid start (sätts till 1024).
*         Subrutinen main anropas sedan för att köra programmet. Efter återhopp
*         görs ingenting genom att programmet försätts i en tom loop.
********************************************************************************/
_start:
   movi sp, 1024 /* Initierar stackpekaren till adress 1024. */
   mov fp, sp    /* Initierar rampekaren till adress 1024. */
   call main     /* Anropar subrutinen main för att köra programmet. */
_end:
   br _end       /* Gör ingenting efter återhopp från subrutinen main. */

/********************************************************************************
* main: Tänder LED[9:0] via skrivning till lysdiodernas basadress LEDS_BASE.
*       Efter skrivning returneras heltalet 0 för att indikera lyckad
*       programexekvering.
********************************************************************************/
main:
   movhi r2, %hi(LEDS_BASE)    /* Läser in LEDS_BASE[31:16] i r2. */
   addi r2, r2, %lo(LEDS_BASE) /* Lägger till LEDS_BASE[15:0] i r2. */
   movi r3, 1023               /* Läser in värdet 1023 i r3. */
   stwio r3, 0(r2)             /* Skriver värdet 1023 till lysdiodernas basadress. */
   movi r2, 0                  /* Laddar returkod 0 i r2. */
   ret                         /* Genomför återhopp med returkod 0. */
