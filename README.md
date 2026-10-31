# ATmega32A LED Snake

Simple AVR Assembly project for the ATmega32A.

## Features

- LED snake effect using LEDs connected to `PD2–PD7` and `PC6–PC7`
- Push button `PB0` – movement in one direction
- Push button `PB1` – movement in the opposite direction
- Timer1 overflow interrupt
- Approx. 100 ms between LED transitions

## Hardware

- ATmega32A
- ZL15AVR development board
- LEDs: `PD2–PD7`, `PC6–PC7`
- Buttons: `PB0`, `PB1`

## Flowcharts

### Main program

![Main program flowchart](main_flowchart.png)

### Timer1 interrupt

![Timer1 interrupt flowchart](interrupt_flowchart.png)

## Demo

![LED snake demo](led_snake_demo_github.gif)

## Notes

Created as part of a university AVR laboratory exercise.

AI assistance was used for explanations, code review and refactoring.
