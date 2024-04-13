const MAP_WIDTH = 512;
const MAP_HEIGHT = 512;

const players = [];
const entities = [];

let currentPlayerId = 1;
let currentEntityId = 1;

export function onConnected(player) {
  player.id = currentPlayerId++;
  players.push(player);

  console.log("Player connected", player.id);

  sendTo(player, {
    type: "hello",
    playerId: player.id,
  });

  for (const entity of entities) {
    sendTo(player, makeSummonMessage(entity));
  }
}

export function onDisconnected(player) {
  console.log("Player disconnected", player.id);
  const index = players.indexOf(player);
  if (index > -1) {
    players.splice(index, 1);
  }
}

export function onMessage(player, message) {
  console.log(player.id, message);
  if (message.type === "summon") {
    onSummon(player, message);
  } else {
    throw new Error("Invalid message: " + message.type);
  }
}

export function tick() {
  for (const entity of entities) {
    console.log("Ticking entity " + entity.id);
    entity.y += 100;
    sendToAll(makeMoveMessage(entity));
  }
  setTimeout(tick, 1000);
}

function sendTo(player, data) {
  player.send(JSON.stringify(data));
}

function sendToAll(data) {
  for (const player of players) {
    sendTo(player, data);
  }
}

function makeSummonMessage(entity) {
  return {
    type: "summon",
    entityId: entity.id,
    ownerId: entity.ownerId,
    x: entity.x,
    y: entity.y,
  };
}

function makeMoveMessage(entity) {
  return {
    type: "move",
    entityId: entity.id,
    x: entity.x,
    y: entity.y,
  };
}

function onSummon(player, message) {
  const x = message.x;
  const y = message.y;

  if (typeof x !== "number" || typeof y !== "number") {
    throw new Error("Invalid summon location");
  }

  if (x !== 0 && y !== 0 && x !== MAP_WIDTH - 1 && y !== MAP_HEIGHT - 1) {
    throw new Error("Invalid summon location");
  }

  if (x < 0 || y < 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT) {
    throw new Error("Invalid summon location");
  }

  const entity = {
    id: currentEntityId++,
    ownerId: player.id,
    x,
    y,
  };

  sendToAll(makeSummonMessage(entity));
  entities.push(entity);
}

function getPlayerFromId(id) {
  return players.find(x => x.id === id);
}

function getNearestEnemy(entity) {

}
