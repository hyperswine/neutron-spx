# Neutron Sparx

Sparx framework for neutron (Rei). There is no default recovery strategy for now. Assume the sparx should just work and wont crash. If crash, I guess `spx:system` should restart it. Wait so maybe get a handle on each started sparx? And if one of them returns early or unexpectedly, try to restart it?
