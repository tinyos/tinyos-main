
configuration TrackFlowsC {

} implementation {
  
  components MainC, TrackFlowsP, IPDispatchP;
  components SerialActiveMessageC as Serial;

  TrackFlowsP.Boot -> MainC;
  TrackFlowsP.SerialControl -> Serial;
  TrackFlowsP.IPExtensions -> IPDispatchP.IPExtensions;
  TrackFlowsP.Headers -> IPDispatchP.HopByHopExt;

  TrackFlowsP.FlowSend -> Serial.AMSend[AM_FLOW_ID_MSG];
  
}
