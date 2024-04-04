const dgram = require('dgram');
var robot = require("robotjs");

// Erstellen eines UDP-Servers
const server = dgram.createSocket('udp4');

// Port, auf dem der Server lauscht
const PORT = 12346;

// IP-Adresse und Port des Clients
const clientAddress = '10.10.10.20'; // Beispiel-IP-Adresse des Clients
const clientPort = 12345; // Beispiel-Port des Clients

// Event-Handler für eingehende Nachrichten
server.on('message', (msg, rinfo) => {
    
    const jsonMSG = JSON.parse(msg.toString());

    // console.log(jsonMSG)

    const currentX = robot.getMousePos().x;
    const currentY = robot.getMousePos().y;

    const recievedX = parseFloat(jsonMSG["x"]);
    const recievedY = parseFloat(jsonMSG["y"]);

    if (recievedX != 0 && recievedY != 0) {
        const newX = currentX + recievedX*2;
        const newY = currentY + recievedY*2;
        // console.log([recievedX, recievedY])
        robot.moveMouse(newX, newY)
    }
    
    if (jsonMSG["leftclick"]) {
        robot.mouseClick('left');
    }

    if (jsonMSG["rightclick"]) {
        robot.mouseClick('right');
    }

   

    // if (jsonMSG["holdleftclick"]) {
    //     robot.mouseToggle("down", "left");
    // } else {
    //     robot.mouseToggle("up", "left");
    // }

});

// Event-Handler für Fehler
server.on('error', (err) => {
  console.error(`Serverfehler:\n${err.stack}`);
  server.close();
});

// Event-Handler für das "listening"-Event
server.on('listening', () => {
  const address = server.address();
  console.log(`UDP-Server lauscht auf ${address.address}:${address.port}`);
});

// Server starten und auf eingehende Nachrichten warten
server.bind(PORT);

// Funktion zum kontinuierlichen Senden von Daten an den Client
server.send('you can send me mouse location data', clientPort, clientAddress, (err) => {
if (err) {
    console.error(`error while sending message`)
} else {
    console.log(`message send`);
}
});

