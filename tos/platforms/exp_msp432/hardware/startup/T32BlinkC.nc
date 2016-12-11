
configuration T32BlinkC { }
implementation {
  components T32BlinkP, MainC;
  T32BlinkP -> MainC.Boot;
}
