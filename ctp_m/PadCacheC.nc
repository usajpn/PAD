/**
  * cache for PAD 
  *
  * @author usa
  */

generic configuration PadCacheC(uint8_t CACHE_SIZE) {
    provides interface PadCache<message_t*>;
}
implementation {
    components MainC, new PadCacheP(CACHE_SIZE) as PadCacheP;
    components CtpP;
    PadCache = PadCacheP;
    PadCacheP.CtpPacket -> CtpP;
    MainC.SoftwareInit -> PadCacheP;
}
