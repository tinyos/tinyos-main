/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "AM.h"

/**
 * LinkMonitor - Interface to signals broken and used links in the neighborhood.
 *
 * @author Romain Thouvenin
 */

interface LinkMonitor {

  event void brokenLink(am_addr_t neighbor);

  event void refreshedLink(am_addr_t neighbor);

}
