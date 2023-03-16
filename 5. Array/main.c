/********************************************************************************
* main.c: Demonstration av array i C. Samtliga udda tal 1 – 31 lagras i en
*         statisk array. Samtliga element lagrade i arrayen hämtas sedan en
*         efter en och skrivs till lysdiodernas basadress LEDS_BASE.
*
*         Simulera programmet på följande länk:
*         https://cpulator.01xz.net/?sys=nios-de10-lite
*
*         Vid simulering, kommentera ut makrot GPIO_CASE_GOLD_HW nedan.
********************************************************************************/
#include <stdint.h>

/********************************************************************************
* GPIO_CASE_GOLD_HW: Makro för att definiera basadresser för CASE GOLD hårdvara.
*                    Kommentera ut detta makro vid simulering.
********************************************************************************/
#define GPIO_CASE_GOLD_HW

/********************************************************************************
* Makrodefinitioner:
********************************************************************************/
#ifdef GPIO_CASE_GOLD_HW
#define LEDS_BASE (volatile uint32_t*)(0x8091740)  /* Basadress för lysdioder (CASE GOLD). */
#define DELAY_CONSTANT 100000UL                    /* Fördröjningskonstant (CASE GOLD). */
#else
#define LEDS_BASE (volatile uint32_t*)(0xFF200000) /* Basadress för lysdioder (simulering). */
#define DELAY_CONSTANT 1000000UL                   /* Fördröjningskonstant simulering. */
#endif /* GPIO_CASE_GOLD_HW */

/********************************************************************************
* delay: Genererar fördröjning genom att räkna upp från 0 till DELAY_CONSTANT
*        via en loop. För att säkerhetsställa att kompilatorn inte slopar
*        uppräkningen (för optimering av koden) används instruktionen
*        nop (no operation) varje varv i loopen.
********************************************************************************/
static inline void delay(void)
{
   for (uint32_t i = 0; i < DELAY_CONSTANT; ++i)
   {
      asm volatile("nop");
   }
   return;
}

/********************************************************************************
* assign: Fyller array av angiven storlek till bredden med heltal. Startvärde
*         samt stegvärde kan väljas godtyckligt.
*
*         - data     : Referens till arrayen (pekar på första elementet).
*         - size     : Arrayens storlek, dvs. antalet element den rymmer.
*         - start_val: Startvärdet, dvs. det element som läggs till först.
*         - step_val : Stegvärdet, indikerar differensen mellan varje element.
********************************************************************************/
static inline void assign(uint32_t* data,
                          const uint32_t size,
                          const uint32_t start_val,
                          const uint32_t step_val)
{
   uint32_t val = start_val;

   for (uint32_t* i = data; i < data + size; ++i)
   {
      *i = val;
      val += step_val;
     delay();
   }
   return;
}

/********************************************************************************
* write: Skriver samtliga element lagrade i refererad array en efter en till
*        refererat destinationsregister. En kort fördröjning genereras
*        mellan varje skrivning.
*
*        - data       : Referens till arrayen (pekar på första elementet).
*        - size       : Arrayens storlek, dvs. antalet element den rymmer.
*        - destination: Referens till destinationsregistret.
********************************************************************************/
static inline void write(const uint32_t* data,
                         const uint32_t size,
                         volatile uint32_t* destination)
{
   for (const uint32_t* i = data; i < data + size; ++i)
   {
      *destination = *i;
      delay();
   }
   return;
}

/********************************************************************************
* main: Deklarerar en statisk array som rymmer 16 heltal. Arrayen tilldelas
*       samtliga udda heltal 1 - 31. Arrayens element hämtas var för sig
*       och skrivs till lysdiodernas basadress LEDS_BASE.
********************************************************************************/
int main(void)
{
   uint32_t data[16];
   assign(data, 16, 1, 2);
   write(data, 16, LEDS_BASE);
   return 0;
}
