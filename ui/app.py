import display
import controls
import time
import logging

logging.basicConfig(level=logging.INFO)

is_init = False


def init():
    display.init()

    controls.io_code.subscribe(
        on_next=lambda i: display.write(i[0].name),
    )

    # Loop to keep script running
    global is_init
    is_init = True
    while is_init:
        time.sleep(0.01)

    # Clean up
    logging.info("Shutting down PiDrop UI")


def shutdown():
    global is_init
    is_init = False


try:
    init()

except KeyboardInterrupt:
    shutdown()
    display.shutdown()
    controls.shutdown()
    pass
