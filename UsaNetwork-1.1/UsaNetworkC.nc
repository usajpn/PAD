/*
 * @author usa
 */

 #include <Timer.h>
 #include "UsaNetwork.h"
 #include "CtpDebugMsg.h"

 module UsaNetworkC {
 	uses interface Boot;
	uses interface SplitControl as RadioControl;
	uses interface SplitControl as SerialControl;
	uses interface StdControl as RoutingControl;
	uses interface StdControl as DisseminationControl;
	uses interface DisseminationValue<uint32_t> as DisseminationPeriod;
	uses interface Send;
	uses interface Leds;
 	uses interface Read<uint16_t> as ReadSensor;
	uses interface Timer<TMilli>;
	uses interface RootControl;
	uses interface Receive;
	uses interface CollectionPacket;
	uses interface CtpInfo;
	uses interface CtpCongestion;
	uses interface CtpPacket;
	uses interface Random;
	uses interface Queue<message_t*>;
	uses interface Pool<message_t>;
	uses interface CollectionDebug;
	uses interface AMPacket;
	uses interface Packet as RadioPacket;
	uses interface Read<uint16_t> as ReadBatteryVoltage;
	//uses interface CtpForwardingEngine;
	uses interface ForceParentInsertion;

	uses interface AMSend as UARTSend[am_id_t id];
	uses interface Packet as UARTPacket;
	uses interface AMPacket as UARTAMPacket;
 	
 }

 implementation {
 	//CPUの割り込みを考慮した実装
 	task void uartEchoTask();
	message_t packet;
	message_t uartpacket;
	message_t* recvPtr = &uartpacket;
	uint8_t msglen;
	bool sendBusy = FALSE;
	bool uartbusy = FALSE;
	bool firstTimer = TRUE;
	uint16_t seqno;
	uint16_t voltage = 0;
	
	enum {
		SEND_INTERVAL = 1024
	};

	void toggle_led(uint8_t id);

	event void ReadSensor.readDone(error_t err, uint16_t val) {}

	event void Boot.booted() {
		call SerialControl.start();
	}

	event void SerialControl.startDone(error_t err) {
		call RadioControl.start();
	}

	event void RadioControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call RadioControl.start();
		}
		else {
			//call Leds.led1Toggle();

			call DisseminationControl.start();
			call RoutingControl.start();
			if (TOS_NODE_ID == 0) {
				call RootControl.setRoot();
			} else if (TOS_NODE_ID == 2){
				call ForceParentInsertion.forceParent(0);
			} else {
				call ForceParentInsertion.forceParent(TOS_NODE_ID - 1);
			}
			
			seqno = 0;
			call Timer.startPeriodic(SEND_INTERVAL);
		}
	}

	event void RadioControl.stopDone(error_t err) {}
	event void SerialControl.stopDone(error_t err) {}

	void failedSend() {
		dbg("App", "%s: Send failed.\n", __FUNCTION__);
		call CollectionDebug.logEvent(NET_C_DBG_1);
	}

	void sendMessage() {

		//msgに入れるためのそれぞれのパラメータを取得してmsgに格納
		//msgにpacketのポインタをゲッチュ
		UsaNetworkMsg* msg = (UsaNetworkMsg*)call Send.getPayload(&packet, sizeof(UsaNetworkMsg));
		//uint16_t metric;
		am_addr_t parent = 0;
		//uint8_t hop;
		
		if (TOS_NODE_ID == 1) {
			call ForceParentInsertion.forceParent(0);
		}
		if (TOS_NODE_ID == 2) {
			call ForceParentInsertion.forceParent(0);
		}
		if (seqno > 10 && TOS_NODE_ID == 3) {
			call ForceParentInsertion.forceParent(1);
		}

		call CtpInfo.getParent(&parent);
		//call CtpInfo.getEtx(&metric);
//		hop = call CtpPacket.getThl(&packet);
		//hopToSource = call CtpPacket.getHopToSource(&packet);
		//passNodeId = call CtpPacket.getPassNodeId(&packet);
		call ReadBatteryVoltage.read();


		msg->source = TOS_NODE_ID;
		msg->seqno = seqno;
		//msg->data = 0xCAFE;
		msg->parent = parent;
		//msg->metric = metric;
		msg->voltage = voltage;

		if (call Send.send(&packet, sizeof(UsaNetworkMsg)) != SUCCESS) {
			failedSend();
			//call Leds.led0On();
			dbg("UsaNetworkC", "%s: Tranmission failed.\n", __FUNCTION__);
		}
		else {
			sendBusy = TRUE;
			seqno++;
			dbg("UsaNetworkC", "%s: Transmission succeeded.\n", __FUNCTION__);
		}
	}

	event void Timer.fired() {
		dbg("UsaNetworkC", "UsaNetworkC: Timer fired.\n");
		if (!sendBusy)
			sendMessage();
	}

	event void Send.sendDone(message_t* m, error_t err) {
		if (err == SUCCESS) {
			//call Leds.led0On();
		}
		call Leds.led1Toggle();
		sendBusy = FALSE;
		dbg("UsaNetworkC", "Send completed.\n");
	}
	
	event void ReadBatteryVoltage.readDone(error_t result, uint16_t data) {
		if(result != SUCCESS) {
			data = 0xffff;
		}
		voltage = (uint16_t)((uint32_t)1110 * (uint32_t)1024 /
				  (uint32_t)data);
	}

	event void DisseminationPeriod.changed() {
		const uint32_t* newVal = call DisseminationPeriod.get();
		call Timer.stop();
		call Timer.startPeriodic(*newVal);
	}

	uint8_t prevSeq = 0;
	uint8_t firstMsg = 0;

	event message_t* Receive.receive(message_t* msg, void* payload, 
									uint8_t len) {
		UsaNetworkMsg* addMsg = (UsaNetworkMsg*)payload;
		
		addMsg->passNodeId = call CollectionPacket.getPassNodeId(msg);
		addMsg->hopToSource = call CollectionPacket.getHopToSource(msg);

		dbg("UsaNetworkC", "Received packet at %s from node %hhu.\n", 
			sim_time_string(), call CollectionPacket.getOrigin(msg));	
		call Leds.led1Toggle();

		

		if (call CollectionPacket.getOrigin(msg) == 1) {
			if (firstMsg == 1) {
				if (call CollectionPacket.getSequenceNumber(msg)
					- prevSeq > 1) {
					call Leds.led2On();
				}
			}
			else {
				firstMsg = 1;
			}
			prevSeq = call CollectionPacket.getSequenceNumber(msg);
		}
		
		if (!call Pool.empty() && call Queue.size() < call Queue.maxSize()) {
			message_t* tmp = call Pool.get();
			call Queue.enqueue(msg);
			if (!uartbusy) {
				post uartEchoTask();
			}
			return tmp;
		}

		return msg;
	}
	//Base StationがSerial通信する
	task void uartEchoTask() {
		dbg("Traffic", "Sending packet to UART.\n");
		if (call Queue.empty()) {
			return;
		}
		else if (!uartbusy) {
			message_t* msg = call Queue.dequeue();
			am_addr_t addr = call AMPacket.destination(msg);
			uint8_t len = call RadioPacket.payloadLength(msg);
			am_id_t id = call AMPacket.type(msg);
			am_addr_t src = call AMPacket.source(msg);

			call UARTPacket.clear(msg);
			call UARTAMPacket.setSource(msg, src);

			id = AM_USANETWORKMSG;

			if (call UARTSend.send[id](addr, msg, len) == SUCCESS) {
				uartbusy = TRUE;						
			}
			else {
				call CollectionPacket.getSequenceNumber(msg),
				call CollectionPacket.getOrigin(msg),
				call AMPacket.destination(msg);
			}
		}
	}
	
	event void UARTSend.sendDone[am_id_t id](message_t* msg, error_t error) {
		dbg("Traffic", "UART send done.\n");
		uartbusy = FALSE;
		call Pool.put(msg);
		if (!call Queue.empty()) {
			post uartEchoTask();
		}
	}

	void toggle_led(uint8_t id) {
		switch(id) {
			case 0:
				call Leds.led0Toggle();
				break;
			case 1:
				call Leds.led1Toggle();
				break;
			case 2:
				call Leds.led2Toggle();
				break;
		}
	}

  /* Default implementations for CollectionDebug calls.
   * These allow CollectionDebug not to be wired to anything if debugging
   * is not desired. */

    default command error_t CollectionDebug.logEvent(uint8_t type) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        return SUCCESS;
    }
 
}
