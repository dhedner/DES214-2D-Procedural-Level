extends Node

# One signal called from anywhere for the Bullet Manager to listen to
signal bullet_fired(bullet, position, direction)
signal exit_reached()
