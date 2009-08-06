/*
 * mm3_comm.h
 * Copyright 2009, Eric B. Decker
 * Mam-Mark Project
 */

#ifndef __MM3_COMM_H__
#define __MM3_COMM_H__


#define MM3_COMM_CLIENTS "MM3_COMM_CLIENTS"

enum {
  MM3_COMM_CONTROL	=      unique(MM3_COMM_CLIENTS),
  MM3_COMM_DATA		=      unique(MM3_COMM_CLIENTS),
  MM3_COMM_DEBUG	=      unique(MM3_COMM_CLIENTS),
  MM3_COMM_NUM_CLIENTS	= uniqueCount(MM3_COMM_CLIENTS),
};

#endif  /* __MM3_COMM_H__ */
