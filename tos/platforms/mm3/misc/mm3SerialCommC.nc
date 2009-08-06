/**
 * Copyright @ 2008-2009 Eric B. Decker
 * @author Eric B. Decker
 */
 
configuration mm3SerialCommC {
  provides {
    interface pakSend;
    interface SplitControl;
  }
  uses {
    interface Resource;
    interface ResourceRequested;
  }
}

implementation {
  components MainC, mm3SerialCommP;
  MainC.SoftwareInit -> mm3SerialCommP;

  pakSend = mm3SerialCommP;
  Resource = mm3SerialCommP;
  ResourceRequested = mm3SerialCommP;

  components SerialPakDirectC as SerialSender;
  SplitControl = SerialSender;

  components SerialAMEncapP, SerialNullEncapP;
  SerialAMEncapP   <- SerialSender.EncapWrite[ENCAP_AM];
  SerialNullEncapP <- SerialSender.EncapWrite[ENCAP_SERIAL];
  
  mm3SerialCommP.SubSend -> SerialSender;
}
