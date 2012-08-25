/**
 * An PAD cache that stores the signature of a CTP packet instance.
 * An insert operation indicates "use".  Inserting an element not in
 * the cache will replace the oldest, and inserting an element already
 * in the cache will refresh its age.
 *
 * @author usa 
 */

#include <CtpForwardingEngine.h>
#include <message.h>

generic module PadCacheP(uint8_t size) {
    provides {
      interface Init;
      interface PadCache<message_t*>;
    }
    uses {
      interface CtpPacket;
    }
}
implementation {

  pcache_t cache[size];
  uint8_t first;
  uint8_t count;

  command error_t Init.init() {
    first = 0;
    count = 0;
    return SUCCESS;
  } 

  void printCache() {
#ifdef TOSSIM
    int i;
    dbg("Cache","Cache:");
    for (i = 0; i < count; i++) {
      dbg_clear("Cache", " %04x %02x %02x %02x", cache[i].origin, cache[i].seqno, cache[i].type, cache[i].thl);
      if (i == first)
	dbg_clear("Cache","*");
    } 
    dbg_clear("Cache","\n");
#endif
    }

    /* if key is in cache returns the index (offset by first), otherwise returns count */
  uint8_t lookup(message_t* m) {
    uint8_t i;
    uint8_t idx;
    for (i = 0; i < count; i++) {
      idx = (i + first) % size;
      if (call CtpPacket.getOrigin(m)       == cache[idx].sourceNodeId) {
	break;
      }
    }
    return i;
  }
  
  /* remove the entry with index i (relative to first) */
    void remove(uint8_t i) {
        uint8_t j;
        if (i >= count) 
            return;
        if (i == 0) {
            //shift all by moving first
            first = (first + 1) % size;
        } else {
            //shift everyone down
            for (j = i; j < count; j++) {
	      memcpy(&cache[(j + first) % size], &cache[(j + first + 1) % size], sizeof(pcache_t));
	    }
        }
        count--;
    }

    command void PadCache.insert(message_t* m) {
        uint8_t i;
        if (count == size ) {
            //remove someone. If item not in 
            //cache, remove the first item.
            //otherwise remove the item temporarily for
            //reinsertion. This moves the item up in the
            //LRU stack.
	  i = lookup(m);
	  remove(i % count);
        }
        //now count < size
        cache[(first + count) % size].sourceNodeId = call CtpPacket.getOrigin(m);
	cache[(first + count) % size].seqNum  = call CtpPacket.getSequenceNumber(m);
        count++;
    }

    command bool PadCache.lookup(message_t* m) {
        return (lookup(m) < count);
    }

    command void PadCache.flush() {
      call Init.init(); 
    }

	command void PadCache.update(message_t* m) {
		cache[lookup(m)].seqNum = call CtpPacket.getSequenceNumber(m);
	}
	
	command bool PadCache.sequential(message_t* m) {
	  return (call CtpPacket.getSequenceNumber(m) - cache[lookup(m)].seqNum) == 1;
	}
}
