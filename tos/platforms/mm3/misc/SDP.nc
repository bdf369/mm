/*
 * SD - low level Secure Digital storage driver
 *
 * Copyright (c) 2008, Eric B. Decker
 * All rights reserved.
 */

#include <msp430usart.h>
#include <msp430hardware.h>
#include "hardware.h"
#include "sd.h"

#define SD_PUT_GET_TO 1024
#define SD_PARANOID

module SDP {
  provides {
    interface SD;
    interface Init;
  }
  uses {
    interface HplMsp430Usart as Usart;
    interface Panic;
  }
}

implementation {

  noinit sd_cmd_blk_t sd_cmd;
  noinit uint16_t     sd_r1b_timeout;
  noinit uint16_t     sd_rd_timeout;
  noinit uint16_t     sd_wr_timeout;
  noinit uint16_t     sd_reset_timeout;
  noinit uint16_t     sd_busy_timeout;
  noinit bool         sd_busyflag;
  noinit uint16_t     sd_reset_idles;

  void sd_wait_notbusy();

  void sd_chk_clean() {
    uint8_t tmp;

#ifdef SD_PARANOID
    if (!(U1_TX_EMPTY)) {
      call Panic.panic(PANIC_SD, 1, 0, 0, 0, 0);
      /*
       * how to clean out the transmitter?  It could be
       * hung.  Which would be weird.
       */
    }
    if (U1_OVERRUN) {
      call Panic.panic(PANIC_SD, 2, U1RCTL, 0, 0, 0);
      URCTL &= ~OE;
    }
    if (U1_RX_RDY) {
      tmp = U1RXBUF;
      call Panic.panic(PANIC_SD, 3, tmp, 0, 0, 0);
    }
#else
    if (U1_OVERRUN)
      U1RCTL &= ~OE;
    if (U1_RX_RDY)
      tmp = U1RXBUF;
#endif
  }

  void sd_put(uint8_t tx_data) {
    uint16_t i;

    sd_chk_clean();
    U1TXBUF = tx_data;

    i = SD_PUT_GET_TO;
    while ( !(U1_RX_RDY) && i > 0)
      i--;
    if (i == 0)				/* rx timeout */
      call Panic.panic(PANIC_SD, 4, 0, 0, 0, 0);
    if (U1_OVERRUN)
      call Panic.panic(PANIC_SD, 5, 0, 0, 0, 0);

    /* clean out RX buf and the IFG. */
    U1_CLR_RX;
    tx_data = U1RXBUF;
  }


  uint8_t sd_get() {
    uint16_t i;

    sd_chk_clean();
    U1TXBUF = 0xff;

    i = SD_PUT_GET_TO;
    while ( !U1_RX_RDY && i > 0)
      i--;

    if (i == 0)				/* rx timeout */
      call Panic.panic(PANIC_SD, 6, 0, 0, 0, 0);

    if (U1_OVERRUN)
      call Panic.panic(PANIC_SD, 7, 0, 0, 0, 0);
    U1_CLR_RX;
    return(U1RXBUF);
  }


  void sd_packarg(uint32_t value) {
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    cmd->arg[0] = (uint8_t) (value >> 24);
    cmd->arg[1] = (uint8_t) (value >> 16);
    cmd->arg[2] = (uint8_t) (value >> 8);
    cmd->arg[3] = (uint8_t) (value);
  }


  int sd_send_cmd55() {
    uint16_t i;
    uint8_t  tmp;
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    sd_put(SD_APP_CMD | 0x40);		/* CMD55 */
    sd_put(0);
    sd_put(0);
    sd_put(0);
    sd_put(0);
    sd_put(0xff);				/* crc, don't care */

    i=0;
    do {
      tmp = sd_get();
      i++;
    } while((tmp > 127) && (i < SD_CMD_TIMEOUT));

    cmd->rsp55 = tmp;
    cmd->stage_count = i;

    if (i >= SD_CMD_TIMEOUT) {
      call Panic.panic(PANIC_SD, 8, i, 0, 0, 0);
      return FAIL;
    }

    tmp = sd_get();		/* finish the command */
    if (tmp != 0xff)
      call Panic.panic(PANIC_SD, 9, tmp, 0, 0, 0);
    return SUCCESS;
  }


  /* sd_send_command
   *
   * Send a command to the SD card waiting for the response (length given
   * in the command block.
   *
   * broken up into several stages and marked accordingly in the command block
   *
   * stage 1: For ACMDs send CMD55.  If not an acmd set rsp55 to 0x55 to flag.
   * stage 2: Send the command and wait for response.  Could time out.  stage_count
   *          holds the time out value if it does.
   * stage 3: extra clocks at end of cmd/response
   * stage 4: R1B busy wait.
   */

  int sd_send_command() {
    uint16_t i;
    uint16_t rsp_len;
    uint8_t  tmp;
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    rsp_len = cmd->rsp_len & RSP_LEN_MASK;
    if (rsp_len != 1 && rsp_len != 2 && rsp_len != 5) {
      call Panic.panic(PANIC_SD, 10, rsp_len, 0, 0, 0);
      return FAIL;
    }
    if (SD_CSN == 0)		// already selected
      call Panic.warn(PANIC_SD, 12, 0, 0, 0, 0);

    SD_CSN = 0;
    cmd->stage = 1;
    if (cmd->cmd & ACMD_FLAG) {
      tmp = sd_send_cmd55();
      if (tmp) {
	/* failed, how odd */
	SD_CSN = 1;
	call Panic.panic(PANIC_SD, 11, tmp, 0, 0, 0);
	return FAIL;
      }
    } else
      cmd->rsp55 = 0x55;

    cmd->stage = 2;
    sd_put((cmd->cmd & 0x3F) | 0x40);
    i = 0;
    do
      sd_put(cmd->arg[i++]);
    while (i < 4);

    /* This is the CRC. It only matters what we put here for the first
       command. Otherwise, the CRC is ignored for SPI mode unless we
       enable CRC checking which we don't because it is a royal pain
       in the ass.
    */
    sd_put(0x95);

    /* Wait for a response.  */
    i=0;
    do {
      tmp = sd_get();
      i++;
    } while ((tmp & 0x80) && (i < SD_CMD_TIMEOUT));

    cmd->rsp[0] = tmp;		/* first byte of the response */
    cmd->stage_count = i;

    /* Just bail if we never got a response */
    if (i >= SD_CMD_TIMEOUT) {
      /* stage 2 bail, timeout */
      call Panic.panic(PANIC_SD, 12, tmp, 0, 0, 0);
      SD_CSN = 1;
      return FAIL;
    }

    /* get rest of response if needed */
    i = 1;
    while (i < rsp_len)
      cmd->rsp[i++] = sd_get();

    cmd->stage = 3;
    tmp = sd_get();
    if (tmp != 0xff) {
      call Panic.panic(PANIC_SD, 13, tmp, 0, 0, 0);
    }

    /* If the response is a "busy" type (R1B), then there's some
     * special handling that needs to be done. The card will
     * output a continuous stream of zeros, so the end of the BUSY
     * state is signaled by any nonzero response. The bus idles
     * high.
     */
    if (cmd->rsp_len & R1B_FLAG) {
      cmd->stage = 4;
      i = 0;
      do {
	i++;
	tmp = sd_get();
      } while (tmp != 0xFF);
      sd_r1b_timeout = i;
//	cmd->stage_count = i;
      sd_put(0xff);
    }
    cmd->stage = 0;
    SD_CSN = 1;
    return SUCCESS;
  }


  /* sd_delay: send idle data while clocking */

  void sd_delay(uint16_t number) {
    uint16_t i;

    for(i = 0; i < number; i++)
      sd_put(0xff);
  }


  command error_t Init.init() {
    uint8_t i;

    sd_cmd.cmd = 0xf0;
    sd_cmd.rsp_len = 0;
    for (i = 0; i < 4; i++)
      sd_cmd.arg[i] = 0xf0;
    for (i = 0; i < 5; i++)
      sd_cmd.rsp[i] = 0xf0;
    sd_cmd.rsp55 = 0xf0;
    sd_cmd.stage = 0;
    sd_cmd.stage_count = 0;

    sd_r1b_timeout = 0xf0f0;
    sd_rd_timeout = 0xf0f0;
    sd_wr_timeout = 0xf0f0;
    sd_reset_timeout = 0xf0f0;
    sd_busy_timeout = 0xf0f0;
    sd_busyflag = FALSE;
    return SUCCESS;
  }


  /* Set block length (size of data transaction)

  input:  length	size of block
  output: rtn:		0 block length set okay.
  non-zero, error return from send_command
  */

  int sd_set_blocklen(uint32_t length) {
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    sd_packarg(length);
    cmd->cmd     = SD_SET_BLOCKLEN;
    cmd->rsp_len = SD_SET_BLOCKLEN_R;
    return(sd_send_command());
  }


  /* Reset the SD card.
     ret:	    0,	card initilized
     non-zero, error return

     SPI SD initialization sequence:
     CMD0 (reset), CMD55 (app cmd), ACMD41 (app_send_op_cond), CMD58 (send ocr)
  */

  command error_t SD.reset() {
    uint16_t i;
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    call Usart.setUbr(SPI_400K_DIV);
    sd_packarg(0);

    /* Clock out at least 74 bits of idles (0xFF).  This allows
       the SD card to complete its power up prior to talking to
       the card.

       When experimenting with different SPI clocks (4M ... 400K) and
       the power up sequence.  ie.

       power off SD
       wait 1 sec
       power on
       set spi speed
       select SD
       sd_reset
       preliminaries
       deselect sd
       sd_delay(100)

       If sd_delay is set to 10 then a power on delay is needed.  The
       amount of delay depends on which SPI clock is used.  Using an
       sd_delay of 100 eliminates the need for the power on delay and
       doesn't appreciably change the reset time which is dominated
       by the GO_OP (A41) time.
    */

    SD_CSN = 1;
    sd_delay(SD_RESET_IDLES);

    /* Put the card in the idle state, non-zero return -> error */
    cmd->cmd     = SD_FORCE_IDLE;
    cmd->rsp_len = SD_FORCE_IDLE_R;
    if (sd_send_command()) {
      call Panic.panic(PANIC_SD, 14, 0, 0, 0, 0);
      return FAIL;
    }


    /* Now wait until the card goes idle. Retry at most SD_IDLE_WAIT_MAX times */
    i = 0;
    do {
      i++;
      cmd->cmd     = SD_GO_OP;
      cmd->rsp_len = SD_GO_OP_R;
      if (sd_send_command()) {
	call Panic.panic(PANIC_SD, 15, 0, 0, 0, 0);
	return FAIL;
      }
//    } while ((cmd->rsp[0] & MSK_IDLE) == MSK_IDLE && i < SD_IDLE_WAIT_MAX);
    } while ((cmd->rsp[0] & MSK_IDLE) == MSK_IDLE);
    sd_reset_timeout = i;

    //    if (i >= SD_IDLE_WAIT_MAX)		/* did we bail? */
    //	return(SD_INIT_TIMEOUT);

    cmd->cmd     = SD_SEND_OCR;
    cmd->rsp_len = SD_SEND_OCR_R;
    if (sd_send_command()) {
      call Panic.panic(PANIC_SD, 16, 0, 0, 0, 0);
      return FAIL;
    }

    /* At a very minimum, we must allow 3.3V. */
    if ((cmd->rsp[2] & MSK_OCR_33) != MSK_OCR_33) {
      call Panic.panic(PANIC_SD, 17, cmd->rsp[2], 0, 0, 0);
      return FAIL;
    }

    /* Set the block length */
    if (sd_set_blocklen(SD_BLOCKSIZE)) {
      call Panic.panic(PANIC_SD, 18, 0, 0, 0, 0);
      return FAIL;
    }

    /* If we got this far, initialization was OK. */
    call Usart.setUbr(SPI_2M_DIV);
    return SUCCESS;
  }


  /*
   * sd_read_data_direct: read data from the SD after sending a command
   *    does not use dma and waits for the data.
   */

  error_t sd_read_data_direct(uint16_t data_len, uint8_t *data) {
    uint16_t i;
    uint8_t  tmp;
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    sd_wait_notbusy();
    if (sd_send_command()) {
      call Panic.panic(PANIC_SD, 19, 0, 0, 0, 0);
      return FAIL;
    }

    /* Check for an error, like a misaligned read */
    if (cmd->rsp[0] != 0) {
      call Panic.panic(PANIC_SD, 20, 0, 0, 0, 0);
      return FAIL;
    }

    /* Re-assert CS to continue the transfer */
    SD_CSN = 0;

    /* Wait for the token */
    i=0;
    do {
      tmp = sd_get();
      i++;
    } while ((tmp == 0xFF) && i < SD_READ_TIMEOUT);
    sd_rd_timeout = i;

    if ((tmp & MSK_TOK_DATAERROR) == 0 || i >= SD_READ_TIMEOUT) {
      /*
       * Clock out a byte before returning, let SD finish
       * what is this based on?
       */
      sd_put(0xff);

      /* The card returned an error, or timed out. */
      return FAIL;
    }

    for (i = 0; i < data_len; i++)
      data[i] = sd_get();

    /* Ignore the CRC */
    sd_get();
    sd_get();

    SD_CSN = 1;
    /* Send some extra clocks so the card can finish */
    sd_delay(2);

    return SUCCESS;
  }


  /* sd_check_crc
   *
   * i: data	pointer to a 512 byte + 2 bytes of CRC at end (514)
   *
   * o: rtn	0 (SUCCESS) if crc is okay
   *		1 (FAIL) crc didn't check.
   */

  int sd_check_crc(uint8_t *data, uint16_t len, uint16_t crc) {
    return SUCCESS;
  }


  /* sd_compute_crc
   *
   * append a crc computed over the data buffer pointed at by data
   *
   * i: data	ptr to 512 bytes of data (with 2 additional bytes available
   *		at the end for the crc (total size 514).
   * o: none
   */

  void sd_compute_crc(uint8_t *data) {
    //    data[512] = 0;
    //    data[513] = 0;
  }


  /*
   * sd_read_data_dma: read data from the SD after sending a command
   */

  error_t sd_read_data_dma(uint16_t data_len, uint8_t *data) {
    uint16_t i, crc;
    uint8_t  tmp, idle_byte;
    sd_cmd_blk_t *cmd;
    
    cmd = &sd_cmd;
    if (sd_send_command())
      return FAIL;

    /* Check for an error, like a misaligned read */
    if (cmd->rsp[0] != 0) {
      call Panic.panic(PANIC_SD, 21, 0, 0, 0, 0);
      return FAIL;
    }

    /* Re-assert CS to continue the transfer */
    SD_CSN = 0;

    /* Wait for the token */
    i=0;
    do {
      tmp = sd_get();
      i++;
    } while ((tmp == 0xFF) && i < SD_READ_TIMEOUT);
    sd_rd_timeout = i;

    if ((tmp & MSK_TOK_DATAERROR) == 0 || i >= SD_READ_TIMEOUT) {
      /* Clock out a byte before returning, let SD finish */
      sd_get();

      /* The card returned an error, or timed out. */
      return FAIL;
    }

    idle_byte = 0xff;
    U1IFG &= ~(URXIFG1 | UTXIFG1);

    DMA0SA  = (uint16_t) &U1RXBUF;
    DMA0DA  = (uint16_t) data;
    DMA0SZ  = data_len;
    DMA0CTL = DMA_DT_SINGLE | DMA_SB_DB | DMA_EN |
      DMA_DST_INC | DMA_SRC_NC;

    DMA1SA  = (uint16_t) &idle_byte;
    DMA1DA  = (uint16_t) &U1TXBUF;
    DMA1SZ  = data_len - 1;
    DMA1CTL = DMA_DT_SINGLE | DMA_SB_DB | DMA_EN |
      DMA_DST_NC | DMA_SRC_NC;

    DMACTL0 = DMA1_TSEL_U1RX | DMA0_TSEL_U1RX;
    U1TXBUF = 0xff;

    while (DMA0CTL & DMA_EN)	/* wait for chn 0 to finish */
      ;

    DMACTL0 = 0;

    crc = sd_get();
    crc = crc << 8;
    crc |= sd_get();

    /* Deassert CS */
    SD_CSN = 1;
    /* Send some extra clocks so the card can finish */
    sd_delay(2);
    if (sd_check_crc(data, data_len, crc)) {
      call Panic.panic(PANIC_SD, 22, 0, 0, 0, 0);
      return FAIL;
    }
    return SUCCESS;
  }


  uint16_t sd_read_status() {
    sd_cmd_blk_t *cmd;
    uint16_t i;

    cmd = &sd_cmd;
    cmd->cmd     = SD_SEND_STATUS;
    cmd->rsp_len = SD_SEND_STATUS_R;
    if (sd_send_command())
      return(0xffff);
    i = (cmd->rsp[0] << 8) | cmd->rsp[1];
    return(i);
  }
  
  command error_t SD.write(uint32_t blockaddr, void *data) {
    return FAIL;
  }

  /*
   * SD.read_direct: read a 512 byte block from the SD
   *
   * input:  blockaddr     block to read.  (max 23 bits)
   *         data          pointer to data buffer
   * output: rtn           0 call successful, err otherwise
   */

  command error_t SD.read(uint32_t blockaddr, void *data) {
    sd_cmd_blk_t *cmd;
    error_t err;
    uint8_t *d;

    cmd = &sd_cmd;
    /* Adjust the block address to a byte address */
    blockaddr <<= SD_BLOCKSIZE_NBITS;

    /* Pack the address */
    sd_packarg(blockaddr);

    /* Need to add size checking, 0 = success */
    cmd->cmd     = SD_READ_BLOCK;
    cmd->rsp_len = SD_READ_BLOCK_R;
    err = sd_read_data_direct(SD_BLOCKSIZE, data);
    if (err) {
      call Panic.panic(PANIC_SD, 23, err, 0, 0, 0);
      return(err);
    }

    /*
     * sometimes.  not sure of the conditions.  When using dma
     * the first byte will show up as 0xfe (something having
     * to do with the cmd response).  Check for this and if seen
     * flag it and re-read the buffer.  We don't keep trying so it
     * had better work.
     */
    d = data;
    if (*d == 0xfe) {
      call Panic.panic(PANIC_SD, 24, *d, 0, 0, 0);
      err = sd_read_data_direct(SD_BLOCKSIZE, data);
    }
    return err;
  }


  /* sd_read8
   *
   * read a buffer from the SD that is 8 only long.  Used for
   * looking at the 1st 8 bytes of each sector.
   *
   * Assumes that a sd_set_blocklen(8) has been executed.  After
   * the user is done with reading 1st 8 make sure you reset
   * the blocklen back to 512.  Otherwise things get weird.  (timeouts)
   */

  error_t sd_read8(uint32_t blockaddr, uint8_t *data) {
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    /* Adjust the block address to a linear address */
    blockaddr <<= SD_BLOCKSIZE_NBITS;

    /* Pack the address */
    sd_packarg(blockaddr);

    /* Need to add size checking, 0 = success */
    cmd->cmd     = SD_READ_BLOCK;
    cmd->rsp_len = SD_READ_BLOCK_R;
    return(sd_read_data_direct(8, data));
  }


  /*
   * Start a write to the SD card using DMA.
   *
   * Clears DMA Int Enable.
   */

  error_t sd_start_write(uint32_t blockaddr, uint8_t *data) {
    uint8_t  tmp;
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    sd_compute_crc(data);
    /* Adjust the block address to a linear address */
    blockaddr <<= SD_BLOCKSIZE_NBITS;

    /* Pack the address */
    sd_packarg(blockaddr);

    cmd->cmd     = SD_WRITE_BLOCK;
    cmd->rsp_len = SD_WRITE_BLOCK_R;
    if (sd_send_command()) {
      call Panic.panic(PANIC_SD, 25, 0, 0, 0, 0);
      return FAIL;
    }

    /* Check for an error, like a misaligned write */
    if (cmd->rsp[0] != 0) {
      call Panic.panic(PANIC_SD, 26, 0, 0, 0, 0);
      return FAIL;
    }

    /* Re-assert CS to continue the transfer */
    SD_CSN = 0;

    /* The write command needs an additional 8 clock cycles before
     * the block write is started. */
    tmp = sd_get();
    if (tmp != 0xff)
      call Panic.panic(PANIC_SD, 27, tmp, 0, 0, 0);

    U1IFG = ~(URXIFG1 | UTXIFG1);
    DMA0SA = (uint16_t) data;
    DMA0DA = (uint16_t) &U1TXBUF;
    DMA0SZ = SD_BLOCKSIZE;
    DMA0CTL = DMA_DT_SINGLE | DMA_SB_DB | DMA_EN |
      DMA_DST_NC | DMA_SRC_INC;
    DMACTL0 = DMA0_TSEL_U1TX;

    /* Send start block token to start the transfer */
    U1TXBUF = SD_TOK_WRITE_STARTBLOCK;
    return SUCCESS;
  }


#ifdef notdef
  const mm_time_t
    sd_busy_max      = {0, 0, .mis = 300};

  const mm_time_t
    sd_small_timeout = {0, 0, .mis = 10};
#endif


  error_t sd_finish_write() {
    uint16_t i;
    uint8_t  tmp;

#ifdef notdef
    /*
     * This needs to get changed for the thread.  need a timeout sequence.
     */
    /*
     * We give up to 10 mis for things to settle down.
     *
     * need to convert this timing stuff into using a Timer.
     */
    mm_time_t   t, to, t2;
    time_get_cur(&to);
    add_times(&to, &sd_small_timeout);
#endif

    /*
     * The DMA only kicks out via the transmit path.  Simultaneously
     * we should be getting idles (0xff) coming from the SD card.
     * These are being received resulting in chars being avail in RXBUFF
     * and corresponding Overrun Errors (OE).  Wait for the transmitter
     * to empty.  Then we should have seen the last char received and
     * we can successfully clean out both data avail and the overrun.
     */
    while (!(U1_TX_EMPTY)) {
#ifdef not
      /*
       * Need a timeout
       */
      time_get_cur(&t);
      if (time_leq(&to, &t))
	call Panic.panic(PANIC_SD, 28, 0, 0, 0, 0);
#endif
    }

    tmp = U1IFG;
    U1_CLR_RX;
    tmp = U1RXBUF;		/* clean out OE and data avail */

    if (!(U1_TX_EMPTY) || U1_RX_RDY)
      call Panic.panic(PANIC_SD, 29, 0, 0, 0, 0);

    sd_put(0xff);		/* crc ignored */
    sd_put(0xff);

#ifdef notdef
    /*
     * SD should tell us if it accepted the data block
     */
    i=0;
    do {
      tmp = sd_get();
      i++;
      time_get_cur(&t);
    } while ((tmp == 0xFF) && time_leq(&t, &to));
#endif

    i=0;
    do {
      tmp = sd_get();
      i++;
    } while (tmp == 0xFF);

    if ((tmp & 0x0F) != 0x05) {
      i = sd_read_status();
      call Panic.panic(PANIC_SD, 30, tmp, i, 0, 0);
      return FAIL;
    }

    /* wait for the card to go unbusy */
    i = 0;
    while ((tmp = sd_get()) != 0xff) {
      i++;
#ifdef notdef
      if (time_leq(&to, &t))
	call Panic.panic(PANIC_SD, 31, 0, 0, 0, 0);
#endif
    }
    sd_busy_timeout = i;

    /* Deassert CS */
    SD_CSN = 1;

    /*
     * Send some extra clocks so the card can finish
     * (Where did this come from?)
     */
    sd_delay(2);

    i = sd_read_status();
    if (i)
      call Panic.panic(PANIC_SD, 32, i, 0, 0, 0);
    return SUCCESS;
  }


  error_t sd_write_direct(uint32_t blockaddr, uint8_t *data) {
    error_t rtn;

    rtn = sd_start_write(blockaddr, data);
    if (rtn != SUCCESS)
      return rtn;

    /*
     * sd_start_write uses dma0 to sling the data out.
     * just wait for it to finish.
     */

    while (DMA0CTL & DMA_EN)	/* wait for chnn 0 to finish */
      ;
    DMACTL0 = 0;

    /*
     * now that the dma has finished use sd_finish_write to
     * check the result.
     */
    rtn = sd_finish_write();
    return rtn;
  }


  /*
   * sd_wait_notbusy: make sure card isn't busy
   *
   * synchronously waits until any pending block transfers
   * are finished.
   *
   * Note that sd_read_block() and sd_write_block() already call this
   * function internally before attempting a new transfer, so there are
   * only two times when a user would need to use this function.
   *
   * 1) When the processor will be shutting down. All pending
   *    writes should be finished first.
   * 2) When the user needs the results of an sd_read_block() call right away.
   *
   */

  void sd_wait_notbusy() {
    uint16_t i;

    /* Check for the busy flag (set on a write block) */
    if (sd_busyflag) {
      i = 0;
      while (sd_get() != 0xff)
	i++;
      sd_busyflag = FALSE;
      sd_busy_timeout = i;
    }

    /* Deassert CS */
    SD_CSN = 1;
    /* Send some extra clocks so the card can finish */
    sd_delay(2);
  }


#ifdef notdef
  /*
   * sd_erase
   *
   * erase a contiguous number of blocks
   */

  error_t sd_erase(uint32_t blk_start, uint32_t blk_end) {
    sd_cmd_blk_t *cmd;

    cmd = &sd_cmd;
    /*
     * convert blocks into byte addresses.
     */
    blk_start <<= SD_BLOCKSIZE_NBITS;
    blk_end   <<= SD_BLOCKSIZE_NBITS;

    /*
     * send the start and then the end
     */
    sd_packarg(blk_start);
    cmd->cmd     = SD_SET_ERASE_START;
    cmd->rsp_len = SD_SET_ERASE_START_R;
    if (sd_send_command()) {
      call Panic.panic(PANIC_SD, 33, 0, 0, 0, 0);
      return FAIL;
    }

    /* Check for an error, like a misaligned write */
    if (cmd->rsp[0] != 0) {
      call Panic.panic(PANIC_SD, 34, cmd->rsp[0], 0, 0, 0);
      return FAIL;
    }

    sd_packarg(blk_end);
    cmd->cmd     = SD_SET_ERASE_END;
    cmd->rsp_len = SD_SET_ERASE_END_R;
    if (sd_send_command()) {
      call Panic.panic(PANIC_SD, 35, 0, 0, 0, 0);
      return FAIL;
    }

    /* Check for an error, like a misaligned write */
    if (cmd->rsp[0] != 0) {
      call Panic.panic(PANIC_SD, 36, cmd->rsp[0], 0, 0, 0);
      return FAIL;
    }

    cmd->cmd     = SD_ERASE;
    cmd->rsp_len = SD_ERASE_R;
    if (sd_send_command()) {
      call Panic.panic(PANIC_SD, 37, 0, 0, 0, 0);
      return FAIL;
    }

    /* Check for an error, like a misaligned write */
    if (cmd->rsp[0] != 0) {
      call Panic.panic(PANIC_SD, 38, cmd->rsp[0], 0, 0, 0);
      return FAIL;
    }
    return SUCCESS;
  }
#endif

}