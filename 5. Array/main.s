/********************************************************************************
* main.s: Demonstration av array i Nios II assembler. Samtliga udda tal 1 - 31
*         lagras i en statisk array. Samtliga element lagrade i arrayen hämtas
*         sedan en efter en och skrivs till lysdiodernas basadress LEDS_BASE.
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
*        via en loop. Ordinarie innehåll från register som används i subrutinen
*        sparas undan på stacken, tillsammans med återhoppsadressen i ra
*        samt rampekarens ordinarie adress. Under resten av subrutinen pekar
*        rampekaren på den högsta adress där variablerna lagras.
********************************************************************************/
delay:
   addi sp, sp, -16                 /* Allokerar minne för nya element på stacken. */
   stw ra, 12(sp)                   /* Lägg först till återhoppsadressen på stacken. */
   stw fp, 8(sp)                    /* Sparar rampekarens ordinarie adress på stacken. */
   addi fp, sp, 8                   /* Rampekaren pekar på startadressen där variabler lagras. */
   stw r2, -4(fp)                   /* Sparar undan innehållet från r2 på stacken. */
   stw r3, -8(fp)                   /* Sparar undan innehållet från r2 på stacken. */
   movhi r2, %hi(DELAY_CONSTANT)    /* Läser in DELAY_CONSTANT[31:16] i r2. */
   addi r2, r2, %lo(DELAY_CONSTANT) /* Lägger till DELAY_CONSTANT[15:0] i r2. */
   movi r3, 0                       /* Använder r3 som varvräknare med startvärde 0. */
delay_loop:
   beq r2, r3, delay_end            /* När r3 har räknat upp till r2 avslutas loopen. */
   addi r3, r3, 1                   /* Räknar antalet genomförda varv via inkrementering av r3. */
   br delay_loop                    /* Återstartar loopen så länge r3 är mindre än r2. */
delay_end:
   ldw r3, -8(fp)                   /* Återställer ordinarie innehåll från r3. */
   ldw r2, -4(fp)                   /* Återställer ordinarie innehåll från r2. */
   ldw fp, 8(sp)                    /* Återställer rampekaren. */
   ldw ra, 12(sp)                   /* Återställer återhoppsadressen. */
   addi sp, sp, 16                  /* Återställer stackpekaren. */
   ret                              /* Genomför återhopp när fördröjningen är slutförd. */

/********************************************************************************
* assign: Fyller array av angiven storlek till bredden med heltal. Startvärde
*         samt stegvärde kan väljas godtyckligt.
*
*         - r2: Referens till arrayen (pekar på första elementet).
*         - r3: Arrayens storlek, dvs. antalet element den rymmer.
*         - r4: Startvärdet, dvs. det element som läggs till först.
*         - r5: Stegvärdet, indikerar differensen mellan varje element.
********************************************************************************/
assign:
   addi sp, sp, -4        /* Bereder utrymme för nya element på stacken. */
   stw r6, 0 (sp)         /* Sparar innehållet i r6 på stacken. */
   movi r6, 0             /* Använder r6 som loopräknare. */
assign_loop:
   beq r6, r3, assign_end /* När arrayen har fyllts till bredden avslutas loopen. */
   stw r4, 0(r2)          /* Skriver aktuellt tal till arrayen. */
   addi r2, r2, 4         /* Inkrementerar till adressen där nästa tal ska läggas. */
   add r4, r4, r5         /* Lägger till angivet stegvärde inför nästa tilldelning. */
   addi r6, r6, 1         /* Räknar upp antalet genomförda varv. */
   br assign_loop         /* Återstartar loopen så länge arrayen inte är fylld. */
assign_end:
   ldw r6, 0(sp)          /* Återställer ordinarie innehåll i r6. */
   addi sp, sp, 4         /* Återställer stackpekaren. */
   ret                    /* Avslutar subrutinen när arrayen har fyllts till bredden. */

/********************************************************************************
* write: Skriver samtliga element lagrade i refererad array en efter en till
*        refererat destinationsregister.
*
*        - r2: Referens till arrayen (pekar på första elementet).
*        - r3: Arrayens storlek, dvs. antalet element den rymmer.
*        - r4: Referens till destinationsregistret.
********************************************************************************/
write:
   addi sp, sp, -16      /* Allokerar minne för nya element på stacken. */
   stw ra, 12(sp)        /* Lägg först till återhoppsadressen på stacken. */
   stw fp, 8(sp)         /* Sparar rampekarens ordinarie adress på stacken. */
   addi fp, sp, 8        /* Rampekaren pekar på startadressen där variabler lagras. */
   stw r5, -4(fp)        /* Sparar undan innehållet från r5 på stacken. */
   stw r6, -8(fp)        /* Sparar undan innehållet från r6 på stacken. */
   movi r5, 0            /* Använder r5 som loopräknare. */
write_loop:
   beq r5, r3, write_end /* När iteration genom arrayen är slutförd avslutas loopen. */
   ldw r6, 0(r2)         /* Hämtar aktuellt element från arrayen och lagrar i r6. */
   stwio r6, 0(r4)       /* Det hämtade elementet skrivs till destinationsadressen. */
   addi r2, r2, 4        /* Inkrementerar till adressen för nästa element som ska hämtas. */
   call delay            /* Genererar fördröjning inför nästa varv. */
   addi r5, r5, 1        /* Räknar upp antalet genomförda varv. */
   br write_loop         /* Återstartar loopen så länge iterationen inte är slutförd. */
write_end:
   ldw r6, -8(fp)        /* Återställer ordinarie innehåll från r6. */
   ldw r5, -4(fp)        /* Återställer ordinarie innehåll från r5. */
   ldw fp, 8(sp)         /* Återställer rampekaren. */
   ldw ra, 12(sp)        /* Återställer återhoppsadressen. */
   addi sp, sp, 16       /* Återställer stackpekaren. */
   ret                   /* Avslutar subrutinen när iterationen är slutförd. */

/********************************************************************************
* main: Lagrar minne för arrayen på stacken, som börjar på fp - 64.
*       Utrymme ges också åt lagrad återhoppsadress i ra (börjar på fp + 4)
*       samt rampekarens ordinarie adress (börjar på fp + 0).
********************************************************************************/
main:
   addi sp, sp, -72 /* Ger utrymme för nya element på stacken. */
   stw ra, 68(sp)   /* Lagrar först återhoppsadressen lagrad i ra. */
   stw fp, 64(sp)   /* Lagrar sedan rampekarens ordinarie adress. */
   addi fp, sp, 64  /* Sätter rampekaren till att peka där arrayen lagras. */

/********************************************************************************
* main_array_assign: Fyller arrayen till bredden med udda heltal 1 - 31.
********************************************************************************/
main_array_assign:
   addi r2, fp, -64 /* Laddar (start)adressen för arrayen i r2. */
   movi r3, 16      /* Laddar arrayens storlek i r3. */
   movi r4, 1       /* Laddar arrayens startvärde i r4. */
   movi r5, 2       /* Lagrar stegvärdet för tilldelningen i r5. */
   call assign      /* Fyller arrayen med udda heltal 1 - 31. */

/********************************************************************************
* main_array_write: Skriver arrayens samtliga element till LEDS_BASE.
********************************************************************************/
main_array_write:
   addi r2, fp, -64            /* Laddar (start)adressen för arrayen i r2. */
   movi r3, 16                 /* Laddar arrayens storlek i r3. */
   movhi r4, %hi(LEDS_BASE)    /* Laddar LEDS_BASE[31:16] i r4. */
   addi r4, r4, %lo(LEDS_BASE) /* Lägger till LEDS_BASE[15:0] i r4. */
   call write                  /* Skriver arrayens innehåll till LEDS_BASE. */

/********************************************************************************
* main_end: Återställer stackpekaren och rampekaren samt genomför återhopp
*           innan subrutinen main avslutas.
********************************************************************************/
main_end:
   ldw fp, 64(sp)  /* Återställer rampekaren till startvärde 1024. */
   ldw ra, 68(sp)  /* Lägger tillbaka utsprunglig återhoppsadress i ra. */
   addi sp, sp, 72 /* Återställer stackpekaren till startvärde 1024. */
   movi r2, 0      /* Laddar returvärde 0 i r2. */
   ret             /* Genomför återhopp. */

