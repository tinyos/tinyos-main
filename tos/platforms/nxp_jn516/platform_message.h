#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include <Jn516.h>
#include <Serial.h>

typedef union message_header {
  jn516_header_t jn516;
  serial_header_t serial;
} message_header_t;

typedef union message_footer {
  jn516_footer_t jn516;
} message_footer_t;

typedef union message_metadata {
  jn516_metadata_t jn516;
  serial_metadata_t serial;
} message_metadata_t;

#endif
