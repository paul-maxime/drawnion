const MAP_WIDTH = 800;
const MAP_HEIGHT = 450;

const ENTITY_SPEED = 8;
const MIN_HEALTH = 5;

const TICK_SPEED = 150;

const COLLISIONS_PRECISION = 0.1;

const ELEMENTS_GRASS = 1;
const ELEMENTS_FIRE = 2;
const ELEMENTS_WATER = 3;

const ELEMENTS_TABLE = {
  [ELEMENTS_GRASS]: {
    [ELEMENTS_GRASS]: 2,
    [ELEMENTS_FIRE]: 1,
    [ELEMENTS_WATER]: 4,
  },
  [ELEMENTS_FIRE]: {
    [ELEMENTS_GRASS]: 4,
    [ELEMENTS_FIRE]: 2,
    [ELEMENTS_WATER]: 1,
  },
  [ELEMENTS_WATER]: {
    [ELEMENTS_GRASS]: 1,
    [ELEMENTS_FIRE]: 4,
    [ELEMENTS_WATER]: 2,
  },
}

const MAX_NEUTRAL_ENTITIES = 10;
const TICKS_BETWEEN_NEUTRAL_SPAWNS = 5;
const NEUTRAL_SIZES = [16, 16, 16, 16, 16, 24, 24, 24, 24, 32, 32, 32, 48, 48, 64];

const MANA_PER_TICK = 2;
const INITIAL_MANA = 50;
const MAX_MANA = 300;

const AVATAR_SIZE = 16 * 16;

const TICKS_PER_DECAY = 5;

let players = [];
let entities = [];

let currentPlayerId = 1;
let currentEntityId = 1;

let remainingNeutralEntities = 0;
let neutralSpawnCooldown = 0;

export function onConnected(player) {
  player.id = currentPlayerId++;
  player.mana = INITIAL_MANA;

  players.push(player);

  console.log("Player connected", player.id);

  sendTo(player, {
    type: "hello",
    playerId: player.id,
    mapWidth: MAP_WIDTH,
    mapHeight: MAP_HEIGHT,
  });

  for (const other of players) {
    if (other.pixels) {
      sendTo(player, makeAvatarMessage(other));
    }
  }
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
  if (message.type === "avatar") {
    onAvatarReceived(player, message);
  } else if (message.type === "summon") {
    onSummon(player, message);
  } else {
    throw new Error("Invalid message: " + message.type);
  }
}

export function tick() {
  for (const player of players) {
    playerTick(player);
  }
  for (const entity of entities) {
    entityTick(entity);
  }
  spawnNeutralEntitiesIfRequired();
  setTimeout(tick, TICK_SPEED);
}

function spawnNeutralEntitiesIfRequired() {
  if (remainingNeutralEntities < MAX_NEUTRAL_ENTITIES) {
    if (neutralSpawnCooldown <= 0) {
      neutralSpawnCooldown = TICKS_BETWEEN_NEUTRAL_SPAWNS;
      spawnNeutralEntity();
    } else {
      neutralSpawnCooldown--;
    }
  } else {
    neutralSpawnCooldown = TICKS_BETWEEN_NEUTRAL_SPAWNS;
  }
}

function spawnNeutralEntity() {
  const size = NEUTRAL_SIZES[Math.floor(Math.random() * NEUTRAL_SIZES.length)];
  const element = Math.floor(Math.random() * 3) + 1;

  const x = Math.floor(Math.random() * (MAP_WIDTH - MAP_WIDTH / 5)) + MAP_WIDTH / 10;
  const y = Math.floor(Math.random() * (MAP_HEIGHT - MAP_HEIGHT / 5)) + MAP_HEIGHT / 10;

  const entity = {
    id: currentEntityId++,
    ownerId: 0,
    x,
    y,
    size,
    originalSize: size,
    element,
    decay: 0,
  };

  if (canEntityMoveTo(entity, entity.x, entity.y)) {
    console.log(`Spawning neutral at (${x}, ${y}), size ${size}, element ${element}`);
    sendToAll(makeSummonMessage(entity));
    entities.push(entity);
    remainingNeutralEntities += 1;
    return true;
  } else {
    console.log("Not spawning neutral: collision");
    return false;
  }
}

function playerTick(player) {
  if (!player.pixels) {
    // Haven't joined yet, probably.
  }

  giveManaToPlayer(player, MANA_PER_TICK);
}

function giveManaToPlayer(player, amount) {
  player.mana += amount;
  if (player.mana < 0) {
    player.mana = 0;
  }
  if (player.mana > MAX_MANA) {
    player.mana = MAX_MANA;
  }
  sendTo(player, makeManaMessage(player));
}

function entityTick(entity) {
  if (entity.size < MIN_HEALTH) {
    // Is dead.
    return;
  }

  decayEntity(entity);

  if (entity.size < MIN_HEALTH) {
    // Dead after the decay.
    return;
  }

  if (entity.ownerId === 0) {
    // Neutral entity, doesn't attack.
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

function decayEntity(entity) {
  entity.decay += 1;
  if (entity.decay >= TICKS_PER_DECAY) {
    entity.decay = 0;
    entity.size -= 1;
    sendToAll(makeDamageMessage(entity, null));
    if (entity.size < MIN_HEALTH) {
      // Rip by decay.
      despawnDeadEntity(entity);
    }
  }
}

function despawnDeadEntity(entity) {
  entities = entities.filter(x => x.id !== entity.id);
  if (entity.ownerId === 0) {
    remainingNeutralEntities -= 1;
  }
  sendToAll(makeDespawnMessage(entity));
}

function entityMove(entity, enemy) {
  const movement = vectorNormalize({ x: enemy.x - entity.x, y: enemy.y - entity.y });
  const speed = Math.min(ENTITY_SPEED, distanceBetween(entity, enemy) - (entity.size + enemy.size) / 2.2);

  const destinationX = entity.x + movement.x * speed;
  const destinationY = entity.y + movement.y * speed;

  if (canEntityMoveTo(entity, destinationX, destinationY)) {
    entity.x = destinationX;
    entity.y = destinationY;
    sendToAll(makeMoveMessage(entity));
  }
}

function entityAttack(entity, enemy) {
  enemy.size -= computeDamage(entity, enemy);
  sendToAll(makeDamageMessage(enemy, entity));
  if (enemy.size < MIN_HEALTH) {
    // Rip.
    const owner = getPlayerFromId(entity.ownerId);
    if (owner) {
      const manaGain = enemy.originalSize;
      giveManaToPlayer(owner, manaGain);
      sendTo(owner, makeKillMessage(entity, enemy, manaGain));
    } else {
      console.log("Entity without owner: ", entity);
    }

    despawnDeadEntity(enemy);
    sendToAll(makeDespawnMessage(enemy));
  }
}

function computeDamage(attacker, defender) {
  return ELEMENTS_TABLE[attacker.element][defender.element];
}

function sendTo(player, data) {
  player.send(JSON.stringify(data));
}

function sendToAll(data) {
  for (const player of players) {
    sendTo(player, data);
  }
}

function onAvatarReceived(player, message) {
  if (player.pixels) {
    throw new Error("Image already received");
  }

  const pixels = message.pixels;
  if (!Array.isArray(pixels) || pixels.length !== AVATAR_SIZE || pixels.some(x => typeof x !== "number")) {
    throw new Error("Invalid avatar");
  }
  if (pixels.filter(x => x === 1).length < 50) {
    throw new Error("Avatar not filled enough");
  }

  player.pixels = pixels;
  sendToAll(makeAvatarMessage(player));
}

function onSummon(player, message) {
  if (!player.pixels) {
    throw new Error("Image required");
  }

  const x = message.x;
  const y = message.y;
  const size = message.size;
  const element = message.element;

  if (typeof x !== "number" || typeof y !== "number" || typeof size !== "number" || typeof element !== "number") {
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

  if (element < 1 || element > 3) {
    throw new Error("Invalid element");
  }

  if (player.mana < size) {
    console.log("Summoning without enough mana!");
    return;
  }

  const entity = {
    id: currentEntityId++,
    ownerId: player.id,
    x,
    y,
    size,
    originalSize: size,
    element,
    decay: 0,
  };

  if (!canEntityMoveTo(entity, entity.x, entity.y)) {
    console.log("Collision while summoning!");
    return;
  }

  giveManaToPlayer(player, -size);
  sendToAll(makeSummonMessage(entity));
  entities.push(entity);
}

function makeAvatarMessage(player) {
  return {
    type: "avatar",
    playerId: player.id,
    pixels: player.pixels,
  };
}

function makeSummonMessage(entity) {
  return {
    type: "summon",
    entityId: entity.id,
    ownerId: entity.ownerId,
    x: Math.round(entity.x),
    y: Math.round(entity.y),
    size: entity.size,
    element: entity.element,
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
    attackerId: attacker ? attacker.id : 0,
    newSize: Math.max(entity.size, MIN_HEALTH),
  };
}

function makeDespawnMessage(entity) {
  return {
    type: "despawn",
    entityId: entity.id,
  };
}

function makeManaMessage(player) {
  return {
    type: "mana",
    mana: player.mana,
    max: MAX_MANA,
  };
}

function makeKillMessage(attacker, defender, manaGain) {
  return {
    type: "kill",
    attackerId: attacker.id,
    defenderId: defender.id,
    manaGain,
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
  return !entities.some(other => other !== entity && distanceBetween({ x, y }, other) < (entity.size + other.size) / (entity.ownerId === other.ownerId ? 4 : 3) - COLLISIONS_PRECISION);
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
