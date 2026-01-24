#!/bin/bash

sudo apt update && apt install curl -y
curl -sfL https://get.k3s.io | sh -