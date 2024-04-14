const MAP_WIDTH = 512;
const MAP_HEIGHT = 512;

const ENTITY_SPEED = 8;
const MIN_HEALTH = 5;

const TICK_SPEED = 150;

const COLLISIONS_PRECISION = 0.1;

let players = [];
let entities = [];

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
  for (const entity of entities) {
    if (entity.ownerId === player.id) {
      sendToAll(makeDespawnMessage(entity));
    }
  }
  entities = entities.filter(x => x.ownerId !== player.id);
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
    entityTick(entity);
  }
  setTimeout(tick, TICK_SPEED);
}

function entityTick(entity) {
  if (entity.size < MIN_HEALTH) {
    // Is dead.
    return;
  }

  const enemy = getNearestEnemy(entity);
  if (!enemy) {
    // No enemy, nothing to do.
    return;
  }

  const distance = distanceBetween(entity, enemy);
  if (distance <= (entity.size + enemy.size) / 2 + COLLISIONS_PRECISION) {
    entityAttack(entity, enemy);
    // Move after attacking to keep entities together.
    if (enemy.size >= MIN_HEALTH) {
      entityMove(entity, enemy);
    }
  } else {
    entityMove(entity, enemy);
  }
}

function entityMove(entity, enemy) {
  const movement = vectorNormalize({ x: enemy.x - entity.x, y: enemy.y - entity.y });
  const speed = Math.min(ENTITY_SPEED, distanceBetween(entity, enemy) - (entity.size + enemy.size) / 2);

  const destinationX = entity.x + movement.x * speed;
  const destinationY = entity.y + movement.y * speed;

  if (canEntityMoveTo(entity, destinationX, destinationY)) {
    entity.x = destinationX;
    entity.y = destinationY;
    sendToAll(makeMoveMessage(entity));
  }
}

function entityAttack(entity, enemy) {
  enemy.size -= 1;
  sendToAll(makeDamageMessage(enemy, entity));
  if (enemy.size < MIN_HEALTH) {
    // Rip.
    entities = entities.filter(x => x.id !== enemy.id);
    sendToAll(makeDespawnMessage(enemy));
  }
}

function sendTo(player, data) {
  player.send(JSON.stringify(data));
}

function sendToAll(data) {
  for (const player of players) {
    sendTo(player, data);
  }
}

function onSummon(player, message) {
  const x = message.x;
  const y = message.y;
  const size = message.size;

  if (typeof x !== "number" || typeof y !== "number" || typeof size !== "number") {
    throw new Error("Invalid summon");
  }

  if (x !== 0 && y !== 0 && x !== MAP_WIDTH - 1 && y !== MAP_HEIGHT - 1) {
    throw new Error("Invalid summon location");
  }

  if (x < 0 || y < 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT) {
    throw new Error("Invalid summon location");
  }

  if (size !== 16 && size !== 32 && size !== 48 && size !== 64) {
    throw new Error("Invalid summon size");
  }

  const entity = {
    id: currentEntityId++,
    ownerId: player.id,
    x,
    y,
    size,
  };

  sendToAll(makeSummonMessage(entity));
  entities.push(entity);
}

function makeSummonMessage(entity) {
  return {
    type: "summon",
    entityId: entity.id,
    ownerId: entity.ownerId,
    x: Math.round(entity.x),
    y: Math.round(entity.y),
    size: entity.size,
  };
}

function makeMoveMessage(entity) {
  return {
    type: "move",
    entityId: entity.id,
    x: Math.round(entity.x),
    y: Math.round(entity.y),
  };
}

function makeDamageMessage(entity, attacker) {
  return {
    type: "damage",
    entityId: entity.id,
    attackerId: attacker.id,
    newSize: entity.size,
  };
}

function makeDespawnMessage(entity) {
  return {
    type: "despawn",
    entityId: entity.id,
  };
}

function getPlayerFromId(id) {
  return players.find(x => x.id === id);
}

function getNearestEnemy(entity) {
  const enemies = entities.filter(x => x.ownerId !== entity.ownerId);
  let nearest = null;
  let minDistance = 0;
  for (const enemy of enemies) {
    if (enemy.ownerId === entity.ownerId) continue;
    const distance = distanceBetweenSquared(entity, enemy);
    if (!nearest || distance < minDistance) {
      nearest = enemy;
      minDistance = distance;
    }
  }
  return nearest;
}

function canEntityMoveTo(entity, x, y) {
  return !entities.some(other => other !== entity && distanceBetween({ x, y }, other) < (entity.size + other.size) / 2 - COLLISIONS_PRECISION);
}

function distanceBetween(entityA, entityB) {
  return Math.sqrt((entityA.x - entityB.x) ** 2 + (entityA.y - entityB.y) ** 2);
}

function distanceBetweenSquared(entityA, entityB) {
  return (entityA.x - entityB.x) ** 2 + (entityA.y - entityB.y) ** 2;
}

function vectorNormalize(v) {
  const norm = vectorNorm(v);
  return { x: v.x / norm, y: v.y / norm };
}

function vectorNorm(v) {
  return Math.sqrt(v.x ** 2 + v.y ** 2);
}
