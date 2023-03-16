/********************************************************************************
* main.s: Demonstration av tändning och släckning av en lysdiod via nedtryckning
*         av en tryckknapp. Lysdiod LED1 ansluts till LED[0] och tryckknapp
*         BUTTON1 ansluts till KEY[0]. Vid nedtryckning av BUTTON1 tänds
*         LED1, annars hålls den släckt.
*
*         För att hålla programmet enkelt sparas inte värden undan på stacken
*         vid anrop av subrutiner, vilket hade varit med eller mindre nödvändigt
*         ifall programmet var större.
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
.equ LEDS_BASE   , 0x8091740  /* Basadress för lysdioder (CASE GOLD). */
.equ BUTTONS_BASE, 0x8091760  /* Basadress för tryckknappar (CASE GOLD). */
.else
.equ LEDS_BASE   , 0xFF200000 /* Basadress för lysdioder (simulering). */
.equ BUTTONS_BASE, 0xFF200050 /* Basadress för tryckknappar (simulering). */
.endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* Makrodefinitioner för pin-nummer:
********************************************************************************/
.equ LED1   , 0 /* Lysdiod 1 ansluten till pin LED[0]. */
.equ BUTTON1, 0 /* Tryckknapp 1 ansluten till KEY[0]. */

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
* button_pressed: Indikerar ifall specificerad tryckknapp är nedtryckt genom
*                 att returnera 1 (sant) eller 0 (falskt) i r2.
*
*                 - r2: Tryckknappens pin-nummer.
********************************************************************************/
button_pressed:
   movhi r3, %hi(BUTTONS_BASE)    /* Läser in BUTTONS_BASE[31:16] i r3. */
   addi r3, r3, %lo(BUTTONS_BASE) /* Lägger till BUTTONS_BASE[15:0] i r3. */
   movi r4, 0x01                  /* Läser in tal som ska bitskiftas i r4. */
   sll r2, r4, r2                 /* Skiftar tryckknappens pin, lagrar i r2. */
   ldwio r4, 0(r3)                /* Läser insignaler från BUTTONS_BASE. */
   and r4, r4, r2                 /* Maskerar alla bitar förutom tryckknappens i r4. */
   cmpeqi r2, r4, 0               /* Om resterande värde är 0 är knappen nedtryckt. */
   ret                            /* Genomför återhopp. */

/********************************************************************************
* led_on: Tänder lysdiod ansluten till specificerad pin utan att påverka
*         övriga lysdioder.
*
*         - r2: Lysdiodens pin-nummer.
********************************************************************************/
led_on:
   movhi r3, %hi(LEDS_BASE)    /* Läser in LEDS_BASE[31:16] i r3. */
   addi r3, r3, %lo(LEDS_BASE) /* Lägger till LEDS_BASE[15:0] i r3. */
   movi r4, 0x01               /* Läser in tal som ska bitskiftas i r4. */
   sll r2, r4, r2              /* Skiftar lysdiodens pin-nummer, lagrar i r2. */
   ldwio r4, 0(r3)             /* Läser in aktuellt värde från LEDS_BASE. */
   or r4, r4, r2               /* Ettställer lysdiodens pin i hämtat värde. */
   stwio r4, 0(r3)             /* Skriver uppdaterat värde till LEDS_BASE. */
   ret                         /* Genomför återhopp. */

/********************************************************************************
* led_off: Släcker lysdiod ansluten till specificerad pin utan att påverka
*          övriga lysdioder.
*
*          - r2: Lysdiodens pin-nummer.
********************************************************************************/
led_off:
   movhi r3, %hi(LEDS_BASE)    /* Läser in LEDS_BASE[15:8] i r3. */
   addi r3, r3, %lo(LEDS_BASE) /* Lägger till LEDS_BASE[15:0] i r3. */
   movi r4, 0x01               /* Läser in tal som ska bitskiftas i r4. */
   sll r2, r4, r2              /* Skiftar lysdiodens pin-nummer, lagrar i r2. */
   movi r4, -1                 /* Tilldelar -1 till r4 för invertering med XOR. */
   xor r2, r2, r4              /* Inverterar pin-numret för släckning. */
   ldwio r4, 0(r3)             /* Läser in aktuellt värde från LEDS_BASE i r4. */
   and r4, r4, r2              /* Nollställer lysdiodens pin i hämtat värde. */
   stwio r4, 0(r3)             /* Skriver uppdaterat värde till LEDS_BASE. */
   ret                         /* Genomför återhopp. */

/********************************************************************************
* leds_reset: Släcker samtliga lysdioder.
********************************************************************************/
leds_reset:
   movhi r3, %hi(LEDS_BASE)    /* Läser in LEDS_BASE[31:16] i r3. */
   addi r3, r3, %lo(LEDS_BASE) /* Lägger till LEDS_BASE[15:0] i r3. */
   stwio zero, 0(r3)           /* Nollställer lysdioderna för släckning. */
   ret                         /* Genomför återhopp. */

/********************************************************************************
* main: Ser till att samtliga lysdioder är släckta vid start. Programmet
*       hålls igång så länge matningsspänning tillförs. Vid nedtryckning
*       av BUTTON1 tänds LED1, annars hålls den släckt.
********************************************************************************/
main:
   call leds_reset            /* Släcker samtliga lysdioder vid start. */
main_loop:
   movi r2, BUTTON1           /* Läser in pin-numret för BUTTON1 i r2. */
   call button_pressed        /* Kontrollerar ifall BUTTON1 är nedtryckt. */
   mov r4, r2                 /* Flyttar returvärdet till r4 för senare läsning. */
   movi r2, LED1              /* Läser in pin-numret för LED1 i r2. */
   bne r4, zero, main_led1_on /* Om BUTTON1 är nedtryckt tänds LED1. */
main_led1_off:
   call led_off               /* Släcker LED1. */
   br main_loop               /* Återstartar loopen. */
main_led1_on:
   call led_on                /* Tänder LED1. */
   br main_loop               /* Återstartar loopen. */
