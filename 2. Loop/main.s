/********************************************************************************
* main.s: Skriver samtliga heltal 0 - 1023 ett i taget till lysdiodernas
*         basadress LEDS_BASE via en loop. En kort fördröjning genereras mellan
*         varje skrivning. För att hålla programmet enkelt sparas inte värden
*         undan på stacken vid anrop av subrutiner, vilket hade varit med
*         eller mindre nödvändigt ifall programmet var större.
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
* Makrodefinitioner:
********************************************************************************/
.ifdef GPIO_CASE_GOLD_HW
.equ LEDS_BASE, 0x8091740      /* Basadress för lysdioder (CASE GOLD). */
.equ DELAY_CONSTANT, 100000UL  /* Fördröjningskonstant (CASE GOLD). */
.else
.equ LEDS_BASE, 0xFF200000     /* Basadress för lysdioder (simulering). */
.equ DELAY_CONSTANT, 1000000UL /* Fördröjningskonstant (simulering). */
.endif /* GPIO_CASE_GOLD_HW */

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
* delay: Genererar fördröjning genom att räkna upp från 0 till DELAY_CONSTANT
*        via en loop.
********************************************************************************/
delay:
   movhi r5, %hi(DELAY_CONSTANT)    /* Läser in DELAY_CONSTANT[15:8] i r5. */
   addi r5, r5, %lo(DELAY_CONSTANT) /* Lägger till DELAY_CONSTANT[7:0] i r5. */
   movi r6, 0                       /* Tilldelar startvärde för varvräknaren i r6. */
delay_loop:
   beq r5, r6, delay_end            /* Efter DELAY_CONSTANT antal varv avslutas loopen. */
   addi r6, r6, 1                   /* Räknar upp antalet genomförda varv. */
   br delay_loop                    /* Återstartar loopen tills fördröjningen är genomförd. */
delay_end:
   ret                              /* Avslutar subrutinen när fördröjningen är genomförd. */

/********************************************************************************
* main: Skriver samtliga heltal 0 - 1023 till lysdiodernas basadress LEDS_BASE
*       med en kort fördröjning mellan varje skrivning. Efter att samtliga
*       tal har skrivits till LEDS_BASE avslutas subrutinen med returkod 0
*       för att indikera lyckad programexekvering.
********************************************************************************/
main:
   movhi r2, %hi(LEDS_BASE)    /* Läser in LEDS_BASE[31:16] i r2. */
   addi r2, r2, %lo(LEDS_BASE) /* Läser in LEDS_BASE[15:0] i r2. */
   movi r3, 0                  /* Läser in startvärde 0 för loopräknare i r3. */
   movi r4, 1024               /* Läser in loopens slutvärde i r4. */
main_loop:
   beq r3, r4, main_end        /* När 1024 varv har genomförts avslutas loopen. */
   stwio r3, 0(r2)             /* Skriver aktuellt värde i r3 till LEDS_BASE. */
   call delay                  /* Genererar en kort fördröjning inför nästa skrivning. */
   addi r3, r3, 1              /* Räknar upp antalet genomförda varv. */
   br main_loop                /* Återstart loopen tills 1024 varv har genomförts. */
main_end:
   movi r2, 0                  /* Läser in returkod 0 i r2. */
   ret                         /* Genomför återhopp med returkod 0. */
