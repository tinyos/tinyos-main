#include "TestDhv.h"

configuration TestDhvC {

}

implementation {
  components TestDhvP;
  components LedsC as LedsC;
  TestDhvP.Leds -> LedsC;

  components DisseminationC;
  TestDhvP.StdControl -> DisseminationC;
  /*
  components new DisseminatorC(uint32_t, 0x1) as Dissem1;
  TestDhvP.DisseminationValue1 -> Dissem1;
  TestDhvP.DisseminationUpdate1 -> Dissem1;
  */

  components new DisseminatorC(uint16_t, 1) as Dissem1;
  TestDhvP.DisseminationUpdate1 -> Dissem1;
  TestDhvP.DisseminationValue1 -> Dissem1;

  components new DisseminatorC(uint16_t, 2) as Dissem2;
  TestDhvP.DisseminationUpdate2 -> Dissem2;
  TestDhvP.DisseminationValue2 -> Dissem2;

  components new DisseminatorC(uint16_t, 3) as Dissem3;
  TestDhvP.DisseminationUpdate3 -> Dissem3;
  TestDhvP.DisseminationValue3 -> Dissem3;

  components new DisseminatorC(uint16_t, 4) as Dissem4;
  TestDhvP.DisseminationUpdate4 -> Dissem4;
  TestDhvP.DisseminationValue4 -> Dissem4;

  components new DisseminatorC(uint16_t, 5) as Dissem5;
  TestDhvP.DisseminationUpdate5 -> Dissem5;
  TestDhvP.DisseminationValue5 -> Dissem5;

  components new DisseminatorC(uint16_t, 6) as Dissem6;
  TestDhvP.DisseminationUpdate6 -> Dissem6;
  TestDhvP.DisseminationValue6 -> Dissem6;

  components new DisseminatorC(uint16_t, 7) as Dissem7;
  TestDhvP.DisseminationUpdate7 -> Dissem7;
  TestDhvP.DisseminationValue7 -> Dissem7;

  components new DisseminatorC(uint16_t, 8) as Dissem8;
  TestDhvP.DisseminationUpdate8 -> Dissem8;
  TestDhvP.DisseminationValue8 -> Dissem8;

  components new DisseminatorC(uint16_t, 9) as Dissem9;
  TestDhvP.DisseminationUpdate9 -> Dissem9;
  TestDhvP.DisseminationValue9 -> Dissem9;

  components new DisseminatorC(uint16_t, 10) as Dissem10;
  TestDhvP.DisseminationUpdate10 -> Dissem10;
  TestDhvP.DisseminationValue10 -> Dissem10;

  components new DisseminatorC(uint16_t, 11) as Dissem11;
  TestDhvP.DisseminationUpdate11 -> Dissem11;
  TestDhvP.DisseminationValue11 -> Dissem11;

  components new DisseminatorC(uint16_t, 12) as Dissem12;
  TestDhvP.DisseminationUpdate12 -> Dissem12;
  TestDhvP.DisseminationValue12 -> Dissem12;

  components new DisseminatorC(uint16_t, 13) as Dissem13;
  TestDhvP.DisseminationUpdate13 -> Dissem13;
  TestDhvP.DisseminationValue13 -> Dissem13;

  components new DisseminatorC(uint16_t, 14) as Dissem14;
  TestDhvP.DisseminationUpdate14 -> Dissem14;
  TestDhvP.DisseminationValue14 -> Dissem14;

  components new DisseminatorC(uint16_t, 15) as Dissem15;
  TestDhvP.DisseminationUpdate15 -> Dissem15;
  TestDhvP.DisseminationValue15 -> Dissem15;

  components new DisseminatorC(uint16_t, 16) as Dissem16;
  TestDhvP.DisseminationUpdate16 -> Dissem16;
  TestDhvP.DisseminationValue16 -> Dissem16;

  components new DisseminatorC(uint16_t, 17) as Dissem17;
  TestDhvP.DisseminationUpdate17 -> Dissem17;
  TestDhvP.DisseminationValue17 -> Dissem17;

  components new DisseminatorC(uint16_t, 18) as Dissem18;
  TestDhvP.DisseminationUpdate18 -> Dissem18;
  TestDhvP.DisseminationValue18 -> Dissem18;

  components new DisseminatorC(uint16_t, 19) as Dissem19;
  TestDhvP.DisseminationUpdate19 -> Dissem19;
  TestDhvP.DisseminationValue19 -> Dissem19;

  components new DisseminatorC(uint16_t, 20) as Dissem20;
  TestDhvP.DisseminationUpdate20 -> Dissem20;
  TestDhvP.DisseminationValue20 -> Dissem20;

  components new DisseminatorC(uint16_t, 21) as Dissem21;
  TestDhvP.DisseminationUpdate21 -> Dissem21;
  TestDhvP.DisseminationValue21 -> Dissem21;

  components new DisseminatorC(uint16_t, 22) as Dissem22;
  TestDhvP.DisseminationUpdate22 -> Dissem22;
  TestDhvP.DisseminationValue22 -> Dissem22;

  components new DisseminatorC(uint16_t, 23) as Dissem23;
  TestDhvP.DisseminationUpdate23 -> Dissem23;
  TestDhvP.DisseminationValue23 -> Dissem23;

  components new DisseminatorC(uint16_t, 24) as Dissem24;
  TestDhvP.DisseminationUpdate24 -> Dissem24;
  TestDhvP.DisseminationValue24 -> Dissem24;

  components new DisseminatorC(uint16_t, 25) as Dissem25;
  TestDhvP.DisseminationUpdate25 -> Dissem25;
  TestDhvP.DisseminationValue25 -> Dissem25;

  components new DisseminatorC(uint16_t, 26) as Dissem26;
  TestDhvP.DisseminationUpdate26 -> Dissem26;
  TestDhvP.DisseminationValue26 -> Dissem26;

  components new DisseminatorC(uint16_t, 27) as Dissem27;
  TestDhvP.DisseminationUpdate27 -> Dissem27;
  TestDhvP.DisseminationValue27 -> Dissem27;

  components new DisseminatorC(uint16_t, 28) as Dissem28;
  TestDhvP.DisseminationUpdate28 -> Dissem28;
  TestDhvP.DisseminationValue28 -> Dissem28;

  components new DisseminatorC(uint16_t, 29) as Dissem29;
  TestDhvP.DisseminationUpdate29 -> Dissem29;
  TestDhvP.DisseminationValue29 -> Dissem29;

  components new DisseminatorC(uint16_t, 30) as Dissem30;
  TestDhvP.DisseminationUpdate30 -> Dissem30;
  TestDhvP.DisseminationValue30 -> Dissem30;

  components new DisseminatorC(uint16_t, 31) as Dissem31;
  TestDhvP.DisseminationUpdate31 -> Dissem31;
  TestDhvP.DisseminationValue31 -> Dissem31;

  components new DisseminatorC(uint16_t, 32) as Dissem32;
  TestDhvP.DisseminationUpdate32 -> Dissem32;
  TestDhvP.DisseminationValue32 -> Dissem32;

  components new DisseminatorC(uint16_t, 33) as Dissem33;
  TestDhvP.DisseminationUpdate33 -> Dissem33;
  TestDhvP.DisseminationValue33 -> Dissem33;

  components new DisseminatorC(uint16_t, 34) as Dissem34;
  TestDhvP.DisseminationUpdate34 -> Dissem34;
  TestDhvP.DisseminationValue34 -> Dissem34;

  components new DisseminatorC(uint16_t, 35) as Dissem35;
  TestDhvP.DisseminationUpdate35 -> Dissem35;
  TestDhvP.DisseminationValue35 -> Dissem35;

  components new DisseminatorC(uint16_t, 36) as Dissem36;
  TestDhvP.DisseminationUpdate36 -> Dissem36;
  TestDhvP.DisseminationValue36 -> Dissem36;

  components new DisseminatorC(uint16_t, 37) as Dissem37;
  TestDhvP.DisseminationUpdate37 -> Dissem37;
  TestDhvP.DisseminationValue37 -> Dissem37;

  components new DisseminatorC(uint16_t, 38) as Dissem38;
  TestDhvP.DisseminationUpdate38 -> Dissem38;
  TestDhvP.DisseminationValue38 -> Dissem38;

  components new DisseminatorC(uint16_t, 39) as Dissem39;
  TestDhvP.DisseminationUpdate39 -> Dissem39;
  TestDhvP.DisseminationValue39 -> Dissem39;

  components new DisseminatorC(uint16_t, 40) as Dissem40;
  TestDhvP.DisseminationUpdate40 -> Dissem40;
  TestDhvP.DisseminationValue40 -> Dissem40;

  components new DisseminatorC(uint16_t, 41) as Dissem41;
  TestDhvP.DisseminationUpdate41 -> Dissem41;
  TestDhvP.DisseminationValue41 -> Dissem41;

  components new DisseminatorC(uint16_t, 42) as Dissem42;
  TestDhvP.DisseminationUpdate42 -> Dissem42;
  TestDhvP.DisseminationValue42 -> Dissem42;

  components new DisseminatorC(uint16_t, 43) as Dissem43;
  TestDhvP.DisseminationUpdate43 -> Dissem43;
  TestDhvP.DisseminationValue43 -> Dissem43;

  components new DisseminatorC(uint16_t, 44) as Dissem44;
  TestDhvP.DisseminationUpdate44 -> Dissem44;
  TestDhvP.DisseminationValue44 -> Dissem44;

  components new DisseminatorC(uint16_t, 45) as Dissem45;
  TestDhvP.DisseminationUpdate45 -> Dissem45;
  TestDhvP.DisseminationValue45 -> Dissem45;

  components new DisseminatorC(uint16_t, 46) as Dissem46;
  TestDhvP.DisseminationUpdate46 -> Dissem46;
  TestDhvP.DisseminationValue46 -> Dissem46;

  components new DisseminatorC(uint16_t, 47) as Dissem47;
  TestDhvP.DisseminationUpdate47 -> Dissem47;
  TestDhvP.DisseminationValue47 -> Dissem47;

  components new DisseminatorC(uint16_t, 48) as Dissem48;
  TestDhvP.DisseminationUpdate48 -> Dissem48;
  TestDhvP.DisseminationValue48 -> Dissem48;

  components new DisseminatorC(uint16_t, 49) as Dissem49;
  TestDhvP.DisseminationUpdate49 -> Dissem49;
  TestDhvP.DisseminationValue49 -> Dissem49;

  components new DisseminatorC(uint16_t, 50) as Dissem50;
  TestDhvP.DisseminationUpdate50 -> Dissem50;
  TestDhvP.DisseminationValue50 -> Dissem50;

  components new DisseminatorC(uint16_t, 51) as Dissem51;
  TestDhvP.DisseminationUpdate51 -> Dissem51;
  TestDhvP.DisseminationValue51 -> Dissem51;

  components new DisseminatorC(uint16_t, 52) as Dissem52;
  TestDhvP.DisseminationUpdate52 -> Dissem52;
  TestDhvP.DisseminationValue52 -> Dissem52;

  components new DisseminatorC(uint16_t, 53) as Dissem53;
  TestDhvP.DisseminationUpdate53 -> Dissem53;
  TestDhvP.DisseminationValue53 -> Dissem53;

  components new DisseminatorC(uint16_t, 54) as Dissem54;
  TestDhvP.DisseminationUpdate54 -> Dissem54;
  TestDhvP.DisseminationValue54 -> Dissem54;

  components new DisseminatorC(uint16_t, 55) as Dissem55;
  TestDhvP.DisseminationUpdate55 -> Dissem55;
  TestDhvP.DisseminationValue55 -> Dissem55;

  components new DisseminatorC(uint16_t, 56) as Dissem56;
  TestDhvP.DisseminationUpdate56 -> Dissem56;
  TestDhvP.DisseminationValue56 -> Dissem56;

  components new DisseminatorC(uint16_t, 57) as Dissem57;
  TestDhvP.DisseminationUpdate57 -> Dissem57;
  TestDhvP.DisseminationValue57 -> Dissem57;

  components new DisseminatorC(uint16_t, 58) as Dissem58;
  TestDhvP.DisseminationUpdate58 -> Dissem58;
  TestDhvP.DisseminationValue58 -> Dissem58;

  components new DisseminatorC(uint16_t, 59) as Dissem59;
  TestDhvP.DisseminationUpdate59 -> Dissem59;
  TestDhvP.DisseminationValue59 -> Dissem59;

  components new DisseminatorC(uint16_t, 60) as Dissem60;
  TestDhvP.DisseminationUpdate60 -> Dissem60;
  TestDhvP.DisseminationValue60 -> Dissem60;

  components new DisseminatorC(uint16_t, 61) as Dissem61;
  TestDhvP.DisseminationUpdate61 -> Dissem61;
  TestDhvP.DisseminationValue61 -> Dissem61;

  components new DisseminatorC(uint16_t, 62) as Dissem62;
  TestDhvP.DisseminationUpdate62 -> Dissem62;
  TestDhvP.DisseminationValue62 -> Dissem62;

  components new DisseminatorC(uint16_t, 63) as Dissem63;
  TestDhvP.DisseminationUpdate63 -> Dissem63;
  TestDhvP.DisseminationValue63 -> Dissem63;

  components new DisseminatorC(uint16_t, 64) as Dissem64;
  TestDhvP.DisseminationUpdate64 -> Dissem64;
  TestDhvP.DisseminationValue64 -> Dissem64;


  components MainC;
  TestDhvP.Boot -> MainC;

  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_DHV_TEST_MSG);
  TestDhvP.SerialSend -> SerialAMSenderC;
  TestDhvP.SerialControl -> SerialActiveMessageC;
}
