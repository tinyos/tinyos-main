
#include <PrintfUART.h>
#include <lib6lowpan/ip.h>

module TestLinkLocalC {
  uses {
    interface Boot;
    interface SplitControl;
    interface UDP as Sock;
    interface Timer<TMilli>;
    interface Leds;
  }
} implementation {
  nx_struct echo_state {
    nx_int8_t cmd;
    nx_uint32_t seqno;
  } m_data;

  enum {
    SVC_PORT = 10210,
    CMD_ECHO = 1,
    CMD_REPLY = 2,
  };

  event void Boot.booted() {
    printfUART_init();
    call SplitControl.start();
    m_data.seqno = 0;
  }

  event void SplitControl.startDone(error_t e) {
    call Timer.startPeriodic(2048);
    call Sock.bind(SVC_PORT);
  }

  event void SplitControl.stopDone(error_t e) {}

  event void Timer.fired() {
    struct sockaddr_in6 dest;

    inet_pton6("ff02::1", &dest.sin6_addr);
    dest.sin6_port = htons(SVC_PORT);
    
    m_data.cmd = CMD_ECHO;
    m_data.seqno ++;

    call Sock.sendto(&dest, &m_data, sizeof(m_data));
    call Leds.led0Toggle();
  }

  event void Sock.recvfrom(struct sockaddr_in6 *src, void *payload,                                                               
                           uint16_t len, struct ip6_metadata *meta) {
    nx_struct echo_state *cmd = payload;
    printfUART("TestLinkLocalC: recv from: ");
    printfUART_in6addr(&src->sin6_addr);
    printfUART("\n");

    if (cmd->cmd == CMD_ECHO) {
      cmd->cmd = CMD_REPLY;
      call Sock.sendto(src, payload, len);
      call Leds.led1Toggle();
    } else {
      printfUART("TestLinkLocalC: reply seqno: %li\n", cmd->seqno);
      call Leds.led2Toggle();
    }
  }
}
