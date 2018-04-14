# Raspberry PI (radio_wave_server)

## Provision

Install the RF24 library at least up to Mesh http://tmrh20.github.io/RF24/RPi.html

## External sources included

- https://github.com/nlohmann/json
- https://github.com/kashimAstro/SimpleNetwork

## Build

Run `make`.

## Use

Run `sudo radio_wave_server`.

# MCUs (radio_wave_clients/{APPLICANCES})

## Provision

Install platformio http://docs.platformio.org/en/latest/installation.html
Install the udev rules: `sudo cp radio_wave_clients/*.rules /etc/udev/rules.d/`.

## Deploy

Cd into the appliance folder, and run `pio upload --target`.


# Raspberry PI (storeManager.pde)

Run with Processing.