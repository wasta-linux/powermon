/*
 * queryMateSerial v0.1 7/22/10
 *
 * This source is modified from
 * http://www.embeddedlinuxinterfacing.com/chapters/06/querySerial.c
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public Licnese as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Library General Public License for more details.
 */

/* queryMateSerial
 * queryMateSerial provides serial communications for use with the
 * Outback Mate. This program sends a query out to a serial port and 
 * waits a specific amount of time then returns all the characters 
 * received. The timeout can be selected on the command line. 
 */

/* Build command:
 * gcc -o queryMateSerial queryMateSerial.c
 */


#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <termios.h>
#include <stdlib.h>

struct termios tio;

int main(int argc, char *argv[])
{
  int fd, oldStatus, status, result;
  long baud;
  char buffer[32767];

  if (argc != 3)
  {
    printf("Usage: queryMateSerial port timeout(mS)\n");
    exit(1);
  }

 /* set baud rate to 19200 */
  baud = B19200;

 /* open the serial port device file
  * O_NDELAY - tells port to operate and ignore the DCD line
  * O_NOCTTY - this process is not to become the controlling
  *            process for the port. The driver will not send
  *            this process signals due to keyboard aborts, etc. */
  if ((fd = open(argv[1], O_RDWR | O_NDELAY | O_NOCTTY)) < 0)
  {
    printf("Couldn't open %s\n", argv[1]);
    exit(1);
  }

 /* we are not concerned about preserving the old serial port configuration
  * CS8, 8 data bits
  * CREAD, receiver enabled
  * CLOCAL, don't change the port's owner */
  tio.c_cflag = baud | CS8 | CREAD | CLOCAL;

  tio.c_cflag &= ~HUPCL; /* clear the HUPCL bit, close doesn't change DTR */

  tio.c_lflag = 0;       /* set input flag noncanonical, no processing */

  tio.c_iflag = IGNPAR;  /* ignore parity errors */

  tio.c_oflag = 0;       /* set output flag noncanonical, no processing */

  tio.c_cc[VTIME] = 0;   /* no time delay */
  tio.c_cc[VMIN]  = 0;   /* no char delay */

  tcflush(fd, TCIFLUSH); /* flush the buffer */
  tcsetattr(fd, TCSANOW, &tio); /* set the attributes */

 /* Set up for no delay, ie nonblocking reads will occur.
  * When we read, we'll get what's in the input buffer or nothing */
  fcntl(fd, F_SETFL, FNDELAY);

 /* Set DTR high, RTS low */
  ioctl(fd, TIOCMGET, &status); /* get the serial port status */
  oldStatus = status; /* save the status to restore later */


  status |= TIOCM_DTR;
  status &= ~TIOCM_RTS;

  ioctl(fd, TIOCMSET, &status); /* set the serial port status */

 /* wait for awhile, based on the user's timeout value in mS*/
  usleep(atoi(argv[2]) * 1000);

 /* read the input buffer and print it */
  result = read(fd, buffer, 32767);
  buffer[result] = 0; // zero terminate so printf works
  printf("%s\n", buffer);

 /* Restore the port status */
  ioctl(fd, TIOCMSET, &oldStatus); /* restore the serial port status */

 /* close the device file */
  close(fd);
}
