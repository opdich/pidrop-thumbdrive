import sys
import os
import logging
import time
from PIL import Image, ImageDraw, ImageFont

libdir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "lib")
if os.path.exists(libdir):
    sys.path.append(libdir)

from waveshare_epd import epd2in13_V2

epd = None
image = None
draw = None
display_busy = True
font15 = ImageFont.truetype(os.path.join(libdir, "Font.ttc"), 15)
font24 = ImageFont.truetype(os.path.join(libdir, "Font.ttc"), 24)


def init():
    try:
        global epd, image, draw, display_busy
        epd = epd2in13_V2.EPD()
        reset_screen()
        display_busy = False
        logging.info("Display initialized")

    except IOError as e:
        logging.error(e)


def shutdown():
    # Clean up
    logging.info("Cleaning up the display")
    epd.Clear(0xFF)
    epd2in13_V2.epdconfig.module_exit()


def reset_screen(fill=255):
    global epd, image, draw
    # Initialize
    epd.init(epd.FULL_UPDATE)

    # Clear for good measure
    epd.Clear(0xFF)

    # Reset the image
    image = Image.new("1", (epd.height, epd.width), fill)
    draw = ImageDraw.Draw(image)

    # Set buffer and enable parial updates
    epd.displayPartBaseImage(epd.getbuffer(image))
    epd.init(epd.PART_UPDATE)


def write(message):
    # Check if display is ready
    global display_busy
    if display_busy:
        return

    # Set to busy
    display_busy = True

    # Write the message
    draw.rectangle((120, 80, 250, 105), fill=255)
    draw.text((120, 80), message, font=font24, fill=0)
    epd.displayPartial(epd.getbuffer(image))

    # Clear busy indicator
    display_busy = False


# image = Image.new("1", (epd.height, epd.width), 255)  # 255: clear the frame
# draw = ImageDraw.Draw(image)
# draw.text((0, 0), "Hello World", font=font15, fill=0)
# epd.display(epd.getbuffer(image))

# logging.info("Goto Sleep...")
# epd.sleep()
# time.sleep(3)
