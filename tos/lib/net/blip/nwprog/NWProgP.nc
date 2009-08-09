
#include <Storage.h>
#include <Shell.h>
#include <BinaryShell.h>
#include "imgNum2volumeId.h"
#include "Deluge.h"
#include "PrintfUART.h"
module NWProgP {
  provides interface BootImage;
  uses {
    interface Boot;
    interface UDP as Recv;
    interface StorageMap[uint8_t imag_num];
    interface NetProg;
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
    interface Resource;
    interface DelugeMetadata;
    interface Timer<TMilli> as RebootTimer;

    event void storageReady();

#ifdef BINARY_SHELL
    interface BinaryCommand as ShellCommand;
#else
    interface ShellCommand;
#endif
  }
} implementation {

  enum {
    S_IDLE,
    S_BUSY,
  };
  uint8_t state;
  struct sockaddr_in6 endpoint;
  prog_reply_t reply;
  prog_reply_t *read_buffer;

  // SDH : if this is defined, we read back each packet after we write
  // it and check that it matches.  It turns out that this doesn't
  // actually guarantee you much, due to buffering.
#undef PARANOID

#ifdef PARANOID
  bool paranoid_read;
  uint16_t cmp_len;
  uint8_t cmp_img;
  uint32_t cmp_off;
  uint8_t cmp_buf[256];
#endif

  // Begin-added by Jaein Jeong
  command error_t BootImage.erase(uint8_t img_num) {
    error_t error = call BlockWrite.erase[img_num]();
    return error;
  }
  // End-added

  command void BootImage.reboot() {
    call NetProg.reboot();
  }

  command error_t BootImage.boot(uint8_t img_num) {
    return call NetProg.programImageAndReboot(call StorageMap.getPhysicalAddress[img_num](0));
  }

  event void Boot.booted() {
#ifdef PARANOID
    paranoid_read = FALSE;
#endif
    state = S_IDLE;
    call Recv.bind(5213);
  }

  void sendDone(error_t error) {
    reply.error = error;
    call Recv.sendto(&endpoint, &reply, sizeof(prog_reply_t));
  }

  event void Recv.recvfrom(struct sockaddr_in6 *from,
                           void *payload, uint16_t len,
                           struct ip_metadata *meta) {
    prog_req_t *req = (prog_req_t *)payload;
    uint8_t imgNum = imgNum2volumeId(req->imgno);
    error_t error = FAIL;
    void *buffer;

    // just copy the payload out and write it into flash
    // we'll send the ack from the write done event.
    if (state != S_IDLE) return;
    
    memcpy(&endpoint, from, sizeof(struct sockaddr_in6));
    memcpy(&reply.req, req, sizeof(prog_req_t));

    if (!call Resource.isOwner()) {
      error = call Resource.immediateRequest();
    }
    if (error == SUCCESS) {
      switch (req->cmd) {
      case NWPROG_CMD_ERASE:
        error = call BlockWrite.erase[imgNum]();
        break;
      case NWPROG_CMD_WRITE:
        len -= sizeof(prog_req_t);

#ifdef PARANOID
        if (len > sizeof(cmp_buf)) {
          error = ENOMEM;
          break;
        }
        memcpy(cmp_buf, req->data, len);
        cmp_len = len;
        cmp_off = req->cmd_data.offset;
        cmp_img = imgNum;
#endif
        
        buffer = ip_malloc(len);
        if (buffer == NULL) {
          error = ENOMEM;
          break;
        }
        memcpy(buffer, req->data, len);
        error = call BlockWrite.write[imgNum](req->cmd_data.offset,
                                              buffer,
                                              len);
        if (error != SUCCESS) ip_free(buffer);
        break;
      case NWPROG_CMD_READ: {

        read_buffer = (prog_reply_t *)ip_malloc(64 + sizeof(prog_reply_t));
        if (read_buffer == NULL) {
          error = ENOMEM;
          break;
        }
        memcpy(&read_buffer->req, req, sizeof(prog_req_t));
        error = call BlockRead.read[imgNum](req->cmd_data.offset,
                                            read_buffer->req.data,
                                            64);
        if (error != SUCCESS) {
          ip_free(read_buffer);
        }
        break;
      }
      default:
        error = FAIL;
      }
    }

    if (error != SUCCESS) {
      sendDone(error);
      if (call Resource.isOwner()) {
        call Resource.release();
      }
    } else {
      state = S_BUSY;
    }
  }

  event void BlockWrite.writeDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    if (state != S_BUSY) return;

#ifdef PARANOID
    if (len != cmp_len) {
      printfUART("WARNING: write length changed from %i to %lu!\n", cmp_len, len);
    }
    if (addr != cmp_off) {
      printfUART("WARNING: write address changed from %li to %li!\n", cmp_off, addr);
    }
    if (img_num != cmp_img) {
      printfUART("WARNING: write volume changed from %i to %i\n", cmp_img, img_num);
    }
    if (memcmp(buf, cmp_buf, cmp_len) != 0) {
      printfUART("WARNING: write data changed during call!\n");
    }
    memset(buf, 0, cmp_len);
    if (call BlockRead.read[cmp_img](cmp_off, buf, cmp_len) == SUCCESS) {
      paranoid_read = TRUE;
      return;
    } 


#else
    ip_free(buf);
#endif

    if (error == SUCCESS) {
      call BlockWrite.sync[img_num]();
    } else {
      state = S_IDLE;
      call Resource.release();
      sendDone(error);
    }
  }
  event void BlockRead.readDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {

#ifdef PARANOID
    if (paranoid_read) {
      if (len != cmp_len) {
        printfUART("WARNING: read length changed from %u to %lu!\n", cmp_len, len);
      }
      if (addr != cmp_off) {
        printfUART("WARNING: read address changed from %li to %li!\n", cmp_off, addr);
      }
      if (img_num != cmp_img) {
        printfUART("WARNING: read volume changed from %i to %i\n", cmp_img, img_num);
      }
      if (memcmp(buf, cmp_buf, cmp_len) != 0) {
        printfUART("WARNING: write data changed during call!\n");
      } else {
        printfUART("SUCCESS: write verified!\n");
      }

      paranoid_read = FALSE;
      ip_free(buf);
      if (error == SUCCESS) {
        call BlockWrite.sync[img_num]();
      } else {
        call Resource.release();
        state = S_IDLE;
        sendDone(error);
      }

      return;
    }
#endif


    if (state != S_BUSY || buf != read_buffer->req.data) return;
    call Resource.release();

    read_buffer->error = error;
    call Recv.sendto(&endpoint, read_buffer, sizeof(prog_reply_t) + 64);

    ip_free(read_buffer);
    state = S_IDLE;
  }

  event void BlockWrite.eraseDone[uint8_t img_num](error_t error) {
    if (state != S_BUSY) return;
    if (error == SUCCESS) 
      call BlockWrite.sync[img_num]();
    else {
      sendDone(error);
      state = S_IDLE;
      call Resource.release();
    }
  }

  event void BlockWrite.syncDone[uint8_t img_num](error_t error) { 
    if (state != S_BUSY) return;
    sendDone(error);
    state = S_IDLE;
    call Resource.release();
  }

  event void Resource.granted() {

  }


  /*
   * Shell command implementation
   */
  uint8_t nwprog_currentvol, nwprog_validvols;
  uint8_t boot_image;

  uint8_t volumeID2imgNum(uint8_t volumeID) {
    switch(volumeID) {
    case VOLUME_GOLDENIMAGE: return 0;
    case VOLUME_DELUGE1: return 1;
    case VOLUME_DELUGE2: return 2;
    case VOLUME_DELUGE3: return 3;
    }
  }
  event void DelugeMetadata.readDone(uint8_t imgNum, DelugeIdent* ident, error_t error) {
    int len;
    char *reply_buf = call ShellCommand.getBuffer(MAX_REPLY_LEN);
    if (error == SUCCESS) {
      if (ident->uidhash != DELUGE_INVALID_UID) {
#ifdef BINARY_SHELL
        nx_struct cmd_payload *payload = (nx_struct cmd_payload *)reply_buf;
        prog_req_t *rep = (prog_req_t *)payload->data;
        nx_struct ShortDelugeIdent *i = (nx_struct ShortDelugeIdent *)rep->data;
        rep->cmd = NWPROG_CMD_IMAGEIFO;
        rep->imgno = volumeID2imgNum(imgNum);
        memcpy(i->appname, ident->appname, 16);
        memcpy(i->username, ident->username, 16);
        memcpy(i->hostname, ident->hostname, 16);
        i->timestamp = ident->timestamp;
        nwprog_validvols++;
        call ShellCommand.write(payload, sizeof(nx_struct cmd_payload) + 
                                sizeof(prog_reply_t) + sizeof(nx_struct ShortDelugeIdent));

#else
        len = snprintf(reply_buf, MAX_REPLY_LEN,
                       "image: %i\n\t[size: %li]\n\t[app: %s]\n\t[user: %s]\n\t[host: %s]\n\t[arch: %s]\n\t[time: 0x%lx]\n",
                       volumeID2imgNum(imgNum), ident->size, (char *)ident->appname, (char *) ident->username,
                       (char *)ident->hostname, (char *)ident->platform, (uint32_t)ident->timestamp);
        nwprog_validvols++;
        call ShellCommand.write(reply_buf, len);
#endif
      }
      
    }
    if (++nwprog_currentvol < DELUGE_NUM_VOLUMES) {
      call DelugeMetadata.read(imgNum2volumeId(nwprog_currentvol));
    } else {
#ifdef BINARY_SHELL
      nx_struct cmd_payload *payload = (nx_struct cmd_payload *)reply_buf;
      prog_req_t *rep = (prog_req_t *)payload->data; 
      rep->cmd = NWPROG_CMD_READDONE;
      rep->cmd_data.nimages = nwprog_validvols;
      call ShellCommand.write(payload, sizeof(nx_struct cmd_payload) + sizeof(prog_req_t));
#else
      len = snprintf(reply_buf, MAX_REPLY_LEN,
                     "%i valid image(s)\n", nwprog_validvols);
      call ShellCommand.write(reply_buf, len);
#endif
    }
  }

  event void RebootTimer.fired() {
    call BootImage.boot(boot_image);
  }

#ifdef BINARY_SHELL
  event void ShellCommand.dispatch(nx_struct cmd_payload *data, int len) {
    nx_struct prog_req *req = (nx_struct prog_req *)data->data;
    nx_struct cmd_payload *rep;
    prog_reply_t *rc;
    int error = NWPROG_ERROR_OK;

    switch (req->cmd) {
    case NWPROG_CMD_LIST:
      nwprog_currentvol = 0;
      nwprog_validvols = 0;
      call DelugeMetadata.read(imgNum2volumeId(nwprog_currentvol));
      return;
      break;
    case NWPROG_CMD_BOOT:
      call ShellCommand.write(data, len);

      boot_image = imgNum2volumeId(req->imgno);
      call RebootTimer.startOneShot(req->cmd_data.when);
      break;
    case NWPROG_CMD_REBOOT:
      call BootImage.reboot();
      break;
    }
  }
#else
  event char *ShellCommand.eval(int argc, char **argv) {
    char *nwprog_help_str = "nwprog [list | boot <imgno> [when] | reboot]\n";
    if (argc >= 2) {
      if (memcmp(argv[1], "list", 4) == 0) {
        nwprog_currentvol = 0;
        nwprog_validvols = 0;
        call DelugeMetadata.read(imgNum2volumeId(nwprog_currentvol));
        return NULL;
      } else if (memcmp(argv[1], "boot", 4) == 0 && (argc == 3 || argc == 4)) {

        uint32_t when = 15;
        boot_image = atoi(argv[2]),
        boot_image = imgNum2volumeId(boot_image);
        if (argc == 4)
          when = atoi(argv[3]);
        if (when == 0)
          call RebootTimer.stop();
        else {
          char *ack = call ShellCommand.getBuffer(15);
          snprintf(ack, 15, "REBOOT %li\n", when);
          call RebootTimer.startOneShot(when);
          return ack;
        }
        return NULL;
      } else if (memcmp(argv[1], "reboot", 6) == 0) {
        call BootImage.reboot();
        return NULL;
      } 
    }
    return nwprog_help_str;
  }
#endif

  default command error_t BlockWrite.write[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockWrite.erase[uint8_t imgNum]() { return FAIL; }
  default command error_t BlockWrite.sync[uint8_t imgNum]() { return FAIL; }
  
 default command error_t BlockRead.read[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len) {return FAIL;}

  event void BlockRead.computeCrcDone[uint8_t imgNum](storage_addr_t addr, storage_len_t len,uint16_t crc, error_t error) {}


}
