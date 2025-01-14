--------------------------------------------------------------------------------
-- Battery
--------------------------------------------------------------------------------
-- Copyright (C) 2013-2018 Metrostroi Team & FoxWorks Aerospace s.r.o.
-- Contains proprietary code. See license.txt for additional information.
--------------------------------------------------------------------------------
Metrostroi.DefineSystem("Duewag_Battery")

TRAIN_SYSTEM.DontAccelerateSimulation = true

function TRAIN_SYSTEM:Initialize()

    -- Battery parameters
    self.ElementCapacity    = 50 -- A*hour
    self.ElementCount       = 36
    self.Capacity = self.ElementCapacity * self.ElementCount * 3600
    self.Charge = 0
    self.Voltage = 0
    -- Current through battery in amperes
    self.Current = 0
    self.Charging = 0
end

function TRAIN_SYSTEM:Inputs()
    return { "Charge" }
end
function TRAIN_SYSTEM:Outputs()
    return { "Capacity", "Charge", "Voltage" }
end
function TRAIN_SYSTEM:TriggerInput(name,value)
    if name == "Charge" then self.Charging = value end
end
function TRAIN_SYSTEM:Think(dT)
    -- Calculate discharge
    self.Current = 0--self.Train.KVC.Value*90*(self.Train.PowerSupply.XT3_1 > 0 and 3 or -1 + 4*self.Train:ReadTrainWire(27))*50*self.Train.Panel["V1"]
    --print(self.Train.Panel["V1"])
    self.Charge = math.min(self.Capacity,self.Charge + self.Current * dT)

    -- Calculate battery voltage
    if self.Train.BatteryOn == 1 then
        self.Voltage = 24*(self.Charge/self.Capacity)
    else
        self.Voltage = 24*(self.Charge/self.Capacity) + (self.Charging > 0 and 24 or 0)
    end
end