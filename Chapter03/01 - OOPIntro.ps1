throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

Add-Type -TypeDefinition '
using System;
namespace Vehicle
{
    public class Car
    {
        public string Make {get; set;}
        public string Model {get; set;}
        public Nullable<ConsoleColor> Color {get; set;}
        public UInt16 TireCount {get;set;}
        public UInt16 Speed {get; private set;}

        public Car()
        {
            TireCount = 4;
        }

        public Car(string make, string model, ConsoleColor color)
        {
            Color = color;
            Make = make;
            Model = model;
            TireCount = 4;
        }
    }
}
'

# New-Object and the default empty constructor
$car = New-Object -TypeName Vehicle.Car
$car

# New-Object and a non-default constructor
$car = New-Object -TypeName Vehicle.Car -ArgumentList 'Opel','GT','Red'
$car

# The static method new instead of New-Object
[Vehicle.Car]::new('Opel','GT','Red')