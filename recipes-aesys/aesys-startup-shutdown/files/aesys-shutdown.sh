#!/bin/bash

# Lazy-umount boot and data (for avoiding troubles with system shutdown)
sync
umount -l /boot
umount -l /data
