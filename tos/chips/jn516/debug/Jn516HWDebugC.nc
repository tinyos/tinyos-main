/**
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

configuration Jn516HWDebugC
{
  provides interface Jn516HWDebug;
  uses interface Boot;
}
implementation {
  components Jn516HWDebugP;
  Jn516HWDebug = Jn516HWDebugP;

  Jn516HWDebugP.Boot = Boot;
}
