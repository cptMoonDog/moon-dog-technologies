@lazyglobal off.

set target to vessel("Bulldog CRS Ship").

lock relVelocity to (ship:velocity:orbit - target:velocity:orbit).
lock velExcludingTowardTgt to vxcl(target:position, relVelocity).
//lock steering to -relVelocity.
lock steering to velExcludingTowardTgt.

until false {
}
