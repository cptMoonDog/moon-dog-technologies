//Find launch time by state vector method.  Credit to someone else, this is not mine.
FUNCTION launchWindow {
    PARAMETER tgt.
    LOCAL lat IS SHIP:LATITUDE.
    LOCAL eclipticNormal IS VCRS(tgt:OBT:VELOCITY:ORBIT,tgt:BODY:POSITION-tgt:POSITION):NORMALIZED.
    LOCAL planetNormal IS HEADING(0,lat):VECTOR.
    LOCAL bodyInc IS VANG(planetNormal, eclipticNormal).
    LOCAL beta IS ARCCOS(MAX(-1,MIN(1,COS(bodyInc) * SIN(lat) / SIN(bodyInc)))).
    LOCAL intersectdir IS VCRS(planetNormal, eclipticNormal):NORMALIZED.
    LOCAL intersectpos IS -VXCL(planetNormal, eclipticNormal):NORMALIZED.
    LOCAL launchtimedir IS (intersectdir * SIN(beta) + intersectpos * COS(beta)) * COS(lat) + SIN(lat) * planetNormal.
    LOCAL launchtime IS VANG(launchtimedir, SHIP:POSITION - BODY:POSITION) / 360 * BODY:ROTATIONPERIOD.
    if VCRS(launchtimedir, SHIP:POSITION - BODY:POSITION)*planetNormal < 0 {
        SET launchtime TO BODY:ROTATIONPERIOD - launchtime.
    }
    RETURN TIME:SECONDS+launchtime.
}
