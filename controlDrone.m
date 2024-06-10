function controlDrone(a, command)

if command == "up"
    writeDigitalPin(a, 'D10', 1);
    pause(0.5);
    writeDigitalPin(a, 'D10', 0);
elseif command == "down"
    writeDigitalPin(a, 'D10', 1);
    pause(1);
    writeDigitalPin(a, 'D10', 0);
end
end