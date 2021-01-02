import RPi.GPIO as GPIO
import os

buttons = [18, 19, 20]


def callbackButton(channel):
    print(f"Button {channel}")


def test(channel):
    print("hi I'm new")


GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(buttons, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

for b in buttons:
    if b == 19:
        GPIO.add_event_detect(b, GPIO.RISING, callback=test, bouncetime=200)
    else:
        GPIO.add_event_detect(b, GPIO.RISING, callback=callbackButton, bouncetime=200)


message = input("Press enter to quit\n\n")
GPIO.cleanup()  # Clean up
