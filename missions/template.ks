@lazyglobal off.
//A mission template

//The Launch Vehicle handles launch to LKO
runpath("0:/lv/delta5.ks").

runpath("0:/programs/lko-to-mun.ks", "terrier").
runpath("0:/programs/warp-to-soi.ks", "Mun").
runpath("0:/programs/powered-capture.ks", "terrier").
runpath("0:/programs/landing.ks", "terrier").

runpath("0:/lv/munar-ascent.ks").
runpath("0:/programs/return-from-moon.ks").
runpath("0:/programs/warp-to-soi.ks", "Kerbin").
runpath("0:/programs/adjust-pe.ks", 34).
runpath("0:/programs/edl.ks").


//This starts the runmode system
kernel_ctl["start"]().
