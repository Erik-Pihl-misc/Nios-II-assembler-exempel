/********************************************************************************
* struct.s: Demonstration av strukt för skrivning samt läsning av GPIO-enheter
*           i form av lysdioder, slide-switchar samt tryckknappar.
*
*           Två lysdioder led1 - led2 ansluts till LED[0:1], en slide-switch
*           switch1 ansluts till SWITCH[0] och en tryckknapp button1 ansluts
*           till KEY[0]. Polling (avläsning) sker kontinuerligt av switch1
*           samt button1. Insignalen från switch1 matas direkt till led1.
*           Vid nedtryckning av button1 tänds led2, annars hålls led2 släckt.
*
*           Simulera programmet på följande länk:
*           https://cpulator.01xz.net/?sys=nios-de10-lite
*
*           Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW nedan.
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
* Basadresser för olika valbara in- och utenheter:
********************************************************************************/
.ifdef GPIO_CASE_GOLD_HW
.equ LEDS_BASE    , 0x8091740  /* Basadress för lysdioder. */
.equ SWITCHES_BASE, 0x8091750  /* Basadress för slide-switchar. */
.equ BUTTONS_BASE , 0x8091760  /* Basadress för tryckknappar. */
.else
.equ LEDS_BASE    , 0xFF200000 /* Basadress för lysdioder. */
.equ SWITCHES_BASE, 0xFF200040 /* Basadress för slide-switchar. */
.equ BUTTONS_BASE , 0xFF200050 /* Basadress för tryckknappar. */
.endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* Makron för val av GPIO-enhet för strukten gpio:
********************************************************************************/
.equ GPIO_SELECTION_LED   , 0 /* Lysdiod. */
.equ GPIO_SELECTION_SWITCH, 1 /* Slide-switch. */
.equ GPIO_SELECTION_BUTTON, 2 /* Tryckknapp. */

/********************************************************************************
* Offsets för medlemmar av strukten gpio:
********************************************************************************/
.equ GPIO_BASE_PTR_OFFSET , 0  /* Offset för pekare till GPIO-enhetens basadress. */
.equ GPIO_UNIT_SEL_OFFSET , 4  /* Offset för val av GPIO-enhet. */
.equ GPIO_PIN_OFFSET      , 8  /* Offset för GPIO-enhetens pin-nummer. */
.equ GPIO_SIZE            , 12 /* Storleken för ett GPIO-objekt i byte. */

/********************************************************************************
* gpio_init: Initierar godtycklig GPIO-enhet ansluten till angiven pin.
*            Vid fel sker ingen initiering och felkod 1 returneras via r2.
*            Annars returneras 0 via r2 efter slutförd initiering.
*
*            - r2: Referens till GPIO-enheten.
*            - r3: GPIO-enhetens pin-nummer.
*            - r4: Val av enhet (lysdiod, slide-switch eller tryckknapp).
********************************************************************************/
gpio_init:
   addi sp, sp, -4                  /* Allokerar minne för lokala variabler på stacken. */
   stw r5, 0(sp)                    /* Sparar undan innehållet i r5 inför användning. */
   stw r3, GPIO_PIN_OFFSET(r2)      /* Sparar angivet pin-nummer via offset. */
   stw r4, GPIO_UNIT_SEL_OFFSET(r2) /* Sparar val av GPIO-enhet via offset. */
   movi r5, GPIO_SELECTION_LED      /* Om vald enhet är en lysdiod sparas */
   beq r4, r5, gpio_init_led        /* basadressen till lysdioderna. */
   movi r5, GPIO_SELECTION_SWITCH   /* Annars om vald enhet är en slide-switch */
   beq r4, r5, gpio_init_switch     /* sparas basadressen till slide-switcharna. */
   movi r5, GPIO_SELECTION_BUTTON   /* Annars om vald enhet är en tryckknapp */
   beq r4, r5, gpio_init_button     /* sparas basadressen till tryckknapparna. */
gpio_init_error:
   movi r2, 1                       /* Vid felaktigt vald enhet lagras returkod 1 i r2. */
   br gpio_init_end                 /* Återställer stacken och avslutar subrutinen. */
gpio_init_led:
   movhi r4, %hi(LEDS_BASE)         /* Läser in LEDS_BASE[31:16] i r4. */
   addi r4, r4, %lo(LEDS_BASE)      /* Lägger till LEDS_BASE[15:0] i r4. */
   stw r4, GPIO_BASE_PTR_OFFSET(r2) /* Sparar LEDS_BASE via offset. */
   br gpio_init_success             /* Avslutar subrutinen med returkod 0. */
gpio_init_switch:
   movhi r4, %hi(SWITCHES_BASE)     /* Läser in SWITCHES_BASE[31:16] i r4. */
   addi r4, r4, %lo(SWITCHES_BASE)  /* Lägger till SWITCHES_BASE[15:0] i r4. */
   stw r4, GPIO_BASE_PTR_OFFSET(r2) /* Sparar SWITCHES_BASE via offset. */
   br gpio_init_success             /* Avslutar subrutinen med returkod 0. */
gpio_init_button:
   movhi r4, %hi(BUTTONS_BASE)      /* Läser in BUTTONS_BASE[31:16] i r4. */
   addi r4, r4, %lo(BUTTONS_BASE)   /* Lägger till BUTTONS_BASE[15:0] i r4. */
   stw r4, GPIO_BASE_PTR_OFFSET(r2) /* Sparar BUTTONS_BASE via offset. */
gpio_init_success:
   movi r2, 0                       /* Lagrar returkod 0 i r2. */
gpio_init_end:
   ldw r5, 0(sp)                    /* Återställer innehållet i r5 efter användning. */
   addi sp, sp, 4                   /* Återställer stackpekaren. */
   ret                              /* Genomför återhopp. */

/********************************************************************************
* gpio_write: Skriver utsignal till refererad GPIO-enhet.
*
*               - r2: Referens till GPIO-enheten.
*               - r3: Värdet som ska skrivas (0 eller 1).
********************************************************************************/
gpio_write:
   addi sp, sp, -16                 /* Allokerar minne för lokala variabler på stacken. */
   stw r4, 12(sp)                   /* Sparar undan innehållet i r4 inför användning. */
   stw r5, 8(sp)                    /* Sparar undan innehållet i r5 inför användning. */
   stw r6, 4(sp)                    /* Sparar undan innehållet i r6 inför användning. */
   stw r7, 0(sp)                    /* Sparar undan innehållet i r7 inför användning. */
gpio_write_load_data:
   ldw r4, GPIO_BASE_PTR_OFFSET(r2) /* Laddar enhetens basadress i r4. */
   ldwio r5, 0(r4)                  /* Laddar aktuella signaler från basadressen i r5. */
   ldw r6, GPIO_PIN_OFFSET(r2)      /* Laddar enhetens pin-nummer i r6. */
   movi r7, 1                       /* Läser in 0x01 i r7 för bitvis skiftning av pin-numret. */
gpio_write_shift_left:
   sll r6, r7, r6                   /* Skiftar enhetens pin-nummer för skrivning. */
   bne r3, zero, gpio_write_high    /* Om insignalen i r3 inte är 0 sätts utsignalen till hög. */
gpio_write_low:                     /* Annars sätts utsignalen till låg. */
   movi r7, -1                      /* Läser in 0xFFFF i r7 för invertering via XOR. */
   xor r6, r6, r7                   /* Inverterar det skiftade värdet för att sätta låg utsignal. */
   and r5, r5, r6                   /* Sätter enhetens signal till låg via bitvis AND. */
   stwio r5, 0(r4)                  /* Skriver det uppdaterade värdet till basadressen. */
   br gpio_write_end                /* Återställer stackpekaren och avslutar subrutinen. */
gpio_write_high:
   or r5, r5, r6                    /* Sätter enhetens signal till hög via bitvis OR. */
   stwio r5, 0(r4)                  /* Skriver det uppdaterade värdet till basadressen. */
gpio_write_end:
   ldw r7, 0(sp)                    /* Återställer r7 efter användning. */
   ldw r6, 4(sp)                    /* Återställer r6 efter användning. */
   ldw r5, 8(sp)                    /* Återställer r5 efter användning. */
   ldw r4, 12(sp)                   /* Återställer r4 efter användning. */
   addi sp, sp, 16                  /* Återställer stackpekaren. */
   ret                              /* Avslutar subrutinen efter att skrivningen har slutförts. */

/********************************************************************************
* gpio_read: Returnerar insignalen från referered GPIO-enhet via r2.
*            Vid hög insignal returneras 1, annars 0.
*
*            - r2: Referens till GPIO-enheten.
********************************************************************************/
gpio_read:
   addi sp, sp, -16                 /* Allokerar minne för lokala variabler på stacken. */
   stw r3, 12(sp)                   /* Sparar undan innehållet i r3 inför användning. */
   stw r4, 8(sp)                    /* Sparar undan innehållet i r4 inför användning. */
   stw r5, 4(sp)                    /* Sparar undan innehållet i r5 inför användning. */
   stw r6, 0(sp)                    /* Sparar undan innehållet i r6 inför användning. */
gpio_read_load_data:
   ldw r3, GPIO_BASE_PTR_OFFSET(r2) /* Laddar enhetens basadress i r3. */
   ldwio r4, 0(r3)                  /* Laddar aktuella signaler från basadressen i r4. */
   ldw r5, GPIO_PIN_OFFSET(r2)      /* Laddar enhetens pin-nummer i r5. */
gpio_read_shift_left:
   movi r6, 1                       /* Läser in 0x01 i r6 för bitvis skiftning av pin-numret. */
   sll r5, r6, r5                   /* Skiftar enhetens pin-nummer för läsning. */
   and r4, r4, r5                   /* Maskerar alla bitar förutom enhetens för läsning. */
   cmpgeui r2, r4, 1                /* Om enhetens bit är hög returneras 1 i i r2, annars 0. */
gpio_read_end:
   ldw r6, 0(sp)                    /* Återställer r6 efter användning. */
   ldw r5, 4(sp)                    /* Återställer r5 efter användning. */
   ldw r4, 8(sp)                    /* Återställer r4 efter användning. */
   ldw r3, 12(sp)                   /* Återställer r3 efter användning. */
   addi sp, sp, 16                  /* Återställer stackpekaren. */
   ret                              /* Avslutar subrutinen efter att skrivningen har slutförts. */

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

