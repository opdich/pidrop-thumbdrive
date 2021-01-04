import logging
import RPi.GPIO as GPIO
from rx3.subject import Subject
from .io_codes import Code

io_lookup = [
    {"pin": 18, "code": Code.PREVIOUS},
    {"pin": 19, "code": Code.SELECT},
    {"pin": 20, "code": Code.NEXT},
]

io_code = Subject()


def gpio_callback(channel):
    logging.debug(channel)
    io_code.on_next([io["code"] for io in io_lookup if io["pin"] == channel])


def init():
    # Setup the GPIO
    GPIO.setwarnings(False)
    GPIO.setmode(GPIO.BCM)
    # Assign buttons
    for io in io_lookup:
        GPIO.setup(io["pin"], GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
        GPIO.add_event_detect(
            io["pin"], GPIO.RISING, callback=gpio_callback, bouncetime=200
        )


def shutdown():
    # Clean up
    logging.info("Cleaning up the GPIO")
    GPIO.cleanup()
    io_code.on_completed()
