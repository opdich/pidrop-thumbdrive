import display
import controls
import time

isInit = False


def init():
    # display.init()

    controls.io_code.subscribe(
        on_next=lambda i: print("Received {0}".format(i)),
        on_completed=lambda: print("Done!"),
    )

    # Loop to keep script running
    global isInit
    isInit = True
    while isInit:
        time.sleep(0.01)

    # Clean up
    print("Shutting down PiDrop UI")


def shutdown():
    global isInit
    isInit = False


try:
    init()

except KeyboardInterrupt:
    shutdown()
    controls.shutdown()
    pass
