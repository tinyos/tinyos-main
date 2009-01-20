
#include <Storage.h>
#include <Shell.h>
#include "imgNum2volumeId.h"
#include "Deluge.h"

module NWProgP {
  provides interface BootImage;
  uses {
    interface Boot;
    interface UDP as Recv;
    interface StorageMap[uint8_t imag_num];
    interface NetProg;
    interface BlockWrite[uint8_t img_num];
    interface Resource;
    interface ShellCommand;
    interface DelugeMetadata;
    interface Timer<TMilli> as RebootTimer;
    event void storageReady();
  }
} implementation {

  enum {
    S_IDLE,
    S_BUSY,
  };
  uint8_t state;
  struct sockaddr_in6 endpoint;
  prog_reply_t reply;

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
    state = S_IDLE;
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
        buffer = ip_malloc(len);
        if (buffer == NULL) {
          error = ENOMEM;
          break;
        }
        memcpy(buffer, req->data, len);
        error = call BlockWrite.write[imgNum](req->offset,
                                              buffer,
                                              len);
        if (error != SUCCESS) ip_free(buffer);
        break;
      default:
        error = FAIL;
      }
    }

    if (error != SUCCESS) {
      sendDone(error);
      call Resource.release();
    } else {
      state = S_BUSY;
    }
  }

  event void BlockWrite.writeDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    if (state != S_BUSY) return;
    sendDone(error);
    call Resource.release();
    state = S_IDLE;
    ip_free(buf);
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
  char *nwprog_help_str = "nwprog [list | boot <imgno> [when] | reboot]\n";
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
        len = snprintf(reply_buf, MAX_REPLY_LEN,
                       "image: %i\n\t[size: %li]\n\t[app: %s]\n\t[user: %s]\n\t[host: %s]\n\t[arch: %s]\n\t[time: 0x%lx]\n",
                       volumeID2imgNum(imgNum), ident->size, (char *)ident->appname, (char *) ident->username,
                       (char *)ident->hostname, (char *)ident->platform, (uint32_t)ident->timestamp);
        nwprog_validvols++;
        call ShellCommand.write(reply_buf, len);
      }
      
    }
    if (++nwprog_currentvol < DELUGE_NUM_VOLUMES) {
      call DelugeMetadata.read(imgNum2volumeId(nwprog_currentvol));
    } else {
      len = snprintf(reply_buf, MAX_REPLY_LEN,
                     "%i valid image(s)\n", nwprog_validvols);
      call ShellCommand.write(reply_buf, len);
    }
  }

  event void RebootTimer.fired() {
    call BootImage.boot(boot_image);
  }


  event char *ShellCommand.eval(int argc, char **argv) {
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
      } else if (memcmp(argv[1], "erase", 5) == 0 && argc == 3) {
        uint8_t img = atoi(argv[2]);
        img = imgNum2volumeId(img);
        
        return NULL;
      }
    }
    return nwprog_help_str;
  }

  default command error_t BlockWrite.write[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockWrite.erase[uint8_t imgNum]() { return FAIL; }
  default command error_t BlockWrite.sync[uint8_t imgNum]() { return FAIL; }

}
