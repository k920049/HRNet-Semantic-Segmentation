#!/bin/bash
aws ec2 request-spot-fleet --spot-fleet-request-config file://spot_fleet_config.json