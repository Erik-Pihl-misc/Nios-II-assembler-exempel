/********************************************************************************
* main.s: Demonstration av pekare till lokala variabler, som lagras på stacken
*         tillsammans med returadresser samt rampekarens adress.
*         Två heltal 3 och 4 tilldelas till två variabler via pekare. Summan
*         av dessa tal skrivs till lysdiodernas basadress LEDS_BASE.
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
   mov fp, sp    /* Initerar rampekaren till adress 1024. */
   call main     /* Anropar subrutinen main för att köra programmet. */
_end:
   br _end       /* Gör ingenting efter återhopp från subrutinen main. */

/********************************************************************************
* assign: Tilldelar heltal 3 och 4 till refererade heltalsvariabler.
*         Innehållet i register r4 sparas undan på stacken under användning
*         och återställs innan subrutinen avslutas så att innehållet inte
*         förloras via överskrivning.
*
*         - r2: Referens till den första variabeln.
*         - r3: Referens till den andra variabeln.
********************************************************************************/
assign:
   addi sp, sp, -4 /* Allokerar minne för att spara undan innehåll från r4. */
   stw r4, 0(sp)   /* Sparar undan befintligt värde i r4 inför lokal användning. */
   movi r4, 3      /* Laddar heltalet 3 i r4 för skrivning. */
   stw r4, 0(r2)   /* Skriver heltalet 3 till den första variabelns adress. */
   movi r4, 4      /* Laddar heltalet 4 i r4 för skrivning. */
   stw r4, 0(r3)   /* Skriver heltalet 4 till den andra variabelns adress. */
   ldw r4, 0(sp)   /* Återställer r4 efter lokal användning. */
   addi sp, sp, 4  /* Återställer stackpekaren. */
   ret             /* Genomför återhopp efter slutförd tilldelning. */

/********************************************************************************
* add: Returnerar summan av angivna heltal via r2.
*
*      - r2: Värdet av den första variabeln.
*      - r3: Värdet av den andra variabeln.
********************************************************************************/
add:
   add r2, r2, r3 /* Summar de två talen och lagrar resultatet i r2. */
   ret            /* Genomför återhopp efter att summan har beräknats. */

/********************************************************************************
* main: Deklarerar två lokala variabler x och y med startvärde 0 på stacken.
*       Variablernas minnesadresser passeras till subrutinen assign för
*       tilldelning av heltal 3 respektive 4.
*
*       Summan av de två talen beräknas via anrop av subrutinen add.
*       Det returnerade värdet tilldelas till lysdiodernas badadress LEDS_BASE,
*       vilket tänder LED[2:0]. Subrutinen avslutas med returkod 0 i r2 för
*       att indikera lyckad programexekvering.
********************************************************************************/
main:
   addi sp, sp, -16            /* Allokerar minne för nya element på stacken. */
   stw ra, 12(sp)              /* Lagrar returadressen högst upp i det allokerade blocket. */
   stw fp, 8(sp)               /* Lagrar därefter rampekarens aktuella adress. */
   addi fp, sp, 8              /* Sätter rampekaren till att peka högst upp där variablena lagras. */
   stw zero, -4(fp)            /* Tilldelar startvärde 0 till variabel x. */
   stw zero, -8(fp)            /* Tilldelar startvärde 0 till variabel y. */
main_assign:
   addi r2, fp, -4             /* Lagrar adressen för variabel x i r2. */
   addi r3, fp, -8             /* Lagrar adressen för variabel y i r3. */
   call assign                 /* Anropar assign för att tilldela heltal 3 och 4. */
main_add:
   ldw r2, -4(fp)              /* Laddar värdet av variabel x till r2. */
   ldw r3, -8(fp)              /* Laddar värdet av variabel y till r3. */
   call add                    /* Adderar talen x och y, returvärdet skrivs till r2. */
main_write:
   movhi r3, %hi(LEDS_BASE)    /* Läser in LEDS_BASE[31:16] i r3. */
   addi r3, r3, %lo(LEDS_BASE) /* Lägger till LEDS_BASE[15:0] i r2. */
   stwio r2, 0(r3)             /* Skriver det returnerade värdet i r2 till LEDS_BASE. */
main_end:
   ldw fp, 8(sp)               /* Återställer rampekaren adress. */
   ldw ra, 12(sp)              /* Återställer lagrad returadress. */
   addi sp, sp, 16             /* Återställer stackpekaren. */
   movi r2, 0                  /* Tilldelar returkod 0 till r2. */
   ret                         /* Avslutar programmet med returkod 0. */



