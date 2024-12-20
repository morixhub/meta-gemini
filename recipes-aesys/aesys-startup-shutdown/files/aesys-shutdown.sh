#!/bin/bash

# Lazy-umount boot (for avoiding troubles with system shutdown)
sync
umount -l /boot
