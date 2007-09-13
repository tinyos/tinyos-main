#include <CollectionDebugMsg.h>
module UARTDebugSenderP {
    provides {
        interface CollectionDebug;
    }
    uses {
        interface Boot;
        interface Pool<message_t> as MessagePool;
        interface Queue<message_t*> as SendQueue;
        interface AMSend as UARTSend;
    }
} 
implementation {
    message_t uartPacket;
    bool sending;
    uint8_t len;
    uint16_t statLogReceived = 0;
    uint16_t statEnqueueFail = 0;
    uint16_t statSendFail = 0;
    uint16_t statSendDoneFail = 0;
    uint16_t statSendDoneOk = 0;
    uint16_t statSendDoneBug = 0;
 

    event void Boot.booted() {
        sending = FALSE;
        len = sizeof(CollectionDebugMsg);
        statSendFail = 0;
        statLogReceived = 0;
        statEnqueueFail = 0;
        statSendDoneOk = 0;
        statSendDoneFail = 0;
        statSendDoneBug = 0;
    }

    task void sendTask() {
        if (sending) {
            return;
        } else if (call SendQueue.empty()) {
            return;
        } else {
            message_t* smsg = call SendQueue.head();
            error_t eval = call UARTSend.send(AM_BROADCAST_ADDR, smsg, len);
            if (eval == SUCCESS) {
                sending = TRUE;
                return;
            } else {
                //Drop packet. Don't retry.
                statSendFail++;
                call SendQueue.dequeue();
                call MessagePool.put(smsg);
                if (! call SendQueue.empty())
                    post sendTask();
            }
        }
    }

    event void UARTSend.sendDone(message_t *msg, error_t error) {
        message_t* qh = call SendQueue.head();
        if (qh == NULL || qh != msg) {
            //bad mojo
            statSendDoneBug++;
        } else {
            call SendQueue.dequeue();
            call MessagePool.put(msg);  
            if (error == SUCCESS) 
                statSendDoneOk++;
            else 
                statSendDoneFail++;
        }
        sending = FALSE;
        if (!call SendQueue.empty()) 
            post sendTask();
    }

    command error_t CollectionDebug.logEvent(uint8_t type) {
        statLogReceived++;
        if (call MessagePool.empty()) {
            return FAIL;
        } else {
            message_t* msg = call MessagePool.get();
            CollectionDebugMsg* dbg_msg = call UARTSend.getPayload(msg, sizeof(CollectionDebugMsg));
	    if (dbg_msg == NULL) {
	      return FAIL;
	    }
	    
            memset(dbg_msg, 0, len);

            dbg_msg->type = type;
            dbg_msg->seqno = statLogReceived;

            if (call SendQueue.enqueue(msg) == SUCCESS) {
                post sendTask();
                return SUCCESS;
            } else {
                statEnqueueFail++;
                call MessagePool.put(msg);
                return FAIL;
            }
        }
    }
    /* Used for FE_SENT_MSG, FE_RCV_MSG, FE_FWD_MSG, FE_DST_MSG */
    command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg_id, am_addr_t origin, am_addr_t node) {
        statLogReceived++;
        if (call MessagePool.empty()) {
            return FAIL;
        } else {
            message_t* msg = call MessagePool.get();
            CollectionDebugMsg* dbg_msg = call UARTSend.getPayload(msg, sizeof(CollectionDebugMsg));
	    if (dbg_msg == NULL) {
	      return FAIL;
	    }
            memset(dbg_msg, 0, len);

            dbg_msg->type = type;
            dbg_msg->data.msg.msg_uid = msg_id;
            dbg_msg->data.msg.origin = origin;
            dbg_msg->data.msg.other_node = node;
            dbg_msg->seqno = statLogReceived;

            if (call SendQueue.enqueue(msg) == SUCCESS) {
                post sendTask();
                return SUCCESS;
            } else {
                statEnqueueFail++;
                call MessagePool.put(msg);
                return FAIL;
            }
        }
    }
    /* Used for TREE_NEW_PARENT, TREE_ROUTE_INFO */
    command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        statLogReceived++;
        if (call MessagePool.empty()) {
            return FAIL;
        } else {
            message_t* msg = call MessagePool.get();
            CollectionDebugMsg* dbg_msg = call UARTSend.getPayload(msg, sizeof(CollectionDebugMsg));
	    if (dbg_msg == NULL) {
	      return FAIL;
	    }
            memset(dbg_msg, 0, len);

            dbg_msg->type = type;
            dbg_msg->data.route_info.parent = parent;
            dbg_msg->data.route_info.hopcount = hopcount;
            dbg_msg->data.route_info.metric = metric;
            dbg_msg->seqno = statLogReceived;

            if (call SendQueue.enqueue(msg) == SUCCESS) {
                post sendTask();
                return SUCCESS;
            } else {
                statEnqueueFail++;
                call MessagePool.put(msg);
                return FAIL;
            }
        }
    }
    /* Used for DBG_1 */ 
    command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        statLogReceived++;
        if (call MessagePool.empty()) {
            return FAIL;
        } else {
            message_t* msg = call MessagePool.get();
            CollectionDebugMsg* dbg_msg = call UARTSend.getPayload(msg, sizeof(CollectionDebugMsg));
	    if (dbg_msg == NULL) {
	      return FAIL;
	    }
            memset(dbg_msg, 0, len);

            dbg_msg->type = type;
            dbg_msg->data.arg = arg;
            dbg_msg->seqno = statLogReceived;

            if (call SendQueue.enqueue(msg) == SUCCESS) {
                post sendTask();
                return SUCCESS;
            } else {
                statEnqueueFail++;
                call MessagePool.put(msg);
                return FAIL;
            }
        }
    }
    /* Used for DBG_2, DBG_3 */
    command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        statLogReceived++;
        if (call MessagePool.empty()) {
            return FAIL;
        } else {
            message_t* msg = call MessagePool.get();
            CollectionDebugMsg* dbg_msg = call UARTSend.getPayload(msg, sizeof(CollectionDebugMsg));
	    if (dbg_msg == NULL) {
	      return FAIL;
	    }
            memset(dbg_msg, 0, len);

            dbg_msg->type = type;
            dbg_msg->data.dbg.a = arg1;
            dbg_msg->data.dbg.b = arg2;
            dbg_msg->data.dbg.c = arg3;
            dbg_msg->seqno = statLogReceived;

            if (call SendQueue.enqueue(msg) == SUCCESS) {
                post sendTask();
                return SUCCESS;
            } else {
                statEnqueueFail++;
                call MessagePool.put(msg);
                return FAIL;
            }
        }
    }

}
    
