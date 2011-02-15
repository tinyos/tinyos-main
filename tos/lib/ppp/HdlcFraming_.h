/** Internal HDLC framing data structures, pulled out for white-box
 * testing. */
#ifndef PPP_HDLC_FRAMING_INTERNAL_H
#define PPP_HDLC_FRAMING_INTERNAL_H

enum {
  /** The sole address field value permitted by RFC1662 */
  HDLC_AllStationsAddress = 0xff,
  /** The sole control field value permitted by RFC1662 */
  HDLC_ControlFieldValue = 0x03,
  /** The value used to indicate a frame delimiter */
  HDLC_FlagSequence = 0x7e,
  /** The prefix byte used to indicate an escaped byte */
  HDLC_ControlEscape = 0x7d,
  /** The value used to escape a data byte */
  HDLC_ControlModifier = 0x20,
};

enum {
  /** The number of octets in a frame check sequence */
  FCS_LENGTH = 2,
  /** If the size of the buffer provided by the fragment pool isn't
   * at least this big, just pretend there's no space at all. */
  MinimumUsefulBufferLength = 16 + FCS_LENGTH,
};

/** State of the HDLC automaton that processes incoming characters to
 * create frame data. */
typedef enum RXState_e {
  /** Waiting for a flag sequence delimiter.  State is initial, and
   * is re-entered whenever synchronization is lost. */
  RX_unsynchronized,
  /** Delimiter has been received, we are awaiting the address byte
   * (or, if address compression is enabled, whatever the first byte
   * is). */
  RX_atAddress,
  /** Address has been received, we are awaiting the control field byte. */
  RX_atControlField,
  /** Have received the delimiter and are at the point of receiving
   * data; all is good. */
  RX_receive,
  /** Received a valid control escape, waiting for the following
   * data character. */
  RX_escaped,
} RXState_e;

/** State of the task that generates framed data written to the UART */
typedef enum TXState_e {
  /** No transmission is in progress.  txStart_ should be null. */
  TX_idle,
  /** Actively transmitting the payload of a frame. */
  TX_active,
  /** Actively transmitting the CRC of a frame. */
  TX_sendCrc,
} TXState_e;

typedef enum ReceiveFrameState_e {
  /** Indicates that the frame is available for use.
   * inputEngine_task transitions into this state when a frame is
   * released; the UART interrupt transitions from this state when a
   * new buffer is installed. */
  RFS_unused,
  /** The frame's fragment has been allocated and is being used to
   * store incoming data. */
  RFS_receiving,
  /** The incoming frame has been completed, the length updated, the
   * remainder of the fragment released.  inputEngine_task has the
   * responsibility for further transitions. */
  RFS_received,
  /** inputEngine_task sets the frame to processing when it notifies
   * the client of frame availability. */
  RFS_processing,
  /** Processing is complete and any hold has been released.
   * Handoff to inputEngine_task to reclaim the frame fragment. */
  RFS_releasable,
} ReceiveFrameState_e;

/** A structure used to hold a fragment from the HDLC reception frame pool. */
typedef struct HdlcRxFrame_t {
  uint8_t* start;
  uint8_t* end;
  uint8_t frame_state;
} HdlcRxFrame_t;

#endif /* PPP_HDLC_FRAMING_INTERNAL_H */
