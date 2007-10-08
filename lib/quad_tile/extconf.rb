require "mkmf"

with_cflags("-std=c99 #{$CFLAGS}") do
  create_makefile("quad_tile_so")
end
