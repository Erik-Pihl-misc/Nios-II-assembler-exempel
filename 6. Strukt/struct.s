/********************************************************************************
* struct.s: Demonstration av strukt f�r skrivning samt l�sning av GPIO-enheter
*           i form av lysdioder, slide-switchar samt tryckknappar.
*
*           Tv� lysdioder led1 - led2 ansluts till LED[0:1], en slide-switch
*           switch1 ansluts till SWITCH[0] och en tryckknapp button1 ansluts
*           till KEY[0]. Polling (avl�sning) sker kontinuerligt av switch1
*           samt button1. Insignalen fr�n switch1 matas direkt till led1.
*           Vid nedtryckning av button1 t�nds led2, annars h�lls led2 sl�ckt.
*
*           Simulera programmet p� f�ljande l�nk:
*           https://cpulator.01xz.net/?sys=nios-de10-lite
*
*           Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW nedan.
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
* GPIO_CASE_GOLD_HW: Makro f�r att definiera basadresser f�r CASE GOLD h�rdvara.
*                    Kommentera ut detta makro vid simulering.
********************************************************************************/
.equ GPIO_CASE_GOLD_HW, 0

/********************************************************************************
* Basadresser f�r olika valbara in- och utenheter:
********************************************************************************/
.ifdef GPIO_CASE_GOLD_HW
.equ LEDS_BASE    , 0x8091740  /* Basadress f�r lysdioder. */
.equ SWITCHES_BASE, 0x8091750  /* Basadress f�r slide-switchar. */
.equ BUTTONS_BASE , 0x8091760  /* Basadress f�r tryckknappar. */
.else
.equ LEDS_BASE    , 0xFF200000 /* Basadress f�r lysdioder. */
.equ SWITCHES_BASE, 0xFF200040 /* Basadress f�r slide-switchar. */
.equ BUTTONS_BASE , 0xFF200050 /* Basadress f�r tryckknappar. */
.endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* Makron f�r val av GPIO-enhet f�r strukten gpio:
********************************************************************************/
.equ GPIO_SELECTION_LED   , 0 /* Lysdiod. */
.equ GPIO_SELECTION_SWITCH, 1 /* Slide-switch. */
.equ GPIO_SELECTION_BUTTON, 2 /* Tryckknapp. */

/********************************************************************************
* Offsets f�r medlemmar av strukten gpio:
********************************************************************************/
.equ GPIO_BASE_PTR_OFFSET , 0  /* Offset f�r pekare till GPIO-enhetens basadress. */
.equ GPIO_UNIT_SEL_OFFSET , 4  /* Offset f�r val av GPIO-enhet. */
.equ GPIO_PIN_OFFSET      , 8  /* Offset f�r GPIO-enhetens pin-nummer. */
.equ GPIO_SIZE            , 12 /* Storleken f�r ett GPIO-objekt i byte. */

/********************************************************************************
* gpio_init: Initierar godtycklig GPIO-enhet ansluten till angiven pin.
*            Vid fel sker ingen initiering och felkod 1 returneras via r2.
*            Annars returneras 0 via r2 efter slutf�rd initiering.
*
*            - r2: Referens till GPIO-enheten.
*            - r3: GPIO-enhetens pin-nummer.
*            - r4: Val av enhet (lysdiod, slide-switch eller tryckknapp).
********************************************************************************/
gpio_init:
   addi sp, sp, -4                  /* Allokerar minne f�r lokala variabler p� stacken. */
   stw r5, 0(sp)                    /* Sparar undan inneh�llet i r5 inf�r anv�ndning. */
   stw r3, GPIO_PIN_OFFSET(r2)      /* Sparar angivet pin-nummer via offset. */
   stw r4, GPIO_UNIT_SEL_OFFSET(r2) /* Sparar val av GPIO-enhet via offset. */
   movi r5, GPIO_SELECTION_LED      /* Om vald enhet �r en lysdiod sparas */
   beq r4, r5, gpio_init_led        /* basadressen till lysdioderna. */
   movi r5, GPIO_SELECTION_SWITCH   /* Annars om vald enhet �r en slide-switch */
   beq r4, r5, gpio_init_switch     /* sparas basadressen till slide-switcharna. */
   movi r5, GPIO_SELECTION_BUTTON   /* Annars om vald enhet �r en tryckknapp */
   beq r4, r5, gpio_init_button     /* sparas basadressen till tryckknapparna. */
gpio_init_error:
   movi r2, 1                       /* Vid felaktigt vald enhet lagras returkod 1 i r2. */
   br gpio_init_end                 /* �terst�ller stacken och avslutar subrutinen. */
gpio_init_led:
   movhi r4, %hi(LEDS_BASE)         /* L�ser in LEDS_BASE[31:16] i r4. */
   addi r4, r4, %lo(LEDS_BASE)      /* L�gger till LEDS_BASE[15:0] i r4. */
   stw r4, GPIO_BASE_PTR_OFFSET(r2) /* Sparar LEDS_BASE via offset. */
   br gpio_init_success             /* Avslutar subrutinen med returkod 0. */
gpio_init_switch:
   movhi r4, %hi(SWITCHES_BASE)     /* L�ser in SWITCHES_BASE[31:16] i r4. */
   addi r4, r4, %lo(SWITCHES_BASE)  /* L�gger till SWITCHES_BASE[15:0] i r4. */
   stw r4, GPIO_BASE_PTR_OFFSET(r2) /* Sparar SWITCHES_BASE via offset. */
   br gpio_init_success             /* Avslutar subrutinen med returkod 0. */
gpio_init_button:
   movhi r4, %hi(BUTTONS_BASE)      /* L�ser in BUTTONS_BASE[31:16] i r4. */
   addi r4, r4, %lo(BUTTONS_BASE)   /* L�gger till BUTTONS_BASE[15:0] i r4. */
   stw r4, GPIO_BASE_PTR_OFFSET(r2) /* Sparar BUTTONS_BASE via offset. */
gpio_init_success:
   movi r2, 0                       /* Lagrar returkod 0 i r2. */
gpio_init_end:
   ldw r5, 0(sp)                    /* �terst�ller inneh�llet i r5 efter anv�ndning. */
   addi sp, sp, 4                   /* �terst�ller stackpekaren. */
   ret                              /* Genomf�r �terhopp. */

/********************************************************************************
* gpio_write: Skriver utsignal till refererad GPIO-enhet.
*
*               - r2: Referens till GPIO-enheten.
*               - r3: V�rdet som ska skrivas (0 eller 1).
********************************************************************************/
gpio_write:
   addi sp, sp, -16                 /* Allokerar minne f�r lokala variabler p� stacken. */
   stw r4, 12(sp)                   /* Sparar undan inneh�llet i r4 inf�r anv�ndning. */
   stw r5, 8(sp)                    /* Sparar undan inneh�llet i r5 inf�r anv�ndning. */
   stw r6, 4(sp)                    /* Sparar undan inneh�llet i r6 inf�r anv�ndning. */
   stw r7, 0(sp)                    /* Sparar undan inneh�llet i r7 inf�r anv�ndning. */
gpio_write_load_data:
   ldw r4, GPIO_BASE_PTR_OFFSET(r2) /* Laddar enhetens basadress i r4. */
   ldwio r5, 0(r4)                  /* Laddar aktuella signaler fr�n basadressen i r5. */
   ldw r6, GPIO_PIN_OFFSET(r2)      /* Laddar enhetens pin-nummer i r6. */
   movi r7, 1                       /* L�ser in 0x01 i r7 f�r bitvis skiftning av pin-numret. */
gpio_write_shift_left:
   sll r6, r7, r6                   /* Skiftar enhetens pin-nummer f�r skrivning. */
   bne r3, zero, gpio_write_high    /* Om insignalen i r3 inte �r 0 s�tts utsignalen till h�g. */
gpio_write_low:                     /* Annars s�tts utsignalen till l�g. */
   movi r7, -1                      /* L�ser in 0xFFFF i r7 f�r invertering via XOR. */
   xor r6, r6, r7                   /* Inverterar det skiftade v�rdet f�r att s�tta l�g utsignal. */
   and r5, r5, r6                   /* S�tter enhetens signal till l�g via bitvis AND. */
   stwio r5, 0(r4)                  /* Skriver det uppdaterade v�rdet till basadressen. */
   br gpio_write_end                /* �terst�ller stackpekaren och avslutar subrutinen. */
gpio_write_high:
   or r5, r5, r6                    /* S�tter enhetens signal till h�g via bitvis OR. */
   stwio r5, 0(r4)                  /* Skriver det uppdaterade v�rdet till basadressen. */
gpio_write_end:
   ldw r7, 0(sp)                    /* �terst�ller r7 efter anv�ndning. */
   ldw r6, 4(sp)                    /* �terst�ller r6 efter anv�ndning. */
   ldw r5, 8(sp)                    /* �terst�ller r5 efter anv�ndning. */
   ldw r4, 12(sp)                   /* �terst�ller r4 efter anv�ndning. */
   addi sp, sp, 16                  /* �terst�ller stackpekaren. */
   ret                              /* Avslutar subrutinen efter att skrivningen har slutf�rts. */

/********************************************************************************
* gpio_read: Returnerar insignalen fr�n referered GPIO-enhet via r2.
*            Vid h�g insignal returneras 1, annars 0.
*
*            - r2: Referens till GPIO-enheten.
********************************************************************************/
gpio_read:
   addi sp, sp, -16                 /* Allokerar minne f�r lokala variabler p� stacken. */
   stw r3, 12(sp)                   /* Sparar undan inneh�llet i r3 inf�r anv�ndning. */
   stw r4, 8(sp)                    /* Sparar undan inneh�llet i r4 inf�r anv�ndning. */
   stw r5, 4(sp)                    /* Sparar undan inneh�llet i r5 inf�r anv�ndning. */
   stw r6, 0(sp)                    /* Sparar undan inneh�llet i r6 inf�r anv�ndning. */
gpio_read_load_data:
   ldw r3, GPIO_BASE_PTR_OFFSET(r2) /* Laddar enhetens basadress i r3. */
   ldwio r4, 0(r3)                  /* Laddar aktuella signaler fr�n basadressen i r4. */
   ldw r5, GPIO_PIN_OFFSET(r2)      /* Laddar enhetens pin-nummer i r5. */
gpio_read_shift_left:
   movi r6, 1                       /* L�ser in 0x01 i r6 f�r bitvis skiftning av pin-numret. */
   sll r5, r6, r5                   /* Skiftar enhetens pin-nummer f�r l�sning. */
   and r4, r4, r5                   /* Maskerar alla bitar f�rutom enhetens f�r l�sning. */
   cmpgeui r2, r4, 1                /* Om enhetens bit �r h�g returneras 1 i i r2, annars 0. */
gpio_read_end:
   ldw r6, 0(sp)                    /* �terst�ller r6 efter anv�ndning. */
   ldw r5, 4(sp)                    /* �terst�ller r5 efter anv�ndning. */
   ldw r4, 8(sp)                    /* �terst�ller r4 efter anv�ndning. */
   ldw r3, 12(sp)                   /* �terst�ller r3 efter anv�ndning. */
   addi sp, sp, 16                  /* �terst�ller stackpekaren. */
   ret                              /* Avslutar subrutinen efter att skrivningen har slutf�rts. */

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

