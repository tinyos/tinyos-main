/* 
 * Author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */

configuration FlashC {
  provides interface Flash;
}
implementation {
  components 
    Main,
    FlashM;

  Main.StdControl -> FlashM;
  Flash = FlashM;
}
